# ─── sandbox status ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox status [resource]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Uses: sandbox-status-helpers.sh for _status_ok, _status_warn, _status_fail
# ─────────────────────────────────────────────────────────────────────────────

status_apex() {
    _status_section "APEX / ORDS"

    # Check process
    local pid
    pid=$(netstat -tulpn 2>/dev/null | grep ":8080.*LISTEN" | awk '{print $NF}' | cut -d'/' -f1)
    if [[ -n "$pid" ]]; then
        _status_ok "ORDS process running (PID: $pid)"
    else
        _status_fail "ORDS process not running"
        _status_tip "sandbox start apex"
        return 1
    fi

    # Check port
    _check_port_listening "8080" "APEX/ORDS"

    # Check HTTP endpoints
    _check_http_endpoint "http://localhost:8080/ords/apex" "APEX endpoint" 5
    _check_http_endpoint "http://localhost:8080/ords/sql-developer" "SQL Developer Web" 3

    # Check for errors in logs
    _check_file_for_errors "/tmp/ords.log" "/tmp/ords.log" 50

    echo ""
    _status_url "APEX" "http://localhost:8080/ords/f?p=4550:1"
    _status_url "SQL Developer Web" "http://localhost:8080/ords/sql-developer"
    _status_url "Admin" "http://localhost:8080/ords/apex_admin"
}

status_mcp() {
    _status_section "MCP Server"

    local pid
    pid=$(pgrep -f "sql.*-mcp" 2>/dev/null | head -1)
    if [[ -n "$pid" ]]; then
        _status_ok "MCP process running (PID: $pid)"

        # Show which saved connection is in use
        local conn_name
        conn_name=$(ps -p "$pid" -o args= 2>/dev/null | grep -oP '(?<=-mcp )\S+' || true)
        [[ -n "$conn_name" ]] && _status_ok "Connection: ${conn_name}"
    else
        _status_fail "MCP process not running"
        _status_tip "sandbox start mcp -c <connection>"
        return 1
    fi
}

status_oracle() {
    _status_section "Oracle Database"

    local host="${SANDBOX_DB_HOST:-localhost}"
    local port="${SANDBOX_DB_PORT:-1521}"

    # TCP reachability
    if (exec 3<>/dev/tcp/"$host"/"$port") 2>/dev/null; then
        _status_ok "DB port $port reachable on $host"
    else
        _status_fail "DB port $port not reachable on $host"
        return 1
    fi

    # SQL ping
    local result
    result=$(sqlplus -S system/"${SANDBOX_DB_PASSWORD}"@//"${host}":"${port}"/"${SANDBOX_DB_SERVICE}" <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT 'OK' FROM DUAL;
EXIT
EOF
)
    if echo "$result" | grep -q "^OK"; then
        _status_ok "Database responds to SQL queries"
    else
        _status_warn "Database connected but query returned unexpected output"
    fi

    # PDB status
    local pdb_result
    pdb_result=$(sqlplus -S sys/"${SANDBOX_DB_PASSWORD}"@//"${host}":"${port}"/"${SANDBOX_DB_SID:-FREE}" as sysdba <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT name || ' ' || open_mode FROM v$pdbs WHERE name IN ('SANDBOX_PDB','FREEPDB1') ORDER BY name;
EXIT
EOF
)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local pdb_name pdb_mode
        pdb_name=$(echo "$line" | awk '{print $1}')
        pdb_mode=$(echo "$line" | awk '{print $2}')
        if [[ "$pdb_mode" == "READ WRITE" || "$pdb_mode" == "READ" ]]; then
            _status_ok "PDB ${pdb_name}: ${pdb_mode}"
        else
            _status_warn "PDB ${pdb_name}: ${pdb_mode:-UNKNOWN}"
        fi
    done <<< "$pdb_result"
}

status_all() {
    status_oracle
    echo ""
    status_apex
    echo ""
    status_mcp
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    database)   status_oracle ;;
    apex)       status_apex ;;
    mcp)        status_mcp ;;
    "")         status_all ;;
esac
