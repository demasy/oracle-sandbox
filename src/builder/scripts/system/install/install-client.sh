#!/bin/bash
# ============================================
# Oracle Instant Client Installer
# ============================================
# Downloads and installs Oracle Instant Client from GitHub releases
# Usage: install-client
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh"
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"

print_demasy_banner "Oracle Instant Client Installer"

echo ""

# Check if already installed
if [ -d "/opt/oracle/instantclient" ] && [ -n "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
    log_success "Oracle Instant Client is already installed"
    log_info "Location: /opt/oracle/instantclient"
    echo ""
    exit 0
fi

log_info "Downloading Oracle Instant Client from GitHub releases"
log_warn "By downloading, you accept Oracle's license terms"
echo ""

# Detect architecture
ARCH=$(uname -m)
log_info "Detected architecture: $ARCH"

# Download Oracle Instant Client from GitHub Release
log_step "Downloading Oracle Instant Client..."

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
    
    log_success "Installation complete!"
else
    log_error "Failed to download Instant Client"
    log_error "Please check your internet connection and try again"
    exit 1
fi

echo ""
