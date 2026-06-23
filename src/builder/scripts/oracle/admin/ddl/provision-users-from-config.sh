#!/bin/bash
# ============================================
# Provision Users from YAML Configuration
# ============================================
# Dynamically creates database users from database-objects.yaml configuration
# Usage: provision-users-from-config.sh <PDB_NAME> [CONFIG_FILE] [LOG_FILE]
#
# Parameters:
#   $1 = Database name (SANDBOX_PDB, DEMASY_PDB, DEMASYLABS_PDB)
#   $2 = Path to database-objects.yaml (default: /usr/sandbox/app/oracle/admin/config/database-objects.yaml)
#   $3 = Log file path (default: /tmp/auto-user-setup.log)
#
# Exit codes:
#   0 = All users provisioned successfully
#   1 = Error (invalid parameters or provisioning failed)
#   2 = Partial success (some users created, some failed)
#
# This script:
# 1. Validates parameters
# 2. Calls parse-yaml-users.sh to get enabled users for the PDB
# 3. For each user: creates user (if not exists) → grants privileges
# 4. Logs all operations with timestamps
# 5. Is idempotent (safe to re-run)
# ============================================

set -o pipefail

# Color codes (fallback if colors.sh not available)
RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
NC=${NC:-'\033[0m'}

# Parameters
PDB_NAME="${1:--}"
CONFIG_FILE="${2:-/usr/sandbox/app/oracle/admin/config/database-objects.yaml}"
LOG_FILE="${3:-/tmp/auto-user-setup.log}"

# Validate PDB name
if [[ "$PDB_NAME" == "-" ]] || [[ -z "$PDB_NAME" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: PDB name required as first argument" | tee -a "$LOG_FILE"
    echo "Usage: $0 <PDB_NAME> [CONFIG_FILE] [LOG_FILE]" >&2
    exit 1
fi

# Validate PDB name format (should be UPPERCASE_PDB)
if ! [[ "$PDB_NAME" =~ ^[A-Z_]+$ ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Invalid PDB name format: $PDB_NAME (expected: SANDBOX_PDB, DEMASY_PDB, DEMASYLABS_PDB)" | tee -a "$LOG_FILE"
    exit 1
fi

# Verify config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Config file not found: $CONFIG_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Verify required scripts exist
PARSE_YAML_SCRIPT="/usr/sandbox/app/oracle/admin/utils/parse-yaml-users.sh"
CREATE_USER_SCRIPT="/usr/sandbox/app/oracle/admin/ddl/create-user.sh"
GRANT_PRIVS_SCRIPT="/usr/sandbox/app/oracle/admin/ddl/grant-privileges.sh"

for script in "$PARSE_YAML_SCRIPT" "$CREATE_USER_SCRIPT" "$GRANT_PRIVS_SCRIPT"; do
    if [[ ! -f "$script" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Required script not found: $script" | tee -a "$LOG_FILE"
        exit 1
    fi
done

# ─── Main Logic ─────────────────────────────────────────────────────────────
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" | tee -a "$LOG_FILE"
}

log_skip() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SKIP] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a "$LOG_FILE"
}

# Parse users from YAML
log_info "Parsing users for PDB: $PDB_NAME from $CONFIG_FILE"

# Capture parse output and error handling
mapfile -t users_array < <(bash "$PARSE_YAML_SCRIPT" "$PDB_NAME" "$CONFIG_FILE" 2>/dev/null)
parse_exit=$?

if [[ $parse_exit -gt 1 ]]; then
    log_error "Failed to parse YAML configuration"
    exit 1
fi

if [[ ${#users_array[@]} -eq 0 ]]; then
    log_warn "No users defined for PDB: $PDB_NAME"
    exit 0  # Not an error, just nothing to do
fi

log_info "Found ${#users_array[@]} enabled user(s) for $PDB_NAME"
echo "" | tee -a "$LOG_FILE"

# ─── Create users and grant privileges ───────────────────────────────────────
users_created=0
users_skipped=0
users_failed=0

for user_entry in "${users_array[@]}"; do
    # Parse pipe-separated entry: PDB|USERNAME|PASSWORD_VAR|PRIVILEGE_LEVEL
    IFS='|' read -r pdb username password_var privilege_level <<< "$user_entry"
    
    # Expand password variable: extract VAR_NAME from ${VAR_NAME} format, then indirect-reference
    # password_var comes in as "${SANDBOX_DB_PASSWORD}", need to extract SANDBOX_DB_PASSWORD
    if [[ "$password_var" =~ \$\{([A-Z_][A-Z_0-9]*)\} ]]; then
        var_name="${BASH_REMATCH[1]}"
        password="${!var_name}"
    else
        # Fallback: if password_var doesn't match the pattern, use it as-is
        password="$password_var"
    fi
    
    if [[ -z "$username" ]] || [[ -z "$password" ]] || [[ -z "$privilege_level" ]]; then
        log_error "Invalid user entry: $user_entry (missing username, password, or privilege level)"
        ((users_failed++))
        continue
    fi
    
    log_info "Processing user: $username (privilege level: $privilege_level)"
    
    # Create user if not exists
    bash "$CREATE_USER_SCRIPT" "$username" "$password" "$PDB_NAME" \
        >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        log_success "User created/verified: $username"
        ((users_created++))
    else
        log_error "Failed to create user: $username"
        ((users_failed++))
        continue
    fi
    
    # Grant privileges for this user
    bash "$GRANT_PRIVS_SCRIPT" "$username" "$privilege_level" "$PDB_NAME" \
        >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        log_success "Privileges granted for $username ($privilege_level)"
    else
        log_error "Failed to grant privileges for user: $username"
        ((users_failed++))
        continue
    fi
    
    echo "" | tee -a "$LOG_FILE"
done

# ─── Summary ─────────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG_FILE"
log_info "=========================================="
log_info "User Provisioning Summary for $PDB_NAME"
log_info "=========================================="
log_info "Users Created/Verified: $users_created"
log_info "Users Skipped:          $users_skipped"
log_info "Users Failed:           $users_failed"
log_info "Total Processed:        $((users_created + users_skipped + users_failed))"
log_info "=========================================="

# Determine exit code
if [[ $users_failed -gt 0 ]]; then
    if [[ $users_created -gt 0 ]]; then
        log_warn "Partial success: $users_created created, $users_failed failed"
        exit 2  # Partial success
    else
        log_error "All user provisioning failed"
        exit 1  # Complete failure
    fi
else
    log_success "All users provisioned successfully"
    exit 0  # Complete success
fi
