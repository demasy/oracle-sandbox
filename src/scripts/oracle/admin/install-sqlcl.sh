#!/bin/bash
# ============================================
# Oracle SQLcl Installer
# ============================================
# Downloads and installs Oracle SQLcl from oracle.com
# Usage: install-sqlcl
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh"
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"

print_demasy_banner "Oracle SQLcl Installer"

echo ""

# Check if Instant Client is installed (required dependency)
if [ ! -d "/opt/oracle/instantclient" ] || [ -z "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
    log_error "Oracle Instant Client not installed"
    log_error "SQLcl requires Oracle Instant Client to be installed first"
    echo ""
    log_info "Please run: ${BOLD}${CYAN}install-client${RESET}"
    echo ""
    exit 1
fi

# Check if already installed
if [ -d "/opt/oracle/sqlcl" ] && [ -f "/opt/oracle/sqlcl/bin/sql" ]; then
    log_success "SQLcl is already installed"
    log_info "Location: /opt/oracle/sqlcl"
    # Try to get version
    if [ -x "/opt/oracle/sqlcl/bin/sql" ]; then
        VERSION=$(/opt/oracle/sqlcl/bin/sql -version 2>/dev/null | head -1 || echo "Version unknown")
        log_info "Version: $VERSION"
    fi
    echo ""
    exit 0
fi

log_info "Downloading SQLcl from oracle.com"
log_warn "By downloading, you accept Oracle's license terms"
echo ""

log_step "Downloading SQLcl..."
log_info "Downloading from: oracle.com"

curl -L -o /tmp/sqlcl.zip "https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip"

if [ $? -eq 0 ]; then
    log_step "Extracting SQLcl..."
    mkdir -p /opt/oracle
    unzip -qo /tmp/sqlcl.zip -d /opt/oracle
    
    log_step "Cleaning up..."
    rm /tmp/sqlcl.zip
    
    log_success "SQLcl installed successfully!"
    log_info "Location: /opt/oracle/sqlcl"
    
    # Display version
    if [ -x "/opt/oracle/sqlcl/bin/sql" ]; then
        echo ""
        log_info "Verifying installation..."
        /opt/oracle/sqlcl/bin/sql -version 2>/dev/null | head -1 || log_warn "Could not verify version"
    fi
else
    log_error "Failed to download SQLcl"
    log_error "Please check your internet connection and try again"
    exit 1
fi

echo ""
