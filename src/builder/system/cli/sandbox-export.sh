# ─── sandbox export ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox export [resource] [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Provides: export config/connections/settings as JSON/CSV
# Usage:
#   sandbox export [--format json|csv|table]
#   sandbox export config [--format json|csv]
#   sandbox export connections [--format json|csv]
# ─────────────────────────────────────────────────────────────────────────────

# Export all configurations as JSON
_config_export_json() {
    printf "{\n"
    printf "  \"environment\": {\n"
    printf "    \"db_host\": \"%s\",\n" "${SANDBOX_DB_HOST:-localhost}"
    printf "    \"db_port\": \"%s\",\n" "${SANDBOX_DB_PORT:-1521}"
    printf "    \"db_service\": \"%s\",\n" "${SANDBOX_DB_SERVICE:-FREEPDB1}"
    printf "    \"db_sid\": \"%s\"\n" "${SANDBOX_DB_SID:-FREE}"
    printf "  },\n"
    
    printf "  \"connections\": {\n"
    
    # List all saved connections
    local conn_dir="${HOME:-/home/sandbox}/.dbtools/connections"
    local props_files
    props_files=$(find "$conn_dir" -name "dbtools.properties" 2>/dev/null | sort)
    
    local first=true
    while IFS= read -r props; do
        [[ -z "$props" ]] && continue
        
        if [[ "$first" == true ]]; then
            first=false
        else
            printf ",\n"
        fi
        
        local name user conn_str
        name=$(grep -m1 "^name=" "$props" 2>/dev/null | cut -d= -f2-)
        user=$(grep -m1 "^userName=" "$props" 2>/dev/null | cut -d= -f2-)
        conn_str=$(grep -m1 "^connectionString=" "$props" 2>/dev/null | cut -d= -f2-)
        
        printf "    \"%s\": {\n" "$name"
        printf "      \"user\": \"%s\",\n" "$user"
        printf "      \"connection\": \"%s\"\n" "$conn_str"
        printf "    }"
    done <<< "$props_files"
    
    printf "\n  }\n"
    printf "}\n"
}

# Export configurations as CSV
_config_export_csv() {
    printf "config_key,value\n"
    printf "db_host,%s\n" "${SANDBOX_DB_HOST:-localhost}"
    printf "db_port,%s\n" "${SANDBOX_DB_PORT:-1521}"
    printf "db_service,%s\n" "${SANDBOX_DB_SERVICE:-FREEPDB1}"
    printf "db_sid,%s\n" "${SANDBOX_DB_SID:-FREE}"
    
    # Add connections as separate rows
    local conn_dir="${HOME:-/home/sandbox}/.dbtools/connections"
    local props_files
    props_files=$(find "$conn_dir" -name "dbtools.properties" 2>/dev/null | sort)
    
    while IFS= read -r props; do
        [[ -z "$props" ]] && continue
        
        local name user conn_str
        name=$(grep -m1 "^name=" "$props" 2>/dev/null | cut -d= -f2-)
        user=$(grep -m1 "^userName=" "$props" 2>/dev/null | cut -d= -f2-)
        conn_str=$(grep -m1 "^connectionString=" "$props" 2>/dev/null | cut -d= -f2-)
        
        printf "connection_%s,%s@%s\n" "$name" "$user" "$conn_str"
    done <<< "$props_files"
}

# Export configurations as table
_config_export_table() {
    echo ""
    echo -e "  ${YELLOW}Environment Configuration:${NC}"
    echo -e "    ${CYAN}DB Host:${NC}     ${SANDBOX_DB_HOST:-localhost}"
    echo -e "    ${CYAN}DB Port:${NC}     ${SANDBOX_DB_PORT:-1521}"
    echo -e "    ${CYAN}DB Service:${NC}  ${SANDBOX_DB_SERVICE:-FREEPDB1}"
    echo -e "    ${CYAN}DB SID:${NC}      ${SANDBOX_DB_SID:-FREE}"
    echo ""
    echo -e "  ${YELLOW}Saved Connections:${NC}"
    
    local conn_dir="${HOME:-/home/sandbox}/.dbtools/connections"
    local props_files
    props_files=$(find "$conn_dir" -name "dbtools.properties" 2>/dev/null | sort)
    
    if [[ -z "$props_files" ]]; then
        echo -e "    ${CYAN}(none)${NC}"
    else
        while IFS= read -r props; do
            [[ -z "$props" ]] && continue
            
            local name user conn_str
            name=$(grep -m1 "^name=" "$props" 2>/dev/null | cut -d= -f2-)
            user=$(grep -m1 "^userName=" "$props" 2>/dev/null | cut -d= -f2-)
            conn_str=$(grep -m1 "^connectionString=" "$props" 2>/dev/null | cut -d= -f2-)
            
            echo -e "    ${CYAN}${name}:${NC} ${user}@${conn_str}"
        done <<< "$props_files"
    fi
    echo ""
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Export connections as JSON
_connections_export_json() {
    local props_files
    props_files=$(find "${HOME:-/home/sandbox}/.dbtools/connections" -name "dbtools.properties" 2>/dev/null | sort)
    
    printf "{\n"
    printf "  \"connections\": [\n"
    local first=true
    while IFS= read -r props; do
        [[ -z "$props" ]] && continue
        [[ "$first" == true ]] && first=false || printf ",\n"
        local name user conn_str
        name=$(grep -m1 "^name=" "$props" 2>/dev/null | cut -d= -f2-)
        user=$(grep -m1 "^userName=" "$props" 2>/dev/null | cut -d= -f2-)
        conn_str=$(grep -m1 "^connectionString=" "$props" 2>/dev/null | cut -d= -f2-)
        printf "    {\"name\": \"%s\", \"user\": \"%s\", \"connection\": \"%s\"}" "$name" "$user" "$conn_str"
    done <<< "$props_files"
    printf "\n  ]\n}\n"
}

# Export connections as CSV
_connections_export_csv() {
    local props_files
    props_files=$(find "${HOME:-/home/sandbox}/.dbtools/connections" -name "dbtools.properties" 2>/dev/null | sort)
    
    printf "name,user,connection\n"
    while IFS= read -r props; do
        [[ -z "$props" ]] && continue
        local name user conn_str
        name=$(grep -m1 "^name=" "$props" 2>/dev/null | cut -d= -f2-)
        user=$(grep -m1 "^userName=" "$props" 2>/dev/null | cut -d= -f2-)
        conn_str=$(grep -m1 "^connectionString=" "$props" 2>/dev/null | cut -d= -f2-)
        printf "%s,%s,%s\n" "$name" "$user" "$conn_str"
    done <<< "$props_files"
}

# Export connections as table
_connections_export_table() {
    local props_files
    props_files=$(find "${HOME:-/home/sandbox}/.dbtools/connections" -name "dbtools.properties" 2>/dev/null | sort)
    
    echo -e "  ${YELLOW}Saved connections:${NC}"
    echo ""
    if [[ -z "$props_files" ]]; then
        echo -e "    ${CYAN}(none)${NC}"
    else
        while IFS= read -r props; do
            [[ -z "$props" ]] && continue
            local name user conn_str
            name=$(grep -m1 "^name=" "$props" 2>/dev/null | cut -d= -f2-)
            user=$(grep -m1 "^userName=" "$props" 2>/dev/null | cut -d= -f2-)
            conn_str=$(grep -m1 "^connectionString=" "$props" 2>/dev/null | cut -d= -f2-)
            echo -e "    ${CYAN}${name}:${NC} ${user}@${conn_str}"
        done <<< "$props_files"
    fi
    echo ""
}

case "$RESOURCE" in
    config|all|"")
        # Parse --format flag (default: table)
        _parse_output_format $PARAMS
        
        case "$OUTPUT_FORMAT" in
            json)
                _config_export_json
                ;;
            csv)
                _config_export_csv
                ;;
            *)
                _config_export_table
                ;;
        esac
        ;;
    connections)
        # Export connections only (uses conn list with format support)
        _parse_output_format $PARAMS
        
        case "$OUTPUT_FORMAT" in
            json)
                _connections_export_json
                ;;
            csv)
                _connections_export_csv
                ;;
            *)
                _connections_export_table
                ;;
        esac
        ;;
    *)
        log_error "Unknown export resource: $RESOURCE"
        echo ""
        echo -e "  ${YELLOW}Usage:${NC} sandbox export [resource] [--format json|csv|table]"
        echo -e "  ${YELLOW}Resources:${NC} config (default) | connections | all"
        echo ""
        exit 1
        ;;
esac
