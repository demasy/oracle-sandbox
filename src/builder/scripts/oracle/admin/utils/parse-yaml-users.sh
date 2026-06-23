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
#   2 = No enabled users found for PDB (not an error)
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

# ─── Parse YAML using bash-native tools ─────────────────────────────────────
# Strategy:
# 1. Extract PDB block (from "- name: PDB_NAME" to next "- name:" or EOF)
# 2. Extract users section
# 3. For each user where "enabled: true", extract username, password, privilege level
# 4. Output pipe-separated format

parse_pdb_users() {
    local pdb="$1"
    local yaml_file="$2"
    local in_pdb=0
    local in_users=0
    local in_user=0
    local current_username=""
    local current_password=""
    local current_enabled=""
    local current_privilege_level=""
    local user_count=0
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Detect PDB entry start: "- name: PDB_NAME"
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+name:[[:space:]]+\"?${pdb}\"? ]]; then
            in_pdb=1
            in_users=0
            continue
        fi
        
        # Detect PDB entry end: another "- name:" at the same indentation (databases array item)
        if [[ "$in_pdb" == 1 ]] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+name: ]] && ! [[ "$line" =~ ${pdb} ]]; then
            in_pdb=0
        fi
        
        # If not in target PDB, skip
        [[ "$in_pdb" != 1 ]] && continue
        
        # Detect users section: "users:"
        if [[ "$line" =~ ^[[:space:]]+users: ]]; then
            in_users=1
            continue
        fi
        
        # Exit users section when we hit another top-level key (indentation = 4 spaces)
        if [[ "$in_users" == 1 ]] && [[ "$line" =~ ^[[:space:]]{0,4}[a-zA-Z_]+: ]] && ! [[ "$line" =~ ^[[:space:]]+# ]]; then
            in_users=0
        fi
        
        # If not in users section, skip
        [[ "$in_users" != 1 ]] && continue
        
        # Detect user entry start: "- username:" (6+ spaces indent)
        if [[ "$line" =~ ^[[:space:]]{6,}-[[:space:]]+username: ]]; then
            # If we have a previous user, output it (if enabled)
            if [[ -n "$current_username" ]] && [[ "$current_enabled" == "true" ]]; then
                echo "${pdb}|${current_username}|${current_password}|${current_privilege_level}"
                ((user_count++))
            fi
            
            # Start new user
            current_username=""
            current_password=""
            current_enabled=""
            current_privilege_level=""
            in_user=1
            
            # Extract username from "- username: "value""
            current_username=$(echo "$line" | sed -E 's/.*username:[[:space:]]*"?([^"]+)"?.*/\1/')
            continue
        fi
        
        # Parse user properties (if in_user == 1)
        if [[ "$in_user" == 1 ]]; then
            # enabled: true/false
            if [[ "$line" =~ enabled: ]]; then
                current_enabled=$(echo "$line" | sed -E 's/.*enabled:[[:space:]]*([a-z]+).*/\1/')
            fi
            
            # password: "${VAR}" or "literal"
            if [[ "$line" =~ password: ]]; then
                current_password=$(echo "$line" | sed -E 's/.*password:[[:space:]]*([^ ]*).*/\1/' | tr -d '"')
            fi
            
            # privileges: level: <level>
            if [[ "$line" =~ level: ]]; then
                current_privilege_level=$(echo "$line" | sed -E 's/.*level:[[:space:]]*"?([^ "]+)"?.*/\1/')
            fi
        fi
        
    done < "$yaml_file"
    
    # Output last user if enabled
    if [[ -n "$current_username" ]] && [[ "$current_enabled" == "true" ]]; then
        echo "${pdb}|${current_username}|${current_password}|${current_privilege_level}"
        ((user_count++))
    fi
    
    return $([[ $user_count -gt 0 ]] && echo 0 || echo 2)
}

# Execute parsing and capture result
parse_pdb_users "$PDB_NAME" "$YAML_FILE"
exit_code=$?

# If no users found, warn but don't fail
if [[ $exit_code -eq 2 ]]; then
    echo "WARN: No enabled users found for PDB '$PDB_NAME' in $YAML_FILE" >&2
    exit 0  # Return success but empty output (caller should handle)
fi

exit $exit_code
