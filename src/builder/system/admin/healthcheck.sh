#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
source "/usr/sandbox/app/system/utils/banner.sh"

# Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
SERVER_URL="http://localhost:3000/health"
TIMEOUT=10
MAX_RETRIES=3
CHECK_INTERVAL=2

# Parse --export / --format flag
OUTPUT_FORMAT="table"
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--export" || "$1" == "--format" || "$1" == "-f" ]]; then
        OUTPUT_FORMAT="${2:-table}"
        shift 2
    else
        shift
    fi
done

# Collected JSON results (populated by each check)
declare -A RESULT_STATUS   # OK | WARN | FAILED
declare -A RESULT_DETAIL   # short detail string

_out() {
    [[ "$OUTPUT_FORMAT" == "table" ]] && echo -e "$@"
}

# ─── checks ───────────────────────────────────────────────────────────────────

check_system_resources() {
    _out "\e[1mSystem Resources:\e[0m"
    _out "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check system resource usage and process status"

    local memory_used disk_usage node_processes=0

    local memory_info=$(free -m 2>/dev/null)
    if [[ -n "$memory_info" ]]; then
        memory_used=$(echo "$memory_info" | awk 'NR==2{printf "%.1f", $3*100/$2}')
        _out "   - Memory Usage: ${memory_used}%"
    fi

    disk_usage=$(df -h /usr/sandbox 2>/dev/null | awk 'NR==2{print $5}' | sed 's/%//')
    if [[ -n "$disk_usage" ]]; then
        if [[ "$disk_usage" -lt 85 ]]; then
            _out " - Disk Usage: ${GREEN}✓ OK${NC} (${disk_usage}%)"
        else
            _out " - Disk Usage: ${YELLOW}⚠ HIGH${NC} (${disk_usage}%)"
        fi
    fi

    if [[ -d "/proc" ]]; then
        for pid_dir in /proc/[0-9]*; do
            if [[ -f "$pid_dir/cmdline" ]]; then
                local cmdline=$(cat "$pid_dir/cmdline" 2>/dev/null | tr '\0' ' ')
                echo "$cmdline" | grep -q "node.*app.js" && ((node_processes++))
            fi
        done
    fi

    if [[ "$node_processes" -gt 0 ]]; then
        _out " - Application Process: ${GREEN}✓ OK${NC} ($node_processes process(es))"
        RESULT_STATUS[system]="OK"
        RESULT_DETAIL[system]="memory=${memory_used}%, disk=${disk_usage}%, app_processes=${node_processes}"
    else
        _out " - Application Process: ${YELLOW}⚠ CHECK${NC} - Specific app.js process not found"
        RESULT_STATUS[system]="WARN"
        RESULT_DETAIL[system]="memory=${memory_used}%, disk=${disk_usage}%, app_processes=0"
        return 1
    fi
    return 0
}

check_database_health() {
    _out "\e[1mDatabase Connectivity:\e[0m"
    _out "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check Oracle database connection and accessibility"

    if [[ -z "$SANDBOX_DB_HOST" || -z "$SANDBOX_DB_PORT" || -z "$SANDBOX_DB_SERVICE" ]]; then
        _out " - Database Config: ${YELLOW}⚠ INCOMPLETE${NC} - Missing environment variables"
        RESULT_STATUS[database]="WARN"
        RESULT_DETAIL[database]="missing env vars"
        return 1
    fi

    local port_check=$(timeout 5 bash -c "</dev/tcp/$SANDBOX_DB_HOST/$SANDBOX_DB_PORT" 2>/dev/null && echo "OK" || echo "FAILED")

    if [[ "$port_check" == "OK" ]]; then
        _out " - Database Port: ${GREEN}✓ REACHABLE${NC}"
        local db_test=$(timeout 10 bash -c "echo 'SELECT 1 FROM DUAL; EXIT;' | sql -S system/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT}/${SANDBOX_DB_SERVICE}" 2>/dev/null | grep -c "1" || echo "0")
        if [[ "$db_test" -gt 0 ]]; then
            _out " - Database Connectivity: ${GREEN}✓ OK${NC}"
            RESULT_STATUS[database]="OK"
            RESULT_DETAIL[database]="port=reachable, sql=ok"
        else
            _out " - Database Connectivity: ${YELLOW}⚠ LIMITED${NC} - Port reachable but SQL test failed"
            RESULT_STATUS[database]="WARN"
            RESULT_DETAIL[database]="port=reachable, sql=failed"
        fi
        return 0
    else
        _out " - Database Port: ${RED}✗ UNREACHABLE${NC}"
        RESULT_STATUS[database]="FAILED"
        RESULT_DETAIL[database]="port=unreachable"
        return 1
    fi
}

check_oracle_clients() {
    _out "\e[1mOracle Clients:\e[0m"
    _out "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check SQLcl and SQL*Plus client availability"

    local sqlcl_status="FAILED" sqlplus_status="FAILED"

    if command -v sql &>/dev/null; then
        sqlcl_status="OK"
        _out " - SQLcl Client: ${GREEN}✓ OK${NC}"
    else
        _out " - SQLcl Client: ${RED}✗ FAILED${NC}"
    fi

    if command -v sqlplus &>/dev/null; then
        sqlplus_status="OK"
        _out " - SQL*Plus Client: ${GREEN}✓ OK${NC}"
    else
        _out " - SQL*Plus Client: ${RED}✗ FAILED${NC}"
    fi

    local arch=$(uname -m)
    _out " - Architecture: $arch"
    [[ "$arch" == "aarch64" ]] && _out "   ${RED}Note: Using SQLcl as SQL*Plus fallback on ARM64${NC}"

    if [[ "$sqlcl_status" == "OK" ]]; then
        RESULT_STATUS[oracle_clients]="OK"
        RESULT_DETAIL[oracle_clients]="sqlcl=ok, sqlplus=${sqlplus_status,,}, arch=${arch}"
        return 0
    else
        RESULT_STATUS[oracle_clients]="FAILED"
        RESULT_DETAIL[oracle_clients]="sqlcl=failed, sqlplus=${sqlplus_status,,}, arch=${arch}"
        return 1
    fi
}

check_server_health() {
    _out "\e[1mServer Health:\e[0m"
    _out "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check server connectivity and response"

    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        _out " - Checking server health (attempt $attempt/$MAX_RETRIES)..."
        local response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT $SERVER_URL 2>/dev/null)
        local curl_exit=$?
        if [[ $curl_exit -eq 0 && "$response" -eq 200 ]]; then
            _out " - Server HTTP Health: ${GREEN}✓ OK${NC} (Status: $response)"
            RESULT_STATUS[server]="OK"
            RESULT_DETAIL[server]="http=${response}"
            return 0
        else
            _out " - Server HTTP Health: ${YELLOW}⚠ FAILED${NC} (Status: $response, Exit Code: $curl_exit)"
            [[ $attempt -lt $MAX_RETRIES ]] && { _out "   - Retrying in $CHECK_INTERVAL seconds..."; sleep $CHECK_INTERVAL; }
        fi
        ((attempt++))
    done

    _out " - Server HTTP Health: ${RED}✗ CRITICAL${NC} - Failed after $MAX_RETRIES attempts"
    RESULT_STATUS[server]="FAILED"
    RESULT_DETAIL[server]="http=unreachable after ${MAX_RETRIES} attempts"
    return 1
}

check_apex_health() {
    _out "\e[1mAPEX/ORDS Status:\e[0m"
    _out "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check Oracle APEX and ORDS availability"

    local ords_running=false apex_accessible=false
    local port_check=$(netstat -tulpn 2>/dev/null | grep ":8080.*LISTEN" | grep -o "LISTEN")

    if [[ "$port_check" == "LISTEN" ]]; then
        ords_running=true
        local ords_pid=$(netstat -tulpn 2>/dev/null | grep ":8080.*LISTEN" | awk '{print $NF}' | cut -d'/' -f1)
        _out " - ORDS Process: ${GREEN}✓ RUNNING${NC} (PID: $ords_pid)"
    else
        _out " - ORDS Process: ${YELLOW}⚠ NOT RUNNING${NC}"
        _out "   ${CYAN}Tip: Start with 'docker exec demasy-server start-ords'${NC}"
        RESULT_STATUS[apex_ords]="WARN"
        RESULT_DETAIL[apex_ords]="ords=not_running"
        return 1
    fi

    if command -v lsof &>/dev/null; then
        if lsof -i :8080 &>/dev/null; then
            _out " - ORDS Port 8080: ${GREEN}✓ LISTENING${NC}"
        else
            _out " - ORDS Port 8080: ${RED}✗ NOT LISTENING${NC}"
            RESULT_STATUS[apex_ords]="FAILED"
            RESULT_DETAIL[apex_ords]="ords=running, port=not_listening"
            return 1
        fi
    fi

    local apex_url="http://localhost:8080/ords/apex"
    local apex_response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$apex_url" 2>/dev/null)
    local apex_curl_exit=$?

    if [[ $apex_curl_exit -eq 0 ]]; then
        if [[ "$apex_response" -eq 200 || "$apex_response" -eq 302 ]]; then
            apex_accessible=true
            _out " - APEX Web Interface: ${GREEN}✓ ACCESSIBLE${NC} (HTTP $apex_response)"
            _out "   ${CYAN}URL: http://localhost:8080/ords/apex${NC}"
        else
            _out " - APEX Web Interface: ${YELLOW}⚠ UNUSUAL RESPONSE${NC} (HTTP $apex_response)"
        fi
    else
        _out " - APEX Web Interface: ${RED}✗ NOT ACCESSIBLE${NC}"
        RESULT_STATUS[apex_ords]="FAILED"
        RESULT_DETAIL[apex_ords]="ords=running, apex=not_accessible"
        return 1
    fi

    if [[ -f "/tmp/ords.log" ]]; then
        local recent_errors=$(tail -50 /tmp/ords.log 2>/dev/null | grep -ic "error\|exception\|failed" || echo "0")
        if [[ "$recent_errors" -gt 0 ]]; then
            _out " - ORDS Logs: ${YELLOW}⚠ $recent_errors recent error(s)${NC}"
        else
            _out " - ORDS Logs: ${GREEN}✓ NO RECENT ERRORS${NC}"
        fi
    fi

    local sdw_url="http://localhost:8080/ords/demasy_dev/_sdw/"
    local sdw_response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$sdw_url" 2>/dev/null)
    if [[ "$sdw_response" -eq 200 || "$sdw_response" -eq 302 ]]; then
        _out " - SQL Developer Web: ${GREEN}✓ ACCESSIBLE${NC}"
    else
        _out " - SQL Developer Web: ${YELLOW}⚠ CHECK${NC} (HTTP $sdw_response)"
    fi

    if [[ "$ords_running" == true && "$apex_accessible" == true ]]; then
        RESULT_STATUS[apex_ords]="OK"
        RESULT_DETAIL[apex_ords]="ords=running, apex=accessible (HTTP ${apex_response})"
        return 0
    else
        RESULT_STATUS[apex_ords]="WARN"
        RESULT_DETAIL[apex_ords]="ords=running, apex=not_accessible"
        return 1
    fi
}

# ─── output formatters ────────────────────────────────────────────────────────

_status_to_int() {
    case "$1" in OK) echo 0 ;; WARN) echo 1 ;; *) echo 2 ;; esac
}

output_json() {
    local overall=$1 failures=$2
    local overall_label; [[ $overall -eq 0 ]] && overall_label="HEALTHY" || overall_label="UNHEALTHY"
    printf '{\n'
    printf '  "timestamp": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '  "container": "%s",\n' "$(hostname)"
    printf '  "environment": "%s",\n' "${ENVIRONMENT:-development}"
    printf '  "status": "%s",\n' "$overall_label"
    printf '  "failures": %d,\n' "$failures"
    printf '  "components": {\n'
    local keys=(system database oracle_clients server apex_ords)
    local last="${keys[-1]}"
    for key in "${keys[@]}"; do
        local comma=","
        [[ "$key" == "$last" ]] && comma=""
        printf '    "%s": { "status": "%s", "detail": "%s" }%s\n' \
            "$key" "${RESULT_STATUS[$key]:-UNKNOWN}" "${RESULT_DETAIL[$key]:-}" "$comma"
    done
    printf '  }\n'
    printf '}\n'
}

output_csv() {
    local overall=$1
    local overall_label; [[ $overall -eq 0 ]] && overall_label="HEALTHY" || overall_label="UNHEALTHY"
    printf 'component,status,detail\n'
    for key in system database oracle_clients server apex_ords; do
        printf '%s,%s,%s\n' "$key" "${RESULT_STATUS[$key]:-UNKNOWN}" "${RESULT_DETAIL[$key]:-}"
    done
    printf 'overall,%s,failures=%d\n' "$overall_label" "$2"
}

display_summary() {
    local overall_status=$1
    echo ""
    echo -e "${NC}========================================${NC}"
    echo -e "${NC}Health Check Summary${NC}"
    echo -e "${NC}========================================${NC}"
    echo -e "${NC}Timestamp: $(date)${NC}"
    echo -e "${NC}Container: $(hostname)${NC}"
    echo -e "${NC}Environment: ${ENVIRONMENT:-development}${NC}"
    echo -e "${NC}========================================${NC}"
    echo ""
}

# ─── main ─────────────────────────────────────────────────────────────────────

main() {
    local overall_status=0 component_failures=0

    if [[ "$OUTPUT_FORMAT" == "table" ]]; then
        print_demasy_banner "Health Check!"
    fi

    check_system_resources  || { overall_status=1; ((component_failures++)); }
    _out ""
    check_database_health   || { overall_status=1; ((component_failures++)); }
    _out ""
    check_oracle_clients    || { overall_status=1; ((component_failures++)); }
    _out ""
    check_server_health     || { overall_status=1; ((component_failures++)); }
    _out ""
    check_apex_health       || { overall_status=1; ((component_failures++)); }
    _out ""

    case "$OUTPUT_FORMAT" in
        json) output_json  $overall_status $component_failures ;;
        csv)  output_csv   $overall_status $component_failures ;;
        *)
            display_summary $overall_status
            if [[ $overall_status -eq 0 ]]; then
                echo -e "${GREEN}Overall Status: HEALTHY ✓${NC}"
                echo ""
                echo -e "${GREEN}All systems operational! 🚀${NC}"
            else
                echo -e "${RED}Overall Status: UNHEALTHY ✗${NC}"
                echo -e "${NC}========================================${NC}"
                echo ""
                echo -e "${RED}$component_failures component(s) failing! ⚠️${NC}"
            fi
            ;;
    esac

    exit $overall_status
}

main
