#!/bin/bash
# ============================================
# Oracle SQL*Plus Installer
# ============================================
# Downloads and installs Oracle SQL*Plus from oracle.com
# Usage: install-sqlplus
# Note: Only available for x86_64 architecture
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../utils/colors.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/banner.sh"

print_demasy_banner "Oracle SQL*Plus Installer"

echo ""

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    log_error "SQL*Plus is only available for x86_64 architecture"
    log_info "Current architecture: $ARCH"
    echo ""
    log_info "Alternative: Use ${BOLD}${CYAN}SQLcl${RESET} which works on all architectures"
    log_info "Install SQLcl: ${BOLD}${CYAN}install-sqlcl${RESET}"
    echo ""
    exit 1
fi

# Check if Instant Client is installed (required dependency)
if [ ! -d "/opt/oracle/instantclient" ] || [ -z "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
    log_error "Oracle Instant Client is not installed"
    log_error "SQL*Plus requires Oracle Instant Client to be installed first"
    echo ""
    log_info "Please run: ${BOLD}${CYAN}install-client${RESET}"
    echo ""
    exit 1
fi

# Check if already installed
if command -v sqlplus &> /dev/null && sqlplus -version &> /dev/null; then
    log_success "SQL*Plus is already installed"
    VERSION=$(sqlplus -version 2>/dev/null | head -1)
    log_info "Version: $VERSION"
    echo ""
    exit 0
fi

log_info "Downloading SQL*Plus from oracle.com"
log_warn "By downloading, you accept Oracle's license terms"
echo ""

log_step "Downloading SQL*Plus..."
log_info "Downloading from: oracle.com"

# Download SQL*Plus (Basic + Tools package includes sqlplus)
curl -L -o /tmp/sqlplus.zip "https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-sqlplus-linux.x64-23.7.0.24.10.zip"

if [ $? -eq 0 ]; then
    log_step "Extracting SQL*Plus..."
    unzip -qo /tmp/sqlplus.zip -d /tmp
    
    log_step "Installing to /opt/oracle/instantclient..."
    # Copy sqlplus binaries to existing instantclient directory
    cp -r /tmp/instantclient_23_7/* /opt/oracle/instantclient/
    
    log_step "Cleaning up..."
    rm -rf /tmp/sqlplus.zip /tmp/instantclient_23_7
    
    log_success "SQL*Plus installed successfully!"
    log_info "Location: /opt/oracle/instantclient"
    
    # Verify installation
    if command -v sqlplus &> /dev/null; then
        echo ""
        log_info "Verifying installation..."
        sqlplus -version 2>/dev/null | head -1 || log_warn "Could not verify version"
    fi
else
    log_error "Failed to download SQL*Plus"
    log_error "Please check your internet connection and try again"
    exit 1
fi

echo ""
