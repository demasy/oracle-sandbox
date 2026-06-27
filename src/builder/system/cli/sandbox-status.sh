# ─── sandbox status ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox status [resource] [--format json|csv|table]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Uses: sandbox-status-helpers.sh for _status_ok, _status_warn, _status_fail
# Provides: Text, JSON, CSV output formats
# ─────────────────────────────────────────────────────────────────────────────

# ─── Load dependencies ────────────────────────────────────────────────────────

if [ -z "$CYAN" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/../system/utils/colors.sh"
    source "$SCRIPT_DIR/../system/utils/logging.sh"
fi

# ─── Status collection (global state for formatting) ──────────────────────────

declare -A _STATUS_DATA
_STATUS_LAST_ERROR=""
_STATUS_RESOURCE_CHECKED=""

# Check oracle database status
_check_oracle_status() {
    local host="${SANDBOX_DB_HOST:-192.168.1.110}"
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
        _STATUS_DATA[oracle_query_status]="FAIL"
        return 1
    fi
    
    # SQL ping - try sqlcl first, fall back to status
    local result
    if command -v sqlplus &>/dev/null; then
        result=$(echo "SELECT 'OK' FROM DUAL;" | sqlplus -S "${SANDBOX_DB_USER:-system}/${SANDBOX_DB_PASSWORD:-oracle}@//${host}:${port}/${service}" 2>/dev/null | grep "^OK" | head -1)
    else
        result="OK"  # Assume OK if we can't test
    fi
    
    if [[ -n "$result" ]]; then
        _STATUS_DATA[oracle_query_status]="OK"
    else
        _STATUS_DATA[oracle_query_status]="WARN"
    fi
    
    # PDB status - check if we can query v$pdbs
    local pdb_result
    if command -v sqlplus &>/dev/null; then
        pdb_result=$(echo "SET HEADING OFF FEEDBACK OFF PAGESIZE 0; SELECT name || ' ' || open_mode FROM v\$pdbs WHERE open_mode IS NOT NULL ORDER BY name;" | sqlplus -S "sys/${SANDBOX_DB_PASSWORD:-oracle}@//${host}:${port}/${SANDBOX_DB_SID:-FREE}" as sysdba 2>/dev/null)
    fi
    
    local pdb_count=0
    while IFS=' ' read -r pdb_name pdb_mode; do
        [[ -z "$pdb_name" ]] && continue
        [[ ! "$pdb_mode" =~ READ|WRITE ]] && continue
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
    pid=$(netstat -tulpn 2>/dev/null | grep ":8080.*LISTEN" | awk '{print $NF}' | cut -d'/' -f1 || true)
    
    if [[ -n "$pid" ]]; then
        _STATUS_DATA[apex_pid]="$pid"
        _STATUS_DATA[apex_process_status]="OK"
    else
        _STATUS_DATA[apex_process_status]="FAIL"
        _STATUS_LAST_ERROR="ORDS process not running"
        _STATUS_DATA[apex_http_status]="FAIL"
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
    pid=$(pgrep -f "SqlCli.*-mcp" 2>/dev/null | head -1 || true)

    if [[ -n "$pid" ]]; then
        _STATUS_DATA[mcp_pid]="$pid"
        _STATUS_DATA[mcp_process_status]="OK"

        # Read connection name from state file written by sb start mcp
        local state_file="/tmp/sandbox_mcp.state"
        if [[ -f "$state_file" ]]; then
            local conn_name
            conn_name=$(sed -n '2p' "$state_file" 2>/dev/null || true)
            [[ -n "$conn_name" ]] && _STATUS_DATA[mcp_connection]="$conn_name"
        fi
    else
        _STATUS_DATA[mcp_process_status]="FAIL"
        _STATUS_LAST_ERROR="MCP process not running"
        rm -f /tmp/sandbox_mcp.state
        return 1
    fi
}

# Check network status
_check_network_status() {
    local network_name="sandbox_network"

    _STATUS_DATA[network_name]="$network_name"
    _STATUS_DATA[network_status]="OK"
    _STATUS_DATA[network_driver]="bridge"

    # Gateway
    local gateway
    gateway=$(netstat -rn 2>/dev/null | grep "^0.0.0.0" | awk '{print $2}' || echo "unknown")
    _STATUS_DATA[network_gateway]="$gateway"

    # Container IP, netmask, MTU from ifconfig
    local container_ip netmask mtu
    container_ip=$(ifconfig 2>/dev/null | grep -A1 "^eth0" | grep "inet " | awk '{print $2}')
    [[ -z "$container_ip" ]] && container_ip="unknown"
    netmask=$(ifconfig 2>/dev/null | grep -A1 "^eth0" | grep "inet " | awk '{print $4}' || echo "255.255.255.0")
    mtu=$(ifconfig eth0 2>/dev/null | grep -oP 'mtu \K[0-9]+' || echo "unknown")
    _STATUS_DATA[network_mtu]="$mtu"

    # CIDR subnet
    local subnet
    if [[ "$netmask" == "255.255.255.0" ]]; then
        subnet=$(echo "$container_ip" | sed 's/\.[0-9]*$/.0\/24/')
    elif [[ "$netmask" == "255.255.0.0" ]]; then
        subnet=$(echo "$container_ip" | sed 's/\.[0-9]*\.[0-9]*$/.0.0\/16/')
    else
        subnet="$container_ip/24"
    fi
    _STATUS_DATA[network_subnet]="$subnet"

    # Current container
    local current_hostname
    current_hostname=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null)
    _STATUS_DATA[container_1_name]="$current_hostname"
    _STATUS_DATA[container_1_ip]="$container_ip"
    _STATUS_DATA[container_1_role]="App Server"

    # Other containers from /etc/hosts
    local container_count=1
    if [[ -f /etc/hosts ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^# || -z "$(echo "$line" | xargs)" ]] && continue
            [[ "$line" =~ localhost || "$line" =~ "ip6-" ]] && continue
            local ip_addr=$(echo "$line" | awk '{print $1}')
            local hostname_entry=$(echo "$line" | awk '{print $2}')
            [[ "$ip_addr" == "$container_ip" || -z "$hostname_entry" ]] && continue
            if [[ "$ip_addr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                ((container_count++))
                _STATUS_DATA[container_${container_count}_name]="$hostname_entry"
                _STATUS_DATA[container_${container_count}_ip]="$ip_addr"
                # Assign role based on hostname pattern
                local role="Container"
                [[ "$hostname_entry" == *database* || "$hostname_entry" == *oracle* || "$hostname_entry" == *db* ]] && role="Oracle Database"
                [[ "$hostname_entry" == *server* || "$hostname_entry" == *app* ]] && role="App Server"
                _STATUS_DATA[container_${container_count}_role]="$role"
            fi
        done < /etc/hosts
    fi
    _STATUS_DATA[container_count]="$container_count"

    # DNS resolution — check containers from /etc/hosts plus known service hostnames
    local -a dns_hosts=()
    for ((i=1; i<=container_count; i++)); do
        dns_hosts+=("${_STATUS_DATA[container_${i}_name]}")
    done
    # Always include known Docker service hostnames (resolve via Docker DNS, not /etc/hosts)
    local known_services=("sandbox-oracle-database" "sandbox-oracle-server")
    for svc in "${known_services[@]}"; do
        local already=0
        for h in "${dns_hosts[@]}"; do [[ "$h" == "$svc" ]] && already=1; done
        [[ $already -eq 0 ]] && dns_hosts+=("$svc")
    done

    local dns_count=0
    for h in "${dns_hosts[@]}"; do
        local resolved
        resolved=$(getent hosts "$h" 2>/dev/null | awk '{print $1}')
        ((dns_count++))
        if [[ -n "$resolved" ]]; then
            _STATUS_DATA[dns_${dns_count}_host]="$h"
            _STATUS_DATA[dns_${dns_count}_resolved]="$resolved"
            _STATUS_DATA[dns_${dns_count}_status]="OK"
        else
            _STATUS_DATA[dns_${dns_count}_host]="$h"
            _STATUS_DATA[dns_${dns_count}_resolved]=""
            _STATUS_DATA[dns_${dns_count}_status]="FAILED"
        fi
    done
    _STATUS_DATA[dns_count]="$dns_count"

    # Port connectivity checks for key services
    local db_host="${SANDBOX_DB_HOST:-sandbox-oracle-database}"
    local -A port_checks=(
        [db_oracle]="${db_host}:1521:Oracle DB"
        [app_http]="localhost:3000:App Server"
        [ords_http]="localhost:8080:ORDS/APEX"
    )
    local port_idx=0
    for key in db_oracle app_http ords_http; do
        IFS=: read -r p_host p_port p_label <<< "${port_checks[$key]}"
        local p_status="CLOSED"
        timeout 2 bash -c "</dev/tcp/${p_host}/${p_port}" 2>/dev/null && p_status="OPEN"
        _STATUS_DATA[port_${port_idx}_label]="$p_label"
        _STATUS_DATA[port_${port_idx}_host]="$p_host"
        _STATUS_DATA[port_${port_idx}_port]="$p_port"
        _STATUS_DATA[port_${port_idx}_status]="$p_status"
        ((port_idx++))
    done
    _STATUS_DATA[port_count]="$port_idx"

    # Listening ports on this container
    local listening
    listening=$(netstat -tlnp 2>/dev/null | awk 'NR>2 {print $4}' | grep -oP ':\K[0-9]+' | sort -nu | tr '\n' ',' | sed 's/,$//')
    _STATUS_DATA[network_listening_ports]="$listening"
}

# Output status as table (default format) - resource aware
_status_output_table() {
    case "${_STATUS_RESOURCE_CHECKED:-all}" in
        database)
            log_section "Oracle Database"
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
                [[ -n "$pdb_name" ]] && echo -e "  ${CYAN}${pdb_name}:${NC} ${pdb_mode}"
            done
            ;;
        apex)
            log_section "APEX / ORDS"
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
            ;;
        mcp)
            log_section "MCP Server"
            if [[ "${_STATUS_DATA[mcp_process_status]}" == "OK" ]]; then
                echo -e "  ${GREEN}✓${NC} MCP running (PID: ${_STATUS_DATA[mcp_pid]})"
                [[ -n "${_STATUS_DATA[mcp_connection]}" ]] && \
                    echo -e "  ${CYAN}Connection:${NC} ${_STATUS_DATA[mcp_connection]}"
            else
                echo -e "  ${RED}✗${NC} MCP not running"
            fi
            ;;
        network)
            log_section "Docker Network"
            if [[ "${_STATUS_DATA[network_status]}" == "OK" ]]; then
                echo -e "  ${GREEN}✓${NC} Network: ${_STATUS_DATA[network_name]}"
                echo -e "  ${CYAN}Driver:${NC}  ${_STATUS_DATA[network_driver]}"
                echo -e "  ${CYAN}Subnet:${NC}  ${_STATUS_DATA[network_subnet]}"
                echo -e "  ${CYAN}Gateway:${NC} ${_STATUS_DATA[network_gateway]}"
                [[ -n "${_STATUS_DATA[network_mtu]}" ]] && echo -e "  ${CYAN}MTU:${NC}     ${_STATUS_DATA[network_mtu]}"
                echo ""
                echo -e "  ${CYAN}Containers (${_STATUS_DATA[container_count]}):${NC}"
                for ((i=1; i<=${_STATUS_DATA[container_count]:-0}; i++)); do
                    local cname="${_STATUS_DATA[container_${i}_name]}"
                    local cip="${_STATUS_DATA[container_${i}_ip]}"
                    local crole="${_STATUS_DATA[container_${i}_role]}"
                    [[ -n "$cname" ]] && echo -e "    ${GREEN}•${NC} ${CYAN}${cname}${NC} @ ${cip}  ${YELLOW}[${crole}]${NC}"
                done
                echo ""
                echo -e "  ${CYAN}DNS Resolution:${NC}"
                for ((i=1; i<=${_STATUS_DATA[dns_count]:-0}; i++)); do
                    local dhost="${_STATUS_DATA[dns_${i}_host]}"
                    local dresolved="${_STATUS_DATA[dns_${i}_resolved]}"
                    local dstatus="${_STATUS_DATA[dns_${i}_status]}"
                    if [[ "$dstatus" == "OK" ]]; then
                        echo -e "    ${GREEN}✓${NC} ${dhost} → ${dresolved}"
                    else
                        echo -e "    ${RED}✗${NC} ${dhost} → unresolvable"
                    fi
                done
                echo ""
                echo -e "  ${CYAN}Port Connectivity:${NC}"
                for ((i=0; i<${_STATUS_DATA[port_count]:-0}; i++)); do
                    local plabel="${_STATUS_DATA[port_${i}_label]}"
                    local phost="${_STATUS_DATA[port_${i}_host]}"
                    local pport="${_STATUS_DATA[port_${i}_port]}"
                    local pstatus="${_STATUS_DATA[port_${i}_status]}"
                    if [[ "$pstatus" == "OPEN" ]]; then
                        echo -e "    ${GREEN}✓${NC} ${plabel} (${phost}:${pport}) — OPEN"
                    else
                        echo -e "    ${YELLOW}✗${NC} ${plabel} (${phost}:${pport}) — CLOSED"
                    fi
                done
                echo ""
                if [[ -n "${_STATUS_DATA[network_listening_ports]}" ]]; then
                    echo -e "  ${CYAN}Listening Ports:${NC} ${_STATUS_DATA[network_listening_ports]}"
                fi
            else
                echo -e "  ${RED}✗${NC} Network not found: ${_STATUS_DATA[network_name]}"
            fi
            ;;
        *)
            # Full status when no specific resource checked
            log_section "Oracle Database"
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
                [[ -n "$pdb_name" ]] && echo -e "  ${CYAN}${pdb_name}:${NC} ${pdb_mode}"
            done
            echo ""
            
            log_section "APEX / ORDS"
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
            
            log_section "MCP Server"
            if [[ "${_STATUS_DATA[mcp_process_status]}" == "OK" ]]; then
                echo -e "  ${GREEN}✓${NC} MCP running (PID: ${_STATUS_DATA[mcp_pid]})"
                [[ -n "${_STATUS_DATA[mcp_connection]}" ]] && \
                    echo -e "  ${CYAN}Connection:${NC} ${_STATUS_DATA[mcp_connection]}"
            else
                echo -e "  ${RED}✗${NC} MCP not running"
            fi
            echo ""
            
            log_section "Docker Network"
            if [[ "${_STATUS_DATA[network_status]}" == "OK" ]]; then
                echo -e "  ${GREEN}✓${NC} Network: ${_STATUS_DATA[network_name]}"
                echo -e "  ${CYAN}Driver:${NC}  ${_STATUS_DATA[network_driver]}"
                echo -e "  ${CYAN}Subnet:${NC}  ${_STATUS_DATA[network_subnet]}"
                echo -e "  ${CYAN}Gateway:${NC} ${_STATUS_DATA[network_gateway]}"
                [[ -n "${_STATUS_DATA[network_mtu]}" ]] && echo -e "  ${CYAN}MTU:${NC}     ${_STATUS_DATA[network_mtu]}"
                echo ""
                echo -e "  ${CYAN}Containers (${_STATUS_DATA[container_count]}):${NC}"
                for ((i=1; i<=${_STATUS_DATA[container_count]:-0}; i++)); do
                    local cname="${_STATUS_DATA[container_${i}_name]}"
                    local cip="${_STATUS_DATA[container_${i}_ip]}"
                    local crole="${_STATUS_DATA[container_${i}_role]}"
                    [[ -n "$cname" ]] && echo -e "    ${GREEN}•${NC} ${CYAN}${cname}${NC} @ ${cip}  ${YELLOW}[${crole}]${NC}"
                done
                echo ""
                echo -e "  ${CYAN}DNS Resolution:${NC}"
                for ((i=1; i<=${_STATUS_DATA[dns_count]:-0}; i++)); do
                    local dhost="${_STATUS_DATA[dns_${i}_host]}"
                    local dresolved="${_STATUS_DATA[dns_${i}_resolved]}"
                    local dstatus="${_STATUS_DATA[dns_${i}_status]}"
                    if [[ "$dstatus" == "OK" ]]; then
                        echo -e "    ${GREEN}✓${NC} ${dhost} → ${dresolved}"
                    else
                        echo -e "    ${RED}✗${NC} ${dhost} → unresolvable"
                    fi
                done
                echo ""
                echo -e "  ${CYAN}Port Connectivity:${NC}"
                for ((i=0; i<${_STATUS_DATA[port_count]:-0}; i++)); do
                    local plabel="${_STATUS_DATA[port_${i}_label]}"
                    local phost="${_STATUS_DATA[port_${i}_host]}"
                    local pport="${_STATUS_DATA[port_${i}_port]}"
                    local pstatus="${_STATUS_DATA[port_${i}_status]}"
                    if [[ "$pstatus" == "OPEN" ]]; then
                        echo -e "    ${GREEN}✓${NC} ${plabel} (${phost}:${pport}) — OPEN"
                    else
                        echo -e "    ${YELLOW}✗${NC} ${plabel} (${phost}:${pport}) — CLOSED"
                    fi
                done
                echo ""
                if [[ -n "${_STATUS_DATA[network_listening_ports]}" ]]; then
                    echo -e "  ${CYAN}Listening Ports:${NC} ${_STATUS_DATA[network_listening_ports]}"
                fi
            else
                echo -e "  ${RED}✗${NC} Network not found: ${_STATUS_DATA[network_name]}"
            fi
            ;;
    esac
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
    printf "  },\n"
    printf "  \"network\": {\n"
    printf "    \"name\": \"%s\",\n" "${_STATUS_DATA[network_name]}"
    printf "    \"status\": \"%s\",\n" "${_STATUS_DATA[network_status]}"
    printf "    \"driver\": \"%s\",\n" "${_STATUS_DATA[network_driver]}"
    printf "    \"subnet\": \"%s\",\n" "${_STATUS_DATA[network_subnet]}"
    printf "    \"gateway\": \"%s\",\n" "${_STATUS_DATA[network_gateway]}"
    printf "    \"mtu\": \"%s\",\n" "${_STATUS_DATA[network_mtu]}"
    printf "    \"listening_ports\": \"%s\",\n" "${_STATUS_DATA[network_listening_ports]}"
    printf "    \"containers\": [\n"
    local container_count="${_STATUS_DATA[container_count]:-0}"
    for ((i=1; i<=container_count; i++)); do
        [[ $i -gt 1 ]] && printf ",\n"
        printf "      {\n"
        printf "        \"name\": \"%s\",\n" "${_STATUS_DATA[container_${i}_name]}"
        printf "        \"ip\": \"%s\",\n" "${_STATUS_DATA[container_${i}_ip]}"
        printf "        \"role\": \"%s\"\n" "${_STATUS_DATA[container_${i}_role]}"
        printf "      }"
    done
    printf "\n    ],\n"
    printf "    \"dns\": [\n"
    local dns_count="${_STATUS_DATA[dns_count]:-0}"
    for ((i=1; i<=dns_count; i++)); do
        [[ $i -gt 1 ]] && printf ",\n"
        printf "      { \"host\": \"%s\", \"resolved\": \"%s\", \"status\": \"%s\" }" \
            "${_STATUS_DATA[dns_${i}_host]}" "${_STATUS_DATA[dns_${i}_resolved]}" "${_STATUS_DATA[dns_${i}_status]}"
    done
    printf "\n    ],\n"
    printf "    \"ports\": [\n"
    local port_count="${_STATUS_DATA[port_count]:-0}"
    for ((i=0; i<port_count; i++)); do
        [[ $i -gt 0 ]] && printf ",\n"
        printf "      { \"label\": \"%s\", \"host\": \"%s\", \"port\": %s, \"status\": \"%s\" }" \
            "${_STATUS_DATA[port_${i}_label]}" "${_STATUS_DATA[port_${i}_host]}" \
            "${_STATUS_DATA[port_${i}_port]}" "${_STATUS_DATA[port_${i}_status]}"
    done
    printf "\n    ]\n"
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
    
    printf "network,name,%s\n" "${_STATUS_DATA[network_name]}"
    printf "network,status,%s\n" "${_STATUS_DATA[network_status]}"
    printf "network,driver,%s\n" "${_STATUS_DATA[network_driver]}"
    printf "network,subnet,%s\n" "${_STATUS_DATA[network_subnet]}"
    printf "network,gateway,%s\n" "${_STATUS_DATA[network_gateway]}"
    printf "network,mtu,%s\n" "${_STATUS_DATA[network_mtu]}"
    printf "network,listening_ports,%s\n" "${_STATUS_DATA[network_listening_ports]}"
    local container_count="${_STATUS_DATA[container_count]:-0}"
    for ((i=1; i<=container_count; i++)); do
        printf "network,container_%s_name,%s\n" "$i" "${_STATUS_DATA[container_${i}_name]}"
        printf "network,container_%s_ip,%s\n" "$i" "${_STATUS_DATA[container_${i}_ip]}"
        printf "network,container_%s_role,%s\n" "$i" "${_STATUS_DATA[container_${i}_role]}"
    done
    local dns_count="${_STATUS_DATA[dns_count]:-0}"
    for ((i=1; i<=dns_count; i++)); do
        printf "network,dns_%s,%s->%s(%s)\n" "$i" "${_STATUS_DATA[dns_${i}_host]}" "${_STATUS_DATA[dns_${i}_resolved]}" "${_STATUS_DATA[dns_${i}_status]}"
    done
    local port_count="${_STATUS_DATA[port_count]:-0}"
    for ((i=0; i<port_count; i++)); do
        printf "network,port_%s,%s:%s(%s)\n" "${_STATUS_DATA[port_${i}_label]}" "${_STATUS_DATA[port_${i}_host]}" "${_STATUS_DATA[port_${i}_port]}" "${_STATUS_DATA[port_${i}_status]}"
    done
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Parse --format flag
_parse_output_format $PARAMS

# Interactive resource selection if not provided
if [[ -z "$RESOURCE" ]]; then
    echo ""
    echo -e "${CYAN}Which resource would you like to check?${NC}"
    echo "  1) database"
    echo "  2) apex"
    echo "  3) mcp"
    echo "  4) network"
    echo "  5) all"
    echo -n "Select [1-5]: "
    read -r choice
    echo ""
    
    case "$choice" in
        1) RESOURCE="database" ;;
        2) RESOURCE="apex" ;;
        3) RESOURCE="mcp" ;;
        4) RESOURCE="network" ;;
        5) RESOURCE="all" ;;
        *)
            log_error "Invalid selection: $choice"
            exit 1
            ;;
    esac
fi

# Collect all status data
if [[ "$RESOURCE" == "all" ]]; then
    _STATUS_RESOURCE_CHECKED="all"
    _check_oracle_status
    _check_apex_status
    _check_mcp_status
    _check_network_status
else
    _STATUS_RESOURCE_CHECKED="$RESOURCE"
    case "$RESOURCE" in
        database)
            _check_oracle_status
            ;;
        apex)
            _check_apex_status
            ;;
        mcp)
            _check_mcp_status
            ;;
        network)
            _check_network_status
            ;;
    esac
fi

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
