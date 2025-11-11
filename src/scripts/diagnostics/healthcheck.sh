#!/bin/bash

# Colors for out    echo -e "\e[0;33m-------------------------------------\e[0m"
    echo -e "\e[0;33mDeveloped by \e[1m\e[0;33mDemasy Labs\e[0m\e[0;33m 🚀\e[0m"
    echo -e "\e[0;33m👤 Ahmed El-Demasy ~ Founder @Demasy Labs \e[0m"
    echo -e "\e[0;33m🏆 Oracle Solutions Architect | Oracle ACE\e[0m"
    echo -e "\e[0;33m💻 www.github.com/demasy\e[0m"
    echo -e "\e[0;33m🌐 www.demasy.io | founder@demasy.io | +966507630060\e[0m"D='\033[0;91m'      # Dark Red (Bright Red)
GREEN='\033[0;92m'    # Dark Green (Bright Green)
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Health check configuration
SERVER_URL="http://localhost:3000/health"
TIMEOUT=10
MAX_RETRIES=3
CHECK_INTERVAL=2

# Function to print banner
print_banner() {
    clear
    echo ""
    echo -e "\e[0;33m ____  _____ __  __    _    ______   __\e[0m"
    echo -e "\e[0;33m|  _ \| ____|  \/  |  / \  / ___\ \ / /\e[0m"
    echo -e "\e[0;33m| | | |  _| | |\/| | / _ \ \___ \\\\ V /\e[0m" 
    echo -e "\e[0;33m| |_| | |___| |  | |/ ___ \ ___) || |\e[0m"
    echo -e "\e[0;33m|____/|_____|_|  |_/_/   \_\____/ |_|\e[0m"
    echo ""
    echo -e "                             \e[0;33m\e[5mL A B S\e[0m"
    echo ""
    echo -e "\e[0;33mDeveloped by: \e[1m\e[0;33mDemasy Labs\e[0m\e[0;33m 🚀\e[0m"
    # echo -e "\e[0;33m\e[1mAhmed El-Demasy ~ Founder @Demasy Labs\e[0m"
    # echo -e "\e[0;33mOracle Solutions Architect | Oracle ACE 🏆\e[0m"
    # echo -e "\e[0;33mwww.github.com/demasy\e[0m"
    # echo -e "\e[0;33mwww.demasy.io | founder@demasy.io | +966507630060\e[0m"
    echo -e "\e[0;33m-----------------------------------------------------\e[0m"    
    echo -e "\e[0;33m        Code with love ❤️  in Egypt \e[0m"     
    # echo -e "\e[0;33m        Code with love \e[5m❤️\e[0m\e[0;33m  in Egypt \e[0m" 
    echo ""
    echo ""
    echo -e "\e[1m************* Health Check! ************* \e[0m"
    echo ""
}

# Function to check server HTTP health
check_server_health() {
    echo -e "\e[1mServer Health:\e[0m"
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check server connectivity and response"
    # echo -e " - Testing connection to management server"
    # echo -e " - Validating server response"
    
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        echo -e " - Checking server health (attempt $attempt/$MAX_RETRIES)..."
        
        local response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT $SERVER_URL 2>/dev/null)
        local curl_exit_code=$?
        
        if [ $curl_exit_code -eq 0 ] && [ "$response" -eq 200 ]; then
            echo -e " - Server HTTP Health: ${GREEN}✓ OK${NC} (Status: $response)"
            return 0
        else
            echo -e " - Server HTTP Health: ${YELLOW}⚠ FAILED${NC} (Status: $response, Exit Code: $curl_exit_code)"
            if [ $attempt -lt $MAX_RETRIES ]; then
                echo -e "   - Retrying in $CHECK_INTERVAL seconds..."
                sleep $CHECK_INTERVAL
            fi
        fi
        ((attempt++))
    done
    
    echo -e " - Server HTTP Health: ${RED}✗ CRITICAL${NC} - Failed after $MAX_RETRIES attempts"
    return 1
}

# Function to check Oracle database connectivity
check_database_health() {
    echo -e "\e[1mDatabase Connectivity:\e[0m"
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check Oracle database connection and accessibility"
    # echo -e "- Validating database configuration"
    # echo -e "- Testing database port connectivity"
    
    # Check if environment variables are set
    if [[ -z "$DEMASYLABS_DB_HOST" || -z "$DEMASYLABS_DB_PORT" || -z "$DEMASYLABS_DB_SERVICE" ]]; then
        echo -e " - Database Config: ${YELLOW}⚠ INCOMPLETE${NC} - Missing environment variables"
        return 1
    fi
    
    # echo -e " - Database: ${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}"
    
    # Test database connection using a simple network check first
    local port_check=$(timeout 5 bash -c "</dev/tcp/$DEMASYLABS_DB_HOST/$DEMASYLABS_DB_PORT" 2>/dev/null && echo "OK" || echo "FAILED")
    
    if [ "$port_check" = "OK" ]; then
        echo -e " - Database Port: ${GREEN}✓ REACHABLE${NC}"
        
        # Test actual database connection using SQLcl
        local db_test=$(timeout 10 bash -c "echo 'SELECT 1 FROM DUAL; EXIT;' | sql -S system/${DEMASYLABS_DB_PASS}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}" 2>/dev/null | grep -c "1" || echo "0")
        
        if [ "$db_test" -gt 0 ]; then
            echo -e " - Database Connectivity: ${GREEN}✓ OK${NC}"
            return 0
        else
            echo -e " - Database Connectivity: ${YELLOW}⚠ LIMITED${NC} - Port reachable but SQL test failed"
            return 0  # Don't fail the entire health check if port is reachable
        fi
    else
        echo -e " - Database Port: ${RED}✗ UNREACHABLE${NC}"
        return 1
    fi
}

# Function to check Oracle clients
check_oracle_clients() {
    echo -e "\e[1mOracle Clients:\e[0m"
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check SQLcl and SQL*Plus client availability"
    # echo -e " - Verifying SQLcl installation and configuration"
    # echo -e " - Testing SQL*Plus connectivity tools"
    
    local sqlcl_status="FAILED"
    local sqlplus_status="FAILED"
    
    # Check SQLcl
    if command -v sql &> /dev/null; then
        sqlcl_status="OK"
        echo -e " - SQLcl Client: ${GREEN}✓ OK${NC}"
    else
        echo -e " - SQLcl Client: ${RED}✗ FAILED${NC}"
    fi
    
    # Check SQL*Plus (or fallback)
    if command -v sqlplus &> /dev/null; then
        sqlplus_status="OK"
        echo -e " - SQL*Plus Client: ${GREEN}✓ OK${NC}"
    else
        echo -e " - SQL*Plus Client: ${RED}✗ FAILED${NC}"
    fi
    
    # Check architecture and client compatibility
    local arch=$(uname -m)
    echo -e " - Architecture: $arch"
    if [ "$arch" = "aarch64" ]; then
        echo -e "   ${RED}Note: Using SQLcl as SQL*Plus fallback on ARM64${NC}"
    fi
    
    if [ "$sqlcl_status" = "OK" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check system resources
check_system_resources() {
    echo -e "\e[1mSystem Resources:\e[0m"
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Check system resource usage and process status"
    
    # Memory usage
    local memory_info=$(free -m 2>/dev/null || echo "Memory info unavailable")
    if [ "$memory_info" != "Memory info unavailable" ]; then
        local memory_used=$(echo "$memory_info" | awk 'NR==2{printf "%.1f", $3*100/$2}')
        echo -e "   - Memory Usage: ${memory_used}%"
    fi
    
    # Disk usage for the application directory
    local disk_usage=$(df -h /usr/demasy 2>/dev/null | awk 'NR==2{print $5}' | sed 's/%//')
    if [ -n "$disk_usage" ]; then
        if [ "$disk_usage" -lt 85 ]; then
            echo -e " - Disk Usage: ${GREEN}✓ OK${NC} (${disk_usage}%)"
        else
            echo -e " - Disk Usage: ${YELLOW}⚠ HIGH${NC} (${disk_usage}%)"
        fi
    fi
    
    # Process check using /proc filesystem
    local node_processes=0
    if [ -d "/proc" ]; then
        for pid_dir in /proc/[0-9]*; do
            if [ -f "$pid_dir/cmdline" ]; then
                local cmdline=$(cat "$pid_dir/cmdline" 2>/dev/null | tr '\0' ' ')
                if echo "$cmdline" | grep -q "node.*app.js"; then
                    ((node_processes++))
                fi
            fi
        done
    fi
    
    if [ "$node_processes" -gt 0 ]; then
        echo -e " - Application Process: ${GREEN}✓ OK${NC} ($node_processes process(es))"
    else
        echo -e " - Application Process: ${YELLOW}⚠ CHECK${NC} - Specific app.js process not found"
        
        # Alternative check for any node processes
        local any_node=0
        if [ -d "/proc" ]; then
            for pid_dir in /proc/[0-9]*; do
                if [ -f "$pid_dir/cmdline" ]; then
                    local cmdline=$(cat "$pid_dir/cmdline" 2>/dev/null | tr '\0' ' ')
                    if echo "$cmdline" | grep -q "node"; then
                        ((any_node++))
                    fi
                fi
            done
        fi
        
        if [ "$any_node" -gt 0 ]; then
            echo -e "     - Node.js Runtime: ${GREEN}✓ OK${NC} ($any_node process(es))"
        else
            echo -e "     - Node.js Runtime: ${RED}✗ FAILED${NC} - No Node.js processes found"
            return 1
        fi
    fi
    
    return 0
}

# Function to display summary
display_summary() {
    local overall_status=$1
    echo ""
    echo -e "${NC}========================================${NC}"
    echo -e "${NC}Health Check Summary${NC}"
    echo -e "${NC}========================================${NC}"
    echo -e "${NC}Timestamp: $(date)${NC}"
    echo -e "${NC}Container: $(hostname)${NC}"
    echo -e "${NC}Environment: ${ENVIRONMENT:-development}${NC}"
    echo ""
    
    if [ $overall_status -eq 0 ]; then
        echo -e "${GREEN}Overall Status: HEALTHY ✓${NC}"
        echo ""
        echo "All systems operational! 🚀"
    else
        echo -e "${RED}Overall Status: UNHEALTHY ✗${NC}"
    fi
    echo -e "${NC}========================================${NC}"
    echo ""
}

# Main health check function
main() {
    print_banner
    
    local overall_status=0
    local component_failures=0
    
    # Run all health checks in priority order
    # 1. System Resources - Foundation layer
    check_system_resources || { overall_status=1; ((component_failures++)); }
    echo ""
    
    # 2. Database Connectivity - Core data service
    check_database_health || { overall_status=1; ((component_failures++)); }
    echo ""
    
    # 3. Oracle Clients - Database tools
    check_oracle_clients || { overall_status=1; ((component_failures++)); }
    echo ""
    
    # 4. Server Health - Application layer
    check_server_health || { overall_status=1; ((component_failures++)); }
    echo ""
    
    # Display summary
    display_summary $overall_status
    
    # Exit with appropriate code
    if [ $overall_status -eq 0 ]; then
        echo -e "${GREEN}All systems operational! 🚀${NC}"
        exit 0
    else
        echo -e "${RED}$component_failures component(s) failing! ⚠️${NC}"
        exit 1
    fi
}

# Run the health check
main "$@"
