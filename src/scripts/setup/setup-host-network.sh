#!/bin/bash
#==============================================================================
# Setup Host Network Routes for Docker Container Access
# Allows direct access to container IPs from macOS host
#==============================================================================

# Load utilities
source /usr/demasy/scripts/utils/colors.sh 2>/dev/null || {
    # Fallback colors if not available
    export COLOR_INFO="\033[36m"
    export COLOR_SUCCESS="\033[32m" 
    export COLOR_ERROR="\033[31m"
    export COLOR_RESET="\033[0m"
}

log_info() { echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"; }
log_success() { echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $1"; }
log_error() { echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1"; }

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
DOCKER_NETWORK_SUBNET="192.168.1.0/24"
DOCKER_GATEWAY_IP=$(docker network inspect demasylabs_network --format='{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || echo "192.168.1.1")

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
setup_route() {
    log_info "Setting up host route to Docker network..."
    
    # Check if Docker Desktop is using bridge networking
    local bridge_ip=$(docker network inspect bridge --format='{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null)
    
    if [[ -z "$bridge_ip" ]]; then
        log_error "Could not determine Docker bridge IP"
        return 1
    fi
    
    # Add route to Docker network subnet via Docker bridge
    if route -n get ${DOCKER_NETWORK_SUBNET} >/dev/null 2>&1; then
        log_info "Route already exists, removing..."
        sudo route -n delete ${DOCKER_NETWORK_SUBNET} >/dev/null 2>&1 || true
    fi
    
    log_info "Adding route: ${DOCKER_NETWORK_SUBNET} via ${DOCKER_GATEWAY_IP}"
    if sudo route -n add ${DOCKER_NETWORK_SUBNET} ${DOCKER_GATEWAY_IP} >/dev/null 2>&1; then
        log_success "Route added successfully!"
    else
        log_error "Failed to add route. You may need to run with sudo."
        return 1
    fi
}

remove_route() {
    log_info "Removing host route to Docker network..."
    if route -n get ${DOCKER_NETWORK_SUBNET} >/dev/null 2>&1; then
        if sudo route -n delete ${DOCKER_NETWORK_SUBNET} >/dev/null 2>&1; then
            log_success "Route removed successfully!"
        else
            log_error "Failed to remove route"
            return 1
        fi
    else
        log_info "Route does not exist"
    fi
}

show_status() {
    echo
    log_info "Network Status:"
    echo "  Docker Network: ${DOCKER_NETWORK_SUBNET}"
    echo "  Gateway IP: ${DOCKER_GATEWAY_IP}"
    echo
    
    if route -n get ${DOCKER_NETWORK_SUBNET} >/dev/null 2>&1; then
        log_success "✅ Host route is configured"
        echo "  Database accessible at: 192.168.1.110:1521"
        echo "  Management server at: 192.168.1.120:3000"
    else
        log_info "❌ No host route configured"
        echo "  Use port forwarding: localhost:1521"
    fi
}

test_connectivity() {
    log_info "Testing connectivity to containers..."
    
    # Test database container
    if nc -zv -w 3 192.168.1.110 1521 >/dev/null 2>&1; then
        log_success "✅ Database (192.168.1.110:1521) - Reachable"
    else
        log_error "❌ Database (192.168.1.110:1521) - Not reachable"
    fi
    
    # Test management server  
    if nc -zv -w 3 192.168.1.120 3000 >/dev/null 2>&1; then
        log_success "✅ Management (192.168.1.120:3000) - Reachable" 
    else
        log_error "❌ Management (192.168.1.120:3000) - Not reachable"
    fi
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
case "${1:-status}" in
    "setup"|"add")
        setup_route
        show_status
        test_connectivity
        ;;
    "remove"|"delete")
        remove_route
        show_status
        ;;
    "test")
        test_connectivity
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 {setup|remove|test|status}"
        echo
        echo "Commands:"
        echo "  setup   - Add host route to Docker network"
        echo "  remove  - Remove host route"
        echo "  test    - Test connectivity to containers"
        echo "  status  - Show current network status"
        exit 1
        ;;
esac