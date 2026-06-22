# ─── sandbox status helpers library ────────────────────────────────────────────
# Reusable functions for status checking operations
# Sourced by status action scripts
# ─────────────────────────────────────────────────────────────────────────────

# Display status check result (OK)
_status_ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

# Display status check result (WARNING)
_status_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

# Display status check result (FAILURE)
_status_fail() {
    echo -e "  ${RED}✗${NC} $1"
}

# Check if a process is running by name/pattern
# Usage: _check_process "pattern" "process_description"
# Returns: 0 if running, 1 if not
_check_process() {
    local pattern="$1"
    local desc="$2"
    
    local pid
    pid=$(pgrep -f "$pattern" 2>/dev/null | head -1)
    
    if [[ -n "$pid" ]]; then
        _status_ok "$desc running (PID: $pid)"
        echo "$pid"
        return 0
    else
        _status_fail "$desc not running"
        return 1
    fi
}

# Check if a TCP port is listening
# Usage: _check_port_listening "port_number" "service_description"
# Returns: 0 if listening, 1 if not
_check_port_listening() {
    local port="$1"
    local desc="$2"
    
    if netstat -tulpn 2>/dev/null | grep -q ":${port}.*LISTEN"; then
        _status_ok "Port $port listening ($desc)"
        return 0
    else
        _status_fail "Port $port not listening ($desc)"
        return 1
    fi
}

# Check if an HTTP endpoint is reachable
# Usage: _check_http_endpoint "url" "endpoint_description" [timeout_seconds]
# Returns: 0 if reachable (2xx or 3xx), 1 if not
_check_http_endpoint() {
    local url="$1"
    local desc="$2"
    local timeout="${3:-5}"
    
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$timeout" "$url" 2>/dev/null)
    
    if [[ "$http_code" == "200" || "$http_code" == "302" || "$http_code" == "301" ]]; then
        _status_ok "$desc reachable (HTTP $http_code)"
        return 0
    else
        _status_warn "$desc returned HTTP $http_code"
        return 1
    fi
}

# Check if a file contains error patterns
# Usage: _check_file_for_errors "filepath" "description" [max_lines]
# Returns: count of errors found (0 if none)
_check_file_for_errors() {
    local filepath="$1"
    local desc="$2"
    local max_lines="${3:-50}"
    
    if [[ ! -f "$filepath" ]]; then
        _status_warn "$desc not found"
        return 0
    fi
    
    local error_count
    error_count=$(tail -"$max_lines" "$filepath" 2>/dev/null | grep -c -i "error\|exception\|failed" || true)
    
    if [[ "$error_count" -gt 0 ]]; then
        _status_warn "$error_count recent error(s) in $desc"
        return "$error_count"
    else
        _status_ok "No recent errors in $desc"
        return 0
    fi
}

# Check if a database connection is working
# Usage: _check_db_connection "connection_string" "description"
# Returns: 0 if connected, 1 if not
_check_db_connection() {
    local conn_str="$1"
    local desc="$2"
    
    # Try a simple SQL query via sqlplus
    if echo "select 1 from dual;" | sqlplus -S "$conn_str" >/dev/null 2>&1; then
        _status_ok "Database connection working ($desc)"
        return 0
    else
        _status_fail "Database connection failed ($desc)"
        return 1
    fi
}

# Check if a database is accepting connections on a port
# Usage: _check_db_port "host" "port" "description"
# Returns: 0 if reachable, 1 if not
_check_db_port() {
    local host="$1"
    local port="$2"
    local desc="$3"
    
    if nc -z -w 3 "$host" "$port" 2>/dev/null; then
        _status_ok "DB port $port reachable on $host"
        return 0
    else
        _status_fail "DB port $port not reachable on $host"
        return 1
    fi
}

# Check database availability via SQL query
# Usage: _check_db_sql "query" "description"
# Returns: 0 if query succeeds, 1 if not
_check_db_sql() {
    local query="$1"
    local desc="$2"
    
    if echo "$query" | sqlplus -S sys/password@FREEPDB1 as sysdba >/dev/null 2>&1; then
        _status_ok "$desc"
        return 0
    else
        _status_fail "$desc failed"
        return 1
    fi
}

# Display section header for status output
# Usage: _status_section "Section Name"
_status_section() {
    echo -e "${YELLOW}$1${NC}"
}

# Display a clickable URL in status
# Usage: _status_url "description" "url"
_status_url() {
    local desc="$1"
    local url="$2"
    echo -e "  ${CYAN}${desc}:${NC} $url"
}

# Display a note/tip in status
# Usage: _status_tip "tip text"
_status_tip() {
    echo -e "  ${CYAN}Tip: $1${NC}"
}
