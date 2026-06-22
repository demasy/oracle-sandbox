# ─── sandbox monitor ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox monitor [--export json|prometheus|grafana]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions, OUTPUT_FORMAT
# Provides: Real-time monitoring dashboard and metrics export
# ─────────────────────────────────────────────────────────────────────────────

# ─── Load dependencies ────────────────────────────────────────────────────────

if [ -z "$CYAN" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/../system/utils/colors.sh"
    source "$SCRIPT_DIR/../system/utils/logging.sh"
fi

# ─── Metrics collection ────────────────────────────────────────────────────────

# Global metrics container
declare -A METRICS=(
    [timestamp]=""
    [uptime_seconds]="0"
    [cpu_percent]="0"
    [memory_mb]="0"
    [disk_percent]="0"
    [db_connections]="0"
    [db_transactions]="0"
    [apex_response_time_ms]="0"
    [apex_requests_total]="0"
    [mcp_uptime_seconds]="0"
    [errors_last_hour]="0"
)

# Collect system metrics
_collect_system_metrics() {
    METRICS[timestamp]=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Calculate uptime
    if command -v uptime &> /dev/null; then
        local uptime_raw=$(uptime -p 2>/dev/null | grep -oP '\d+(?= second)' || echo "0")
        METRICS[uptime_seconds]="$uptime_raw"
    fi
    
    # CPU usage (simplified)
    if command -v top &> /dev/null; then
        local cpu_data=$(top -bn1 2>/dev/null | grep -P "Cpu\(s\)" | awk '{print $2}' | cut -d'%' -f1)
        METRICS[cpu_percent]="${cpu_data:-0}"
    fi
    
    # Memory usage
    if command -v free &> /dev/null; then
        local mem_mb=$(free -m 2>/dev/null | awk '/^Mem:/ {print $3}')
        METRICS[memory_mb]="${mem_mb:-0}"
    fi
    
    # Disk usage
    if command -v df &> /dev/null; then
        local disk_percent=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | cut -d'%' -f1)
        METRICS[disk_percent]="${disk_percent:-0}"
    fi
}

# Collect database metrics
_collect_database_metrics() {
    local query_result
    
    # Current connections
    query_result=$(sqlcl -S /nolog <<EOF 2>/dev/null
set heading off feedback off pagesize 0 linesize 1000
connect ${SANDBOX_DB_USER}/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT}/${SANDBOX_DB_PDB}
select count(*) from v\$session;
exit;
EOF
    )
    
    local conn_count=$(echo "$query_result" | tail -1 | grep -oP '\d+' | head -1)
    METRICS[db_connections]="${conn_count:-0}"
    
    # Transaction count
    query_result=$(sqlcl -S /nolog <<EOF 2>/dev/null
set heading off feedback off pagesize 0 linesize 1000
connect ${SANDBOX_DB_USER}/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT}/${SANDBOX_DB_PDB}
select count(*) from v\$transaction;
exit;
EOF
    )
    
    local txn_count=$(echo "$query_result" | tail -1 | grep -oP '\d+' | head -1)
    METRICS[db_transactions]="${txn_count:-0}"
}

# Collect APEX metrics via ORDS
_collect_apex_metrics() {
    if [[ -z "$SANDBOX_ORDS_HOST" ]]; then
        SANDBOX_ORDS_HOST="localhost"
    fi
    if [[ -z "$SANDBOX_ORDS_PORT" ]]; then
        SANDBOX_ORDS_PORT="8080"
    fi
    
    # Check ORDS response time
    local start=$(date +%s%N)
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        "http://${SANDBOX_ORDS_HOST}:${SANDBOX_ORDS_PORT}/ords/" \
        --max-time 5 2>/dev/null || echo "000")
    local end=$(date +%s%N)
    
    if [[ "$response" == "200" || "$response" == "401" ]]; then
        local response_time_ms=$(( (end - start) / 1000000 ))
        METRICS[apex_response_time_ms]="$response_time_ms"
    fi
}

# Collect MCP metrics
_collect_mcp_metrics() {
    if pgrep -f "mcp.*server" > /dev/null 2>&1; then
        # MCP process running - estimate uptime from process start time
        local mcp_pid=$(pgrep -f "mcp.*server" | head -1)
        if [[ -n "$mcp_pid" ]]; then
            local start_time=$(ps -o lstart= -p "$mcp_pid" 2>/dev/null)
            local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
            if [[ "$start_epoch" != "0" ]]; then
                local now_epoch=$(date +%s)
                METRICS[mcp_uptime_seconds]=$((now_epoch - start_epoch))
            fi
        fi
    fi
}

# ─── Output formatting ─────────────────────────────────────────────────────────

# Output metrics as JSON (resource-aware, Grafana-compatible)
_monitor_output_json() {
    case "$RESOURCE" in
        system)
            cat << EOF
{
  "timestamp": "${METRICS[timestamp]}",
  "system": {
    "uptime_seconds": ${METRICS[uptime_seconds]},
    "cpu_percent": ${METRICS[cpu_percent]},
    "memory_mb": ${METRICS[memory_mb]},
    "disk_percent": ${METRICS[disk_percent]}
  }
}
EOF
            ;;
        database)
            cat << EOF
{
  "timestamp": "${METRICS[timestamp]}",
  "database": {
    "connections": ${METRICS[db_connections]},
    "transactions": ${METRICS[db_transactions]}
  }
}
EOF
            ;;
        apex)
            cat << EOF
{
  "timestamp": "${METRICS[timestamp]}",
  "apex": {
    "response_time_ms": ${METRICS[apex_response_time_ms]},
    "requests_total": ${METRICS[apex_requests_total]}
  },
  "mcp": {
    "uptime_seconds": ${METRICS[mcp_uptime_seconds]}
  }
}
EOF
            ;;
        *)
            cat << EOF
{
  "timestamp": "${METRICS[timestamp]}",
  "system": {
    "uptime_seconds": ${METRICS[uptime_seconds]},
    "cpu_percent": ${METRICS[cpu_percent]},
    "memory_mb": ${METRICS[memory_mb]},
    "disk_percent": ${METRICS[disk_percent]}
  },
  "database": {
    "connections": ${METRICS[db_connections]},
    "transactions": ${METRICS[db_transactions]}
  },
  "apex": {
    "response_time_ms": ${METRICS[apex_response_time_ms]},
    "requests_total": ${METRICS[apex_requests_total]}
  },
  "mcp": {
    "uptime_seconds": ${METRICS[mcp_uptime_seconds]}
  },
  "health": {
    "errors_last_hour": ${METRICS[errors_last_hour]}
  }
}
EOF
            ;;
    esac
}

# Output metrics in Prometheus format
_monitor_output_prometheus() {
    cat << EOF
# HELP sandbox_uptime_seconds System uptime in seconds
# TYPE sandbox_uptime_seconds gauge
sandbox_uptime_seconds ${METRICS[uptime_seconds]}

# HELP sandbox_cpu_percent CPU utilization percentage
# TYPE sandbox_cpu_percent gauge
sandbox_cpu_percent ${METRICS[cpu_percent]}

# HELP sandbox_memory_mb Memory usage in MB
# TYPE sandbox_memory_mb gauge
sandbox_memory_mb ${METRICS[memory_mb]}

# HELP sandbox_disk_percent Disk utilization percentage
# TYPE sandbox_disk_percent gauge
sandbox_disk_percent ${METRICS[disk_percent]}

# HELP sandbox_db_connections Database connection count
# TYPE sandbox_db_connections gauge
sandbox_db_connections ${METRICS[db_connections]}

# HELP sandbox_db_transactions Database transaction count
# TYPE sandbox_db_transactions gauge
sandbox_db_transactions ${METRICS[db_transactions]}

# HELP sandbox_apex_response_time_ms APEX response time in milliseconds
# TYPE sandbox_apex_response_time_ms gauge
sandbox_apex_response_time_ms ${METRICS[apex_response_time_ms]}

# HELP sandbox_mcp_uptime_seconds MCP service uptime in seconds
# TYPE sandbox_mcp_uptime_seconds gauge
sandbox_mcp_uptime_seconds ${METRICS[mcp_uptime_seconds]}

# HELP sandbox_errors_total Total errors in last hour
# TYPE sandbox_errors_total counter
sandbox_errors_total ${METRICS[errors_last_hour]}
EOF
}

# Output metrics in dashboard table format (resource-aware)
_monitor_output_table() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    # Show header based on resource
    case "$RESOURCE" in
        system)
            echo -e "${CYAN}                    SYSTEM MONITORING${NC}"
            ;;
        database)
            echo -e "${CYAN}                    DATABASE MONITORING${NC}"
            ;;
        apex)
            echo -e "${CYAN}                    APEX MONITORING${NC}"
            ;;
        *)
            echo -e "${CYAN}                    SANDBOX MONITORING DASHBOARD${NC}"
            ;;
    esac
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Output based on resource
    case "$RESOURCE" in
        system)
            echo -e "${YELLOW}SYSTEM METRICS${NC}"
            printf "  %-25s: %-15s\n" "Uptime" "${METRICS[uptime_seconds]}s"
            printf "  %-25s: %-15s\n" "CPU Usage" "${METRICS[cpu_percent]}%"
            printf "  %-25s: %-15s\n" "Memory Usage" "${METRICS[memory_mb]}MB"
            printf "  %-25s: %-15s\n" "Disk Usage" "${METRICS[disk_percent]}%"
            echo ""
            ;;
        database)
            echo -e "${YELLOW}DATABASE METRICS${NC}"
            printf "  %-25s: %-15s\n" "Active Connections" "${METRICS[db_connections]}"
            printf "  %-25s: %-15s\n" "Transactions" "${METRICS[db_transactions]}"
            echo ""
            ;;
        apex)
            echo -e "${YELLOW}APEX METRICS${NC}"
            printf "  %-25s: %-15s\n" "Response Time" "${METRICS[apex_response_time_ms]}ms"
            printf "  %-25s: %-15s\n" "Total Requests" "${METRICS[apex_requests_total]}"
            echo ""
            echo -e "${YELLOW}MCP SERVICE${NC}"
            printf "  %-25s: %-15s\n" "Uptime" "${METRICS[mcp_uptime_seconds]}s"
            echo ""
            ;;
        *)
            # Show all metrics
            echo -e "${YELLOW}SYSTEM METRICS${NC}"
            printf "  %-25s: %-15s\n" "Uptime" "${METRICS[uptime_seconds]}s"
            printf "  %-25s: %-15s\n" "CPU Usage" "${METRICS[cpu_percent]}%"
            printf "  %-25s: %-15s\n" "Memory Usage" "${METRICS[memory_mb]}MB"
            printf "  %-25s: %-15s\n" "Disk Usage" "${METRICS[disk_percent]}%"
            echo ""
            
            echo -e "${YELLOW}DATABASE METRICS${NC}"
            printf "  %-25s: %-15s\n" "Active Connections" "${METRICS[db_connections]}"
            printf "  %-25s: %-15s\n" "Transactions" "${METRICS[db_transactions]}"
            echo ""
            
            echo -e "${YELLOW}APEX METRICS${NC}"
            printf "  %-25s: %-15s\n" "Response Time" "${METRICS[apex_response_time_ms]}ms"
            printf "  %-25s: %-15s\n" "Total Requests" "${METRICS[apex_requests_total]}"
            echo ""
            
            echo -e "${YELLOW}MCP SERVICE${NC}"
            printf "  %-25s: %-15s\n" "Uptime" "${METRICS[mcp_uptime_seconds]}s"
            echo ""
            ;;
    esac
    
    echo -e "${YELLOW}HEALTH${NC}"
    printf "  %-25s: %-15s\n" "Errors (Last Hour)" "${METRICS[errors_last_hour]}"
    printf "  %-25s: %-15s\n" "Timestamp" "${METRICS[timestamp]}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Interactive menu for resource selection
_monitor_menu() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          SELECT MONITORING RESOURCE                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} System Metrics    (CPU, Memory, Disk, Uptime)"
    echo -e "  ${GREEN}2)${NC} Database Metrics  (Connections, Transactions)"
    echo -e "  ${GREEN}3)${NC} APEX Metrics     (Response Time, MCP Uptime)"
    echo -e "  ${GREEN}4)${NC} All Metrics      (Complete Dashboard)"
    echo ""
    
    read -p "Select option (1-4): " selection
    
    case "$selection" in
        1) RESOURCE="system" ;;
        2) RESOURCE="database" ;;
        3) RESOURCE="apex" ;;
        4) RESOURCE="all" ;;
        *) 
            echo -e "${RED}✗${NC} Invalid selection"
            return 1
            ;;
    esac
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Check for menu flag
if [[ "$PARAMS" =~ --menu ]]; then
    _monitor_menu
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi

# Default resource to "all" if not specified
RESOURCE="${RESOURCE:-all}"

# Validate resource
case "$RESOURCE" in
    system|database|apex|all)
        :  # Valid resource
        ;;
    *)
        log_error "Invalid monitor resource: $RESOURCE"
        log_info "Valid resources: system, database, apex, all"
        exit 1
        ;;
esac

# Parse parameters
_export_format=$(_parse_param_value "--export" $PARAMS)

log_info "Collecting monitoring metrics..."

# Collect all metrics (we collect all and filter on output)
_collect_system_metrics
_collect_database_metrics
_collect_apex_metrics
_collect_mcp_metrics

# Output based on requested format
if [[ -n "$_export_format" ]]; then
    # Export mode: output ONLY the requested format, no table
    case "$_export_format" in
        prometheus)
            _monitor_output_prometheus
            ;;
        grafana|json)
            _monitor_output_json
            ;;
    esac
else
    # Table mode: output human-readable table (default)
    _monitor_output_table
fi
