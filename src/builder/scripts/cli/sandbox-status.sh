# ─── sandbox status ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox status [resource]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

_status_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
_status_warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
_status_fail() { echo -e "  ${RED}✗${NC} $1"; }

status_apex() {
    echo -e "${YELLOW}APEX / ORDS${NC}"

    local pid
    pid=$(netstat -tulpn 2>/dev/null | grep ":8080.*LISTEN" | awk '{print $NF}' | cut -d'/' -f1)
    if [[ -n "$pid" ]]; then
        _status_ok  "ORDS process running   (PID: $pid)"
    else
        _status_fail "ORDS process not running"
        echo -e "  ${CYAN}Tip: sandbox start apex${NC}"
        return 1
    fi

    if netstat -tulpn 2>/dev/null | grep -q ":8080.*LISTEN"; then
        _status_ok  "Port 8080 listening"
    else
        _status_fail "Port 8080 not listening"
        return 1
    fi

    local http
    http=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://localhost:8080/ords/apex" 2>/dev/null)
    if [[ "$http" == "200" || "$http" == "302" ]]; then
        _status_ok  "APEX endpoint reachable (HTTP $http)"
    else
        _status_warn "APEX endpoint returned HTTP $http"
    fi

    local sdw
    sdw=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://localhost:8080/ords/sql-developer" 2>/dev/null)
    if [[ "$sdw" == "200" || "$sdw" == "302" ]]; then
        _status_ok  "SQL Developer Web reachable (HTTP $sdw)"
    else
        _status_warn "SQL Developer Web returned HTTP $sdw"
    fi

    if [[ -f /tmp/ords.log ]]; then
        local errs
        errs=$(tail -50 /tmp/ords.log 2>/dev/null | grep -c -i "error\|exception\|failed" || true)
        if [[ "$errs" -gt 0 ]]; then
            _status_warn "$errs recent error(s) in /tmp/ords.log"
        else
            _status_ok  "No recent errors in /tmp/ords.log"
        fi
    fi

    echo ""
    echo -e "  ${CYAN}APEX:${NC}             http://localhost:8080/ords/f?p=4550:1"
    echo -e "  ${CYAN}SQL Developer Web:${NC} http://localhost:8080/ords/sql-developer"
    echo -e "  ${CYAN}Admin:${NC}            http://localhost:8080/ords/apex_admin"
}

status_mcp() {
    echo -e "${YELLOW}MCP Server${NC}"

    local pid
    pid=$(pgrep -f "sql.*-mcp" 2>/dev/null | head -1)
    if [[ -n "$pid" ]]; then
        _status_ok  "MCP process running    (PID: $pid)"

        # Show which saved connection is in use
        local conn_name
        conn_name=$(ps -p "$pid" -o args= 2>/dev/null | grep -oP '(?<=-mcp )\S+' || true)
        [[ -n "$conn_name" ]] && _status_ok  "Connection:            ${conn_name}"
    else
        _status_fail "MCP process not running"
        echo -e "  ${CYAN}Tip: sandbox start mcp -c <connection>${NC}"
        return 1
    fi
}

status_oracle() {
    echo -e "${YELLOW}Oracle Database${NC}"

    local host="${SANDBOX_DB_HOST:-localhost}"
    local port="${SANDBOX_DB_PORT:-1521}"

    # TCP reachability
    if (exec 3<>/dev/tcp/"$host"/"$port") 2>/dev/null; then
        _status_ok  "DB port ${port} reachable on ${host}"
    else
        _status_fail "DB port ${port} not reachable on ${host}"
        return 1
    fi

    # SQL ping
    local result
    result=$(sql -S system/"${SANDBOX_DB_PASSWORD}"@//"${host}":"${port}"/"${SANDBOX_DB_SERVICE}" \
        2>/dev/null <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT 'OK' FROM DUAL;
EXIT
EOF
)
    if echo "$result" | grep -q "^OK"; then
        _status_ok  "Database responds to SQL queries"
    else
        _status_warn "Database connected but query returned unexpected output"
    fi

    # PDB status — must connect as sysdba to CDB to see all PDBs
    local pdb_result
    pdb_result=$(sql -S sys/"${SANDBOX_DB_PASSWORD}"@//"${host}":"${port}"/"${SANDBOX_DB_SID:-FREE}" as sysdba \
        2>/dev/null <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT name || ' ' || open_mode FROM v$pdbs WHERE name IN ('SANDBOX_PDB','SANDBOX_PDB','FREEPDB1') ORDER BY name;
EXIT
EOF
)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local pdb_name pdb_mode
        pdb_name=$(echo "$line" | awk '{print $1}')
        pdb_mode=$(echo "$line" | awk '{print $2}')
        if [[ "$pdb_mode" == "READ WRITE" || "$pdb_mode" == "READ" ]]; then
            _status_ok  "PDB ${pdb_name}: ${pdb_mode}"
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
