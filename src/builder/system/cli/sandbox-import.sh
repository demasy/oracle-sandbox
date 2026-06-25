# ─── sandbox import ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox import <resource> --file <path> [--format json|csv]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Provides: Configuration and connection import from JSON/CSV files
# ─────────────────────────────────────────────────────────────────────────────

# ─── Helper functions ──────────────────────────────────────────────────────────

# Validate file exists and is readable
_validate_import_file() {
    local file="$1"
    [[ -z "$file" ]] && _log "error" "No file specified. Use: --file <path>" && return 1
    [[ ! -f "$file" ]] && _log "error" "File not found: $file" && return 1
    [[ ! -r "$file" ]] && _log "error" "File not readable: $file" && return 1
    return 0
}

# Parse JSON connection object and add connection
_import_connection_from_json() {
    local json_obj="$1"
    local name user host port pdb pass
    
    # Extract fields from simple JSON object
    name=$(echo "$json_obj" | grep -oP '"name":\s*"\K[^"]+' | head -1)
    user=$(echo "$json_obj" | grep -oP '"user":\s*"\K[^"]+' | head -1)
    host=$(echo "$json_obj" | grep -oP '"host":\s*"\K[^"]+' | head -1)
    port=$(echo "$json_obj" | grep -oP '"port":\s*"\K[0-9]+' | head -1)
    pdb=$(echo "$json_obj" | grep -oP '"pdb":\s*"\K[^"]+' | head -1)
    pass=$(echo "$json_obj" | grep -oP '"password":\s*"\K[^"]+' | head -1)
    
    [[ -z "$name" || -z "$user" ]] && return 1
    
    # Add connection using conn action
    sandbox conn add \
        --name "$name" \
        --user "$user" \
        ${host:+--host "$host"} \
        ${port:+--port "$port"} \
        ${pdb:+--pdb "$pdb"} \
        ${pass:+--pass "$pass"} > /dev/null 2>&1 && return 0 || return 1
}

# Import connections from JSON file
_import_connections_json() {
    local file="$1"
    local count=0 success=0 failed=0
    
    # Extract connection objects (simple parsing for {name, user, ...})
    while IFS= read -r line; do
        [[ "$line" =~ \"name\" ]] && {
            ((count++))
            if _import_connection_from_json "$line"; then
                ((success++))
                _log "info" "✓ Connection $count imported"
            else
                ((failed++))
                _log "warn" "✗ Failed to import connection $count"
            fi
        }
    done < "$file"
    
    echo "Imported: $success, Failed: $failed"
}

# Import connections from CSV file (name,user,host,port,pdb,password)
_import_connections_csv() {
    local file="$1"
    local count=0 success=0 failed=0 header_skip=0
    
    while IFS=',' read -r name user host port pdb password; do
        # Skip header row
        [[ "$name" == "name" ]] && { header_skip=1; continue; }
        [[ -z "$name" ]] && continue
        
        ((count++))
        sandbox conn add \
            --name "$name" \
            --user "$user" \
            ${host:+--host "$host"} \
            ${port:+--port "$port"} \
            ${pdb:+--pdb "$pdb"} \
            ${password:+--pass "$password"} > /dev/null 2>&1 && {
            ((success++))
            _log "info" "✓ Connection imported: $name"
        } || {
            ((failed++))
            _log "warn" "✗ Failed: $name"
        }
    done < "$file"
    
    echo "Imported: $success, Failed: $failed"
}

# Import configuration from JSON file
_import_config_json() {
    local file="$1"
    local count=0 success=0 failed=0
    
    # Extract key=value pairs from JSON
    while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        ((count++))
        
        # Set as environment variable (in current session only)
        export "SANDBOX_$key=$value"
        ((success++))
        _log "info" "✓ Config imported: $key"
    done < <(grep -oP '"[^"]+"\s*:\s*"[^"]+"' "$file" | sed 's/"//g;s/\s*:\s*/=/')
    
    echo "Imported: $success configuration items"
}

# Import configuration from CSV file (key,value)
_import_config_csv() {
    local file="$1"
    local count=0 success=0 failed=0 header_skip=0
    
    while IFS=',' read -r key value; do
        [[ "$key" == "key" ]] && { header_skip=1; continue; }
        [[ -z "$key" ]] && continue
        
        ((count++))
        export "SANDBOX_$key=$value"
        ((success++))
        _log "info" "✓ Config: $key=$value"
    done < "$file"
    
    echo "Imported: $success configuration items"
}

# Validate imported data (dry-run mode)
_validate_import_connections() {
    local file="$1"
    _log "info" "Validating connection imports..."
    
    local count=0
    if [[ "$file" == *.json ]]; then
        count=$(grep -c '"name"' "$file")
    else
        count=$(($(wc -l < "$file") - 1))  # Subtract header
    fi
    
    _log "info" "Found $count connections to import"
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Parse parameters
_parse_output_format "$PARAMS"

# Extract file parameter
_file=$(_parse_param_value "--file" $PARAMS)

# Validate inputs
_validate_import_file "$_file" || exit 1

# Dispatch based on resource type
case "$RESOURCE" in
    connections)
        _log "info" "Importing connections from $_file"
        if [[ "$_file" == *.json ]]; then
            _import_connections_json "$_file"
        elif [[ "$_file" == *.csv ]]; then
            _import_connections_csv "$_file"
        else
            _log "error" "Unsupported file format. Use .json or .csv"
            exit 1
        fi
        ;;
    config)
        _log "info" "Importing configuration from $_file"
        if [[ "$_file" == *.json ]]; then
            _import_config_json "$_file"
        elif [[ "$_file" == *.csv ]]; then
            _import_config_csv "$_file"
        else
            _log "error" "Unsupported file format. Use .json or .csv"
            exit 1
        fi
        ;;
    all)
        _log "info" "Importing all resources from $_file"
        _log "warn" "Bulk import not yet implemented. Use 'connections' or 'config' resource"
        exit 1
        ;;
    *)
        _log "error" "Unknown resource: $RESOURCE. Use: connections|config|all"
        exit 1
        ;;
esac

_log "success" "Import completed"
