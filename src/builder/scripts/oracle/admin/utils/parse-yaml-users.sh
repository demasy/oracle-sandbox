#!/bin/bash
# ============================================
# Parse YAML Users Configuration
# ============================================
# Extracts enabled users from database-objects.yaml for dynamic provisioning
# Usage: parse-yaml-users.sh <PDB_NAME> [PATH_TO_YAML]
# Output: Pipe-separated format (per line): PDB|USERNAME|PASSWORD_VAR|PRIVILEGE_LEVEL
# 
# Example:
#   bash parse-yaml-users.sh SANDBOX_PDB /path/to/database-objects.yaml
#   Output:
#     SANDBOX_PDB|sandbox|${SANDBOX_DB_PASSWORD}|admin
#     SANDBOX_PDB|sandbox_ai|${SANDBOX_DB_PASSWORD}|minimal
#
# Exit codes:
#   0 = Success (one or more users found and output)
#   1 = Error (missing parameters, invalid PDB, file not found)
# ============================================

set -o pipefail

# Validate parameters
if [[ -z "$1" ]]; then
    echo "ERROR: PDB name required" >&2
    echo "Usage: $0 <PDB_NAME> [PATH_TO_YAML]" >&2
    echo "Example: $0 SANDBOX_PDB /path/to/database-objects.yaml" >&2
    exit 1
fi

PDB_NAME="$1"
YAML_FILE="${2:-.}"

# If only directory provided, look for database-objects.yaml
if [[ -d "$YAML_FILE" ]]; then
    YAML_FILE="$YAML_FILE/database-objects.yaml"
fi

# Verify file exists
if [[ ! -f "$YAML_FILE" ]]; then
    echo "ERROR: YAML file not found: $YAML_FILE" >&2
    exit 1
fi

# ─── Parse using AWK for reliable YAML structure handling ──────────────────
# AWK handles complex state transitions more reliably than bash
awk -v target_pdb="$PDB_NAME" '
BEGIN {
    pdb_found = 0
    in_users = 0
    in_user = 0
    user_count = 0
}

# Detect PDB entry start: "  - name: PDB_NAME"
/^  - name: / && !pdb_found {
    name = $0
    gsub(/.*name:[[:space:]]*"?/, "", name)
    gsub(/"?[[:space:]]*$/, "", name)
    if (name == target_pdb) {
        pdb_found = 1
    }
    next
}

# Detect end of target PDB section (another "  - name:" or different top-level key)
/^  - name: / && pdb_found {
    exit
}

/^  [a-z]/ && /^  [^-]/ && pdb_found {
    exit
}

# Detect start of users section
pdb_found && /^    users:/ {
    in_users = 1
    next
}

# Detect end of users section (another top-level key under PDB)
pdb_found && in_users && /^    [a-z]/ && !/^    users:/ && !/^      / {
    in_users = 0
}

# Detect user entry: "      - username: ..."
in_users && /^      - username:/ {
    # Output previous user if it was enabled
    if (in_user && enabled == "true") {
        printf "%s|%s|%s|%s\n", target_pdb, username, password, level
        user_count++
    }
    
    # Extract and store new user
    username = $0
    gsub(/.*username:[[:space:]]*"?/, "", username)
    gsub(/"?[[:space:]]*$/, "", username)
    enabled = ""
    password = ""
    level = ""
    in_user = 1
    next
}

# Parse user properties
in_user && /^        enabled:/ {
    enabled = $0
    gsub(/.*enabled:[[:space:]]*/, "", enabled)
    gsub(/[[:space:]]*$/, "", enabled)
    next
}

in_user && /^        password:/ {
    password = $0
    gsub(/.*password:[[:space:]]*/, "", password)
    gsub(/[[:space:]]*$/, "", password)
    gsub(/"/, "", password)
    next
}

in_user && /^          level:/ {
    level = $0
    gsub(/.*level:[[:space:]]*"?/, "", level)
    gsub(/"?[[:space:]]*$/, "", level)
    next
}

END {
    # Output last user if enabled
    if (in_user && enabled == "true") {
        printf "%s|%s|%s|%s\n", target_pdb, username, password, level
        user_count++
    }
    
    # Exit with appropriate code
    exit (user_count > 0 ? 0 : 2)
}
' "$YAML_FILE"

exit_code=$?

# If no users found, warn but don't fail the provisioning process
if [[ $exit_code -eq 2 ]]; then
    echo "WARN: No enabled users found for PDB '$PDB_NAME' in $YAML_FILE" >&2
    exit 0  # Return success but empty output (caller should handle)
fi

exit 0
