#!/bin/bash
# ============================================
# Parse YAML PDB Configuration
# ============================================
# Extracts PDB names from database-objects.yaml for dynamic provisioning
# Usage: parse-yaml-pdbs.sh [PATH_TO_YAML]
# Output: One PDB name per line
# 
# Example:
#   bash parse-yaml-pdbs.sh /path/to/database-objects.yaml
#   Output:
#     SANDBOX_PDB
#     DEMASY_PDB
#     DEMASYLABS_PDB
#
# Exit codes:
#   0 = Success (one or more PDBs found)
#   1 = Error (file not found, invalid format)
#   2 = No PDBs found
# ============================================

set -o pipefail

# Validate parameters
YAML_FILE="${1:-.}"

# If only directory provided, look for database-objects.yaml
if [[ -d "$YAML_FILE" ]]; then
    YAML_FILE="$YAML_FILE/database-objects.yaml"
fi

# Verify file exists
if [[ ! -f "$YAML_FILE" ]]; then
    echo "ERROR: YAML file not found: $YAML_FILE" >&2
    exit 1
fi

# ─── Parse YAML to extract PDB names ─────────────────────────────────────────
# Strategy:
# 1. Find "databases:" section
# 2. Extract all "- name: PDB_NAME" entries under databases
# 3. Output one PDB name per line (no duplicates)

parse_pdbs() {
    local yaml_file="$1"
    local in_databases=0
    local pdb_count=0
    local seen_pdbs=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Detect databases section: "databases:"
        if [[ "$line" =~ ^databases: ]]; then
            in_databases=1
            continue
        fi
        
        # Exit databases section when we hit another top-level key (no indent)
        if [[ "$in_databases" == 1 ]] && [[ "$line" =~ ^[a-zA-Z_]+: ]] && ! [[ "$line" =~ ^[[:space:]]+ ]]; then
            in_databases=0
        fi
        
        # If not in databases section, skip
        [[ "$in_databases" != 1 ]] && continue
        
        # Extract PDB entry: "- name: PDB_NAME" (2-space indent under databases:)
        if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]+name: ]]; then
            # Extract PDB name using sed
            pdb_name=$(echo "$line" | sed -E 's/.*name:[[:space:]]*"?([^":]+)"?.*/\1/')
            
            # Validate PDB name is not empty
            if [[ -n "$pdb_name" ]]; then
                # Avoid duplicates
                if ! echo "$seen_pdbs" | grep -q "^$pdb_name$"; then
                    echo "$pdb_name"
                    seen_pdbs="${seen_pdbs}${pdb_name}"$'\n'
                    ((pdb_count++))
                fi
            fi
        fi
        
    done < "$yaml_file"
    
    return $([[ $pdb_count -gt 0 ]] && echo 0 || echo 2)
}

# Execute parsing
parse_pdbs "$YAML_FILE"
exit_code=$?

# If no PDBs found, error
if [[ $exit_code -eq 2 ]]; then
    echo "ERROR: No PDBs found in $YAML_FILE" >&2
    exit 1
fi

exit 0
