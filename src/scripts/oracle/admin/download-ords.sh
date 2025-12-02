#!/bin/bash
# ============================================
# Oracle ORDS Software Installer
# ============================================
# Downloads and installs Oracle ORDS software from oracle.com
# Usage: install-ords
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../utils/colors.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/banner.sh"

print_demasy_banner "Oracle ORDS Software Installer"

echo ""

# Check if Instant Client is installed (required dependency)
if [ ! -d "/opt/oracle/instantclient" ] || [ -z "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
    log_error "Oracle Instant Client is not installed"
    log_error "ORDS requires Oracle Instant Client to be installed first"
    echo ""
    log_info "Please run: ${BOLD}${CYAN}install-client${RESET}"
    echo ""
    exit 1
fi

# Check if already installed
if [ -d "/opt/oracle/ords" ] && [ -n "$(ls -A /opt/oracle/ords/*.war 2>/dev/null)" ]; then
    log_success "Oracle ORDS is already installed"
    log_info "Location: /opt/oracle/ords"
    # Try to find version
    WAR_FILE=$(ls /opt/oracle/ords/*.war 2>/dev/null | head -1)
    if [ -n "$WAR_FILE" ]; then
        log_info "WAR file: $(basename "$WAR_FILE")"
    fi
    echo ""
    exit 0
fi

log_info "Downloading Oracle ORDS from oracle.com"
log_warn "By downloading, you accept Oracle's license terms"
echo ""

log_step "Downloading ORDS..."
log_info "Downloading from: oracle.com"

curl -L -o /tmp/ords.zip "https://download.oracle.com/otn_software/java/ords/ords-latest.zip"

if [ $? -eq 0 ]; then
    log_step "Extracting ORDS..."
    mkdir -p /opt/oracle/ords
    unzip -qo /tmp/ords.zip -d /opt/oracle/ords
    
    log_step "Cleaning up..."
    rm /tmp/ords.zip
    
    log_success "ORDS installed successfully!"
    log_info "Location: /opt/oracle/ords"
    
    # Display WAR file info
    WAR_FILE=$(ls /opt/oracle/ords/*.war 2>/dev/null | head -1)
    if [ -n "$WAR_FILE" ]; then
        echo ""
        log_info "WAR file: $(basename "$WAR_FILE")"
        log_info "Size: $(du -h "$WAR_FILE" | cut -f1)"
    fi
else
    log_error "Failed to download ORDS"
    log_error "Please check your internet connection and try again"
    exit 1
fi

echo ""
