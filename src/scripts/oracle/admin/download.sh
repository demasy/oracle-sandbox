#!/bin/bash
# ============================================
# Oracle Components Downloader
# ============================================
# Downloads Oracle Instant Client from GitHub releases
# Usage: Run inside container with: download-oracle-components
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh"
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"

clear
print_demasy_banner "Oracle Components Downloader"

echo ""
log_info "This script downloads Oracle components:"
log_info "  • Oracle Instant Client (from GitHub Release)"
log_info "  • SQLcl (from oracle.com)"
log_info "  • APEX (from oracle.com)"
log_info "  • ORDS (from oracle.com)"
echo ""
log_warn "By downloading, you accept Oracle's license terms"
echo ""

# Detect architecture
ARCH=$(uname -m)
log_info "Detected architecture: $ARCH"
echo ""

# ============================================
# 1. Download Oracle Instant Client
# ============================================
log_step "[1/4] Downloading Oracle Instant Client..."

if [ "$ARCH" = "x86_64" ]; then
    IC_FILE="instantclient-basic-linux-x64-23.7.0.24.10.zip"
elif [ "$ARCH" = "aarch64" ]; then
    IC_FILE="instantclient-basic-linux-x64-23.7.0.24.10.zip"
    log_warn "Using x64 Instant Client with emulation on ARM64"
else
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

IC_URL="https://github.com/demasy/oracle-sandbox/releases/download/oracle-ic-23.7/$IC_FILE"

log_info "Downloading from: $IC_URL"

curl -L -f "$IC_URL" -o /tmp/instantclient.zip

if [ $? -eq 0 ]; then
    log_step "Extracting Instant Client..."
    unzip -qo /tmp/instantclient.zip -d /tmp
    
    log_step "Installing to /opt/oracle/instantclient..."
    mkdir -p /opt/oracle
    mv /tmp/libs/oracle/clients/instantclient_23_7 /opt/oracle/instantclient
    
    log_step "Cleaning up..."
    rm -rf /tmp/instantclient.zip /tmp/libs
    
    log_success "Oracle Instant Client installed successfully!"
    log_info "Location: /opt/oracle/instantclient"
    
    # Set library path
    echo ""
    log_info "Setting LD_LIBRARY_PATH..."
    export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
    echo "export LD_LIBRARY_PATH=/opt/oracle/instantclient:\$LD_LIBRARY_PATH" >> ~/.bashrc
    
    log_success "Oracle Instant Client installed!"
else
    log_error "Failed to download Instant Client"
    exit 1
fi

echo ""

# ============================================
# 2. Download SQLcl
# ============================================
log_step "[2/4] Downloading SQLcl..."
log_info "Downloading from: oracle.com"

curl -L -o /tmp/sqlcl.zip "https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip"

if [ $? -eq 0 ]; then
    log_step "Extracting SQLcl..."
    unzip -qo /tmp/sqlcl.zip -d /opt/oracle
    rm /tmp/sqlcl.zip
    log_success "SQLcl installed!"
else
    log_error "Failed to download SQLcl"
    exit 1
fi

echo ""

# ============================================
# 3. Download APEX
# ============================================
log_step "[3/4] Downloading Oracle APEX 24.2..."
log_info "Downloading from: oracle.com (~250MB, may take a few minutes)"

curl -L -o /tmp/apex.zip "https://download.oracle.com/otn_software/apex/apex-latest.zip"

if [ $? -eq 0 ]; then
    log_step "Extracting APEX..."
    unzip -qo /tmp/apex.zip -d /opt/oracle
    rm /tmp/apex.zip
    log_success "APEX installed!"
else
    log_error "Failed to download APEX"
    exit 1
fi

echo ""

# ============================================
# 4. Download ORDS
# ============================================
log_step "[4/4] Downloading Oracle ORDS 25.3..."
log_info "Downloading from: oracle.com"

curl -L -o /tmp/ords.zip "https://download.oracle.com/otn_software/java/ords/ords-latest.zip"

if [ $? -eq 0 ]; then
    log_step "Extracting ORDS..."
    mkdir -p /opt/oracle/ords
    unzip -qo /tmp/ords.zip -d /opt/oracle/ords
    rm /tmp/ords.zip
    log_success "ORDS installed!"
else
    log_error "Failed to download ORDS"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "All Oracle components downloaded successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Installation locations:"
echo "  • Instant Client: /opt/oracle/instantclient"
echo "  • SQLcl:          /opt/oracle/sqlcl"
echo "  • APEX:           /opt/oracle/apex"
echo "  • ORDS:           /opt/oracle/ords"
echo ""
log_info "Next steps:"
echo "  1. Connect to database: ${BOLD}${CYAN}sqlcl${RESET}"
echo "  2. Install APEX/ORDS:   ${BOLD}${CYAN}install-apex${RESET}"
echo "  3. Start APEX:          ${BOLD}${CYAN}start-apex${RESET}"
echo ""
