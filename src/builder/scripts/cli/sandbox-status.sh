# ─── sandbox status ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox status [resource] [--format json|csv|table]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Uses: sandbox-status-helpers.sh for _status_ok, _status_warn, _status_fail
# Provides: Text, JSON, CSV output formats
# ─────────────────────────────────────────────────────────────────────────────

# ─── Status collection (global state for formatting) ──────────────────────────

declare -A _STATUS_DATA
_STATUS_LAST_ERROR=""

# Check oracle database status
_check_oracle_status() {
    local host="${SANDBOX_DB_HOST:-localhost}"
    local port="${SANDBOX_DB_PORT:-1521}"
    local service="${SANDBOX_DB_SERVICE:-FREEPDB1}"
    
    _STATUS_DATA[oracle_host]="$host"
    _STATUS_DATA[oracle_port]="$port"
    _STATUS_DATA[oracle_service]="$service"
    
    # TCP reachability
    if (exec 3<>/dev/tcp/"$host"/"$port") 2>/dev/null; then
        _STATUS_DATA[oracle_port_status]="OK"
    else
        _STATUS_DATA[oracle_port_status]="FAIL"
        _STATUS_LAST_ERROR="DB port $port not reachable"
        return 1
    fi
    
    # SQL ping - use sqlcl directly to bypass wrapper output
    local result
    result=$(/opt/oracle/sqlcl/bin/sql -S system/"${SANDBOX_DB_PASSWORD}"@//"${host}":"${port}"/"${service}" <<'EOF' 2>/dev/null | tail -3 | head -1
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT 'OK' FROM DUAL;
EXIT
EOF
)
    if echo "$result" | grep -q "^OK"; then
        _STATUS_DATA[oracle_query_status]="OK"
    else
        _STATUS_DATA[oracle_query_status]="WARN"
    fi
    
    # PDB status - use sqlcl directly
    local pdb_result
    pdb_result=$(/opt/oracle/sqlcl/bin/sql -S sys/"${SANDBOX_DB_PASSWORD}"@//"${host}":"${port}"/"${SANDBOX_DB_SID:-FREE}" as sysdba <<'EOF' 2>/dev/null | grep -E "^[A-Z_]+ (READ|WRITE)"
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT name || ' ' || open_mode FROM v$pdbs WHERE name IN ('SANDBOX_PDB','FREEPDB1') ORDER BY name;
EXIT
EOF
)
    local pdb_count=0
    while IFS=' ' read -r pdb_name pdb_mode; do
        [[ -z "$pdb_name" ]] && continue
        ((pdb_count++))
        _STATUS_DATA[pdb_${pdb_count}_name]="$pdb_name"
        _STATUS_DATA[pdb_${pdb_count}_mode]="$pdb_mode"
    done <<< "$pdb_result"
    _STATUS_DATA[pdb_count]="$pdb_count"
}

# Check APEX/ORDS status
_check_apex_status() {
    # Check process
    local pid
    pid=$(netstat -tulpn 2>/dev/null | grep ":8080.*LISTEN" | awk '{print $NF}' | cut -d'/' -f1)
    
    if [[ -n "$pid" ]]; then
        _STATUS_DATA[apex_pid]="$pid"
        _STATUS_DATA[apex_process_status]="OK"
    else
        _STATUS_DATA[apex_process_status]="FAIL"
        _STATUS_LAST_ERROR="ORDS process not running"
        return 1
    fi
    
    # Check HTTP endpoint
    local http_status
    http_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ords/apex 2>/dev/null || echo "000")
    if [[ "$http_status" == "200" || "$http_status" == "302" ]]; then
        _STATUS_DATA[apex_http_status]="OK"
    else
        _STATUS_DATA[apex_http_status]="WARN"
        _STATUS_DATA[apex_http_code]="$http_status"
    fi
}

# Check MCP server status
_check_mcp_status() {
    local pid
    pid=$(pgrep -f "sql.*-mcp" 2>/dev/null | head -1)
    
    if [[ -n "$pid" ]]; then
        _STATUS_DATA[mcp_pid]="$pid"
        _STATUS_DATA[mcp_process_status]="OK"
        
        # Get connection name
        local conn_name
        conn_name=$(ps -p "$pid" -o args= 2>/dev/null | grep -oP '(?<=-mcp )\S+' || true)
        [[ -n "$conn_name" ]] && _STATUS_DATA[mcp_connection]="$conn_name"
    else
        _STATUS_DATA[mcp_process_status]="FAIL"
        _STATUS_LAST_ERROR="MCP process not running"
        return 1
    fi
}

# Output status as table (default format)
_status_output_table() {
    _status_section "Oracle Database"
    echo -e "  ${CYAN}Host:${NC}    ${_STATUS_DATA[oracle_host]}"
    echo -e "  ${CYAN}Port:${NC}    ${_STATUS_DATA[oracle_port]}"
    echo -e "  ${CYAN}Service:${NC} ${_STATUS_DATA[oracle_service]}"
    [[ "${_STATUS_DATA[oracle_port_status]}" == "OK" ]] && \
        echo -e "  ${GREEN}✓${NC} Port reachable" || \
        echo -e "  ${RED}✗${NC} Port unreachable"
    [[ "${_STATUS_DATA[oracle_query_status]}" == "OK" ]] && \
        echo -e "  ${GREEN}✓${NC} Database responsive" || \
        echo -e "  ${YELLOW}!${NC} Database query unexpected"
    
    for ((i=1; i<=${_STATUS_DATA[pdb_count]:-0}; i++)); do
        local pdb_name="${_STATUS_DATA[pdb_${i}_name]}"
        local pdb_mode="${_STATUS_DATA[pdb_${i}_mode]}"
        echo -e "  ${CYAN}${pdb_name}:${NC} ${pdb_mode}"
    done
    echo ""
    
    _status_section "APEX / ORDS"
    if [[ "${_STATUS_DATA[apex_process_status]}" == "OK" ]]; then
        echo -e "  ${GREEN}✓${NC} ORDS running (PID: ${_STATUS_DATA[apex_pid]})"
    else
        echo -e "  ${RED}✗${NC} ORDS not running"
    fi
    [[ "${_STATUS_DATA[apex_http_status]}" == "OK" ]] && \
        echo -e "  ${GREEN}✓${NC} HTTP endpoint responding" || \
        echo -e "  ${YELLOW}!${NC} HTTP code: ${_STATUS_DATA[apex_http_code]:-unknown}"
    echo -e "  ${CYAN}URLs:${NC}"
    echo -e "    APEX:  http://localhost:8080/ords/f?p=4550:1"
    echo -e "    SQLDev: http://localhost:8080/ords/sql-developer"
    echo ""
    
    _status_section "MCP Server"
    if [[ "${_STATUS_DATA[mcp_process_status]}" == "OK" ]]; then
        echo -e "  ${GREEN}✓${NC} MCP running (PID: ${_STATUS_DATA[mcp_pid]})"
        [[ -n "${_STATUS_DATA[mcp_connection]}" ]] && \
            echo -e "  ${CYAN}Connection:${NC} ${_STATUS_DATA[mcp_connection]}"
    else
        echo -e "  ${RED}✗${NC} MCP not running"
    fi
    echo ""
}

# Output status as JSON
_status_output_json() {
    printf "{\n"
    printf "  \"timestamp\": \"%s\",\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf "  \"database\": {\n"
    printf "    \"host\": \"%s\",\n" "${_STATUS_DATA[oracle_host]}"
    printf "    \"port\": %s,\n" "${_STATUS_DATA[oracle_port]}"
    printf "    \"service\": \"%s\",\n" "${_STATUS_DATA[oracle_service]}"
    printf "    \"port_status\": \"%s\",\n" "${_STATUS_DATA[oracle_port_status]}"
    printf "    \"query_status\": \"%s\",\n" "${_STATUS_DATA[oracle_query_status]}"
    printf "    \"pdbs\": [\n"
    
    local pdb_count="${_STATUS_DATA[pdb_count]:-0}"
    for ((i=1; i<=pdb_count; i++)); do
        [[ $i -gt 1 ]] && printf ",\n"
        printf "      {\n"
        printf "        \"name\": \"%s\",\n" "${_STATUS_DATA[pdb_${i}_name]}"
        printf "        \"mode\": \"%s\"\n" "${_STATUS_DATA[pdb_${i}_mode]}"
        printf "      }"
    done
    printf "\n    ]\n"
    printf "  },\n"
    printf "  \"apex\": {\n"
    printf "    \"process_status\": \"%s\",\n" "${_STATUS_DATA[apex_process_status]}"
    [[ -n "${_STATUS_DATA[apex_pid]}" ]] && printf "    \"pid\": %s,\n" "${_STATUS_DATA[apex_pid]}"
    printf "    \"http_status\": \"%s\",\n" "${_STATUS_DATA[apex_http_status]}"
    printf "    \"http_code\": \"%s\"\n" "${_STATUS_DATA[apex_http_code]:-unknown}"
    printf "  },\n"
    printf "  \"mcp\": {\n"
    printf "    \"process_status\": \"%s\",\n" "${_STATUS_DATA[mcp_process_status]}"
    [[ -n "${_STATUS_DATA[mcp_pid]}" ]] && printf "    \"pid\": %s,\n" "${_STATUS_DATA[mcp_pid]}"
    [[ -n "${_STATUS_DATA[mcp_connection]}" ]] && printf "    \"connection\": \"%s\",\n" "${_STATUS_DATA[mcp_connection]}"
    printf "    \"available\": true\n"
    printf "  }\n"
    printf "}\n"
}

# Output status as CSV
_status_output_csv() {
    printf "component,key,value\n"
    printf "database,host,%s\n" "${_STATUS_DATA[oracle_host]}"
    printf "database,port,%s\n" "${_STATUS_DATA[oracle_port]}"
    printf "database,service,%s\n" "${_STATUS_DATA[oracle_service]}"
    printf "database,port_status,%s\n" "${_STATUS_DATA[oracle_port_status]}"
    printf "database,query_status,%s\n" "${_STATUS_DATA[oracle_query_status]}"
    
    local pdb_count="${_STATUS_DATA[pdb_count]:-0}"
    for ((i=1; i<=pdb_count; i++)); do
        printf "database,pdb_%s_name,%s\n" "$i" "${_STATUS_DATA[pdb_${i}_name]}"
        printf "database,pdb_%s_mode,%s\n" "$i" "${_STATUS_DATA[pdb_${i}_mode]}"
    done
    
    printf "apex,process_status,%s\n" "${_STATUS_DATA[apex_process_status]}"
    [[ -n "${_STATUS_DATA[apex_pid]}" ]] && printf "apex,pid,%s\n" "${_STATUS_DATA[apex_pid]}"
    printf "apex,http_status,%s\n" "${_STATUS_DATA[apex_http_status]}"
    printf "apex,http_code,%s\n" "${_STATUS_DATA[apex_http_code]:-unknown}"
    
    printf "mcp,process_status,%s\n" "${_STATUS_DATA[mcp_process_status]}"
    [[ -n "${_STATUS_DATA[mcp_pid]}" ]] && printf "mcp,pid,%s\n" "${_STATUS_DATA[mcp_pid]}"
    [[ -n "${_STATUS_DATA[mcp_connection]}" ]] && printf "mcp,connection,%s\n" "${_STATUS_DATA[mcp_connection]}"
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Parse --format flag
_parse_output_format $PARAMS

# Collect all status data
case "$RESOURCE" in
    database|"")
        _check_oracle_status
        [[ -z "$RESOURCE" ]] && _check_apex_status && _check_mcp_status
        ;;
    apex)
        _check_apex_status
        ;;
    mcp)
        _check_mcp_status
        ;;
esac

# Output based on format
case "$OUTPUT_FORMAT" in
    json)
        _status_output_json
        ;;
    csv)
        _status_output_csv
        ;;
    *)
        _status_output_table
        ;;
esac
