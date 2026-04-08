#!/bin/bash
# ============================================
# Oracle APEX & ORDS Installer
# ============================================
# Downloads and installs both APEX and ORDS software
# Usage: install-apex
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh"
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"

clear
print_demasy_banner "Oracle APEX & ORDS Installer"

echo ""
log_info "This script will install:"
log_info "  • Oracle APEX software"
log_info "  • Oracle ORDS software"
echo ""
log_warn "By proceeding, you accept Oracle's license terms"
echo ""

# Check if Instant Client is installed (required dependency)
if [ ! -d "/opt/oracle/instantclient" ] || [ -z "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
    log_error "Oracle Instant Client is not installed"
    log_error "APEX & ORDS require Oracle Instant Client to be installed first"
    echo ""
    log_info "Please run: ${BOLD}${CYAN}install-client${RESET}"
    echo ""
    exit 1
fi

# Track failures
FAILED_COMPONENTS=()

# ============================================
# 1. Install APEX Software
# ============================================
echo ""
log_step "[1/2] Installing APEX Software"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/download-apex-standalone.sh"
if [ $? -ne 0 ]; then
    FAILED_COMPONENTS+=("APEX")
fi

# ============================================
# 2. Install ORDS Software
# ============================================
echo ""
log_step "[2/2] Installing ORDS Software"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/download-ords.sh"
if [ $? -ne 0 ]; then
    FAILED_COMPONENTS+=("ORDS")
fi

# ============================================
# Summary
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#FAILED_COMPONENTS[@]} -eq 0 ]; then
    log_success "APEX & ORDS software installed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Installation locations:"
    echo "  • APEX: /opt/oracle/apex"
    echo "  • ORDS: /opt/oracle/ords"
    echo ""
    log_info "Next steps:"
    echo "  1. These are software files only"
    echo "  2. Use the existing ${BOLD}${CYAN}install-apex${RESET} script to configure APEX in the database"
    echo "  3. Use ${BOLD}${CYAN}start-apex${RESET} to start ORDS"
    echo ""
else
    log_error "Some components failed to install:"
    for component in "${FAILED_COMPONENTS[@]}"; do
        echo "  ✗ $component"
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "You can retry individual components:"
    for component in "${FAILED_COMPONENTS[@]}"; do
        case $component in
            "APEX")
                echo "  ${CYAN}install-apex-standalone${RESET}"
                ;;
            "ORDS")
                echo "  ${CYAN}install-ords${RESET}"
                ;;
        esac
    done
    echo ""
    exit 1
fi
