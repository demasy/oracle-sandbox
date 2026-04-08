#!/bin/bash
# ============================================
# Docker Build Stage Startup Script
# ============================================
# Handles installation of Oracle components during Docker build
# Usage: Called during Dockerfile build stage
# ============================================

set -e  # Exit on error

# Source utility scripts using absolute paths
source /usr/sandbox/app/system/utils/colors.sh
source /usr/sandbox/app/system/utils/logging.sh
source /usr/sandbox/app/system/utils/banner.sh

print_demasy_banner "Docker Build - Installing Oracle Components"

echo ""

# ============================================
# Install Oracle Instant Client
# ============================================
log_step "Installing Oracle Instant Client..."
/usr/sandbox/app/system/install/install-client.sh

echo ""

# ============================================
# Install SQLcl
# ============================================
log_step "Installing SQLcl..."
/usr/sandbox/app/system/install/install-sqlcl.sh

echo ""

log_success "Oracle components installed successfully!"
echo ""
