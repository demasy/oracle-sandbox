#!/bin/bash
# ============================================
# Oracle APEX Software Installer (Standalone)
# ============================================
# Downloads and installs Oracle APEX software from oracle.com
# Usage: install-apex-standalone
# Note: This only installs APEX software, not ORDS
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh"
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"

print_demasy_banner "Oracle APEX Software Installer (Standalone)"

echo ""

# Check if Instant Client is installed (required dependency)
if [ ! -d "/opt/oracle/instantclient" ] || [ -z "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
    log_error "Oracle Instant Client is not installed"
    log_error "APEX requires Oracle Instant Client to be installed first"
    echo ""
    log_info "Please run: ${BOLD}${CYAN}install-client${RESET}"
    echo ""
    exit 1
fi

# Check if already installed
if [ -d "/opt/oracle/apex" ] && [ -f "/opt/oracle/apex/apexins.sql" ]; then
    log_success "Oracle APEX is already installed"
    log_info "Location: /opt/oracle/apex"
    # Try to get version from coreins.sql
    if [ -f "/opt/oracle/apex/core/coreins.sql" ]; then
        VERSION=$(grep -oP "Release \K[0-9.]+" /opt/oracle/apex/apxdvins.sql 2>/dev/null | head -1 || echo "Version unknown")
        log_info "Version: $VERSION"
    fi
    echo ""
    exit 0
fi

log_info "Downloading Oracle APEX from oracle.com"
log_warn "By downloading, you accept Oracle's license terms"
log_warn "This is a large file (~250MB), it may take several minutes"
echo ""

log_step "Downloading APEX..."
log_info "Downloading from: oracle.com"

curl -L -o /tmp/apex.zip "https://download.oracle.com/otn_software/apex/apex-latest.zip"

if [ $? -eq 0 ]; then
    log_step "Extracting APEX..."
    mkdir -p /opt/oracle
    unzip -qo /tmp/apex.zip -d /opt/oracle
    
    log_step "Cleaning up..."
    rm /tmp/apex.zip
    
    log_success "APEX installed successfully!"
    log_info "Location: /opt/oracle/apex"
    
    # Display version info
    if [ -f "/opt/oracle/apex/apexins.sql" ]; then
        echo ""
        log_info "Installation verified"
        log_info "Use 'install-apex' to install APEX into the database"
    fi
else
    log_error "Failed to download APEX"
    log_error "Please check your internet connection and try again"
    exit 1
fi

echo ""
