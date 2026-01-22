#!/bin/bash

################################################################################
# DEMASYLABS PDB and User Rollback Script
# This script runs FROM INSIDE the Docker container
# Removes DEMASYLABS_PDB pluggable database and demasy user
################################################################################

set -e

# Get the actual script location (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source utilities from the actual script location
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh" 
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"

# Display Demasy Labs banner
print_demasy_banner "DEMASYLABS PDB and User Rollback"

################################################################################
# CONFIGURATION - Read from Environment Variables
################################################################################
log_info "Reading configuration from environment variables..."

DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
DB_SID="${DEMASYLABS_DB_SID}"
PDB_NAME="DEMASYLABS_PDB"
DEMASY_USER="demasy"
COMMON_USER="c##demasy"

# Validate required environment variables
log_step "Validating environment variables..."
MISSING_VARS=()

[[ -z "$DB_HOST" ]] && MISSING_VARS+=("DEMASYLABS_DB_HOST")
[[ -z "$DB_PORT" ]] && MISSING_VARS+=("DEMASYLABS_DB_PORT")
[[ -z "$DB_PASSWORD" ]] && MISSING_VARS+=("DEMASYLABS_DB_PASSWORD")
[[ -z "$DB_SID" ]] && MISSING_VARS+=("DEMASYLABS_DB_SID")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    log_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  ✗ $var"
    done
    echo ""
    log_info "Please ensure all required environment variables are set in docker-compose.yml"
    exit 1
fi

log_success "All required environment variables are present"

# Display configuration
log_info "Rollback Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  CDB: $DB_SID"
echo "  PDB to Remove: $PDB_NAME"
echo "  Common User to Remove: $COMMON_USER"
echo "  Local User to Remove: $DEMASY_USER"
echo ""

################################################################################
# CONFIRMATION PROMPT
################################################################################
log_section "⚠️  DESTRUCTIVE OPERATION WARNING ⚠️"
log_warn "This script will permanently delete:"
echo "  • PDB: $PDB_NAME (including ALL data)"
echo "  • Common User: $COMMON_USER"
echo "  • Local User: $DEMASY_USER (within PDB)"
echo "  • All associated tablespaces and files"
echo ""
log_error "This operation CANNOT be undone!"
echo ""

# Auto-confirmation for scripted environments - check if running interactively
if [[ -t 0 ]]; then
    read -p "Are you sure you want to proceed? Type 'DELETE' to confirm: " CONFIRMATION
    if [ "$CONFIRMATION" != "DELETE" ]; then
        log_info "Rollback cancelled by user"
        exit 0
    fi
else
    log_warn "Running in non-interactive mode - proceeding with rollback"
fi

echo ""
log_success "Confirmation received - proceeding with rollback..."

################################################################################
# STEP 1: Test Database Connection
################################################################################
log_section "Step 1: Testing Database Connection"
log_step "Connecting to CDB\$ROOT..."

# Test connection to CDB$ROOT
if ! sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << 'EOF' > /dev/null 2>&1
SELECT 'Connected to ' || SYS_CONTEXT('USERENV', 'CON_NAME') AS connection_info FROM DUAL;
EXIT
EOF
then
    log_error "Cannot connect to database CDB at ${DB_HOST}:${DB_PORT}/${DB_SID}"
    log_error "Please verify database is running and credentials are correct"
    exit 1
fi

log_success "Successfully connected to CDB\$ROOT"

################################################################################
# STEP 2: Check What Exists
################################################################################
log_section "Step 2: Checking Current State"

# Check if PDB exists
log_step "Checking if PDB $PDB_NAME exists..."
PDB_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)
PDB_EXISTS=$(echo "$PDB_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

# Check if common user exists
log_step "Checking if common user $COMMON_USER exists..."
COMMON_USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $COMMON_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)
COMMON_USER_EXISTS=$(echo "$COMMON_USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

# Check if local user exists (only if PDB exists)
LOCAL_USER_EXISTS="0"
if [ "$PDB_EXISTS" = "1" ]; then
    log_step "Checking if local user $DEMASY_USER exists in PDB $PDB_NAME..."
    LOCAL_USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
    )
    LOCAL_USER_EXISTS=$(echo "$LOCAL_USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")
fi

# Display current state
log_info "Current State:"
echo "  • PDB $PDB_NAME: $([ "$PDB_EXISTS" = "1" ] && echo "EXISTS" || echo "NOT FOUND") (detected: $PDB_EXISTS)"
echo "  • Common User $COMMON_USER: $([ "$COMMON_USER_EXISTS" = "1" ] && echo "EXISTS" || echo "NOT FOUND") (detected: $COMMON_USER_EXISTS)"
echo "  • Local User $DEMASY_USER: $([ "$LOCAL_USER_EXISTS" = "1" ] && echo "EXISTS" || echo "NOT FOUND")"
echo ""

if [ "$PDB_EXISTS" = "0" ] && [ "$COMMON_USER_EXISTS" = "0" ] && [ "$LOCAL_USER_EXISTS" = "0" ]; then
    log_success "Nothing to rollback - all components already removed"
    exit 0
fi

################################################################################
# STEP 3: Drop Local User (if exists and PDB exists)
################################################################################
if [ "$PDB_EXISTS" = "1" ] && [ "$LOCAL_USER_EXISTS" = "1" ]; then
    log_section "Step 3: Removing Local User"
    log_step "Dropping local user $DEMASY_USER from PDB $PDB_NAME..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Switch to PDB
ALTER SESSION SET CONTAINER = ${PDB_NAME};

-- Drop local user and cascade to remove all objects
DROP USER ${DEMASY_USER} CASCADE;

SELECT 'Local user dropped successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "Local user $DEMASY_USER dropped from PDB $PDB_NAME"
    else
        log_warn "Failed to drop local user $DEMASY_USER (continuing...)"
    fi
else
    log_info "Skipping local user removal (user or PDB doesn't exist)"
fi

################################################################################
# STEP 4: Drop PDB (if exists)
################################################################################
if [ "$PDB_EXISTS" = "1" ]; then
    log_section "Step 4: Removing Pluggable Database"
    
    # First close the PDB
    log_step "Closing PDB $PDB_NAME..."
    sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF > /dev/null 2>&1
ALTER PLUGGABLE DATABASE ${PDB_NAME} CLOSE IMMEDIATE;
EXIT
EOF
    
    # Then drop the PDB including datafiles
    log_step "Dropping PDB $PDB_NAME including datafiles..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Drop PDB including all datafiles
DROP PLUGGABLE DATABASE ${PDB_NAME} INCLUDING DATAFILES;

SELECT 'PDB dropped successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "PDB $PDB_NAME dropped including all datafiles"
    else
        log_error "Failed to drop PDB $PDB_NAME"
        log_warn "Manual cleanup may be required"
    fi
else
    log_info "Skipping PDB removal (PDB doesn't exist)"
fi

################################################################################
# STEP 5: Drop Common User (if exists)
################################################################################
if [ "$COMMON_USER_EXISTS" = "1" ]; then
    log_section "Step 5: Removing Common User"
    log_step "Dropping common user $COMMON_USER..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Drop common user and cascade to remove all objects
DROP USER ${COMMON_USER} CASCADE;

SELECT 'Common user dropped successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "Common user $COMMON_USER dropped successfully"
    else
        log_warn "Failed to drop common user $COMMON_USER (continuing...)"
    fi
else
    log_info "Skipping common user removal (user doesn't exist)"
fi

################################################################################
# STEP 6: Final Verification
################################################################################
log_section "Step 6: Final Verification"
log_step "Verifying all components have been removed..."

# Verify PDB is gone
PDB_CHECK=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)
PDB_CHECK=$(echo "$PDB_CHECK" | grep -o '[0-9]' | tail -n1 || echo "0")

# Verify common user is gone
COMMON_USER_CHECK=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $COMMON_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)
COMMON_USER_CHECK=$(echo "$COMMON_USER_CHECK" | grep -o '[0-9]' | tail -n1 || echo "0")

log_info "Verification Results:"
echo "  • PDB $PDB_NAME: $([ "$PDB_CHECK" = "0" ] && echo "✓ REMOVED" || echo "⚠ STILL EXISTS")"
echo "  • Common User $COMMON_USER: $([ "$COMMON_USER_CHECK" = "0" ] && echo "✓ REMOVED" || echo "⚠ STILL EXISTS")"
echo ""

################################################################################
# COMPLETION SUMMARY
################################################################################
log_section "Rollback Complete!"

if [ "$PDB_CHECK" = "0" ] && [ "$COMMON_USER_CHECK" = "0" ]; then
    log_success "All DEMASYLABS components successfully removed"
    echo ""
    log_info "Removed Components:"
    echo "  ✓ PDB: $PDB_NAME (including all datafiles)"
    echo "  ✓ Common User: $COMMON_USER"
    echo "  ✓ Local User: $DEMASY_USER"
    echo "  ✓ All associated privileges and objects"
    echo ""
    log_success "Database is now in clean state 🧹"
else
    log_warn "Some components may still exist - manual cleanup may be required"
    echo ""
    log_info "Manual Cleanup Commands (if needed):"
    if [ "$PDB_CHECK" != "0" ]; then
        echo "  • DROP PLUGGABLE DATABASE $PDB_NAME INCLUDING DATAFILES;"
    fi
    if [ "$COMMON_USER_CHECK" != "0" ]; then
        echo "  • DROP USER $COMMON_USER CASCADE;"
    fi
fi

echo ""
log_info "To recreate the environment, run:"
echo "  docker exec -it demasylabs-oracle-server create-demasy-user"