#!/bin/bash
# ============================================
# Oracle Components - Install All
# ============================================
# Downloads and installs all Oracle components in sequence
# Usage: install-all
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/../../utils/colors.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/banner.sh"

clear
print_demasy_banner "Oracle Components - Install All"

echo ""
log_info "This script will install all Oracle components:"
log_info "  • Oracle Instant Client (from GitHub Release)"
log_info "  • SQLcl (from oracle.com)"
log_info "  • SQL*Plus (from oracle.com - x86_64 only)"
log_info "  • APEX (from oracle.com)"
log_info "  • ORDS (from oracle.com)"
echo ""
log_warn "By proceeding, you accept Oracle's license terms"
log_warn "Total download size: ~510MB"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warn "Installation cancelled"
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Starting installation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track failures
FAILED_COMPONENTS=()

# ============================================
# 1. Install Oracle Instant Client
# ============================================
echo ""
log_step "[1/4] Oracle Instant Client"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/install-client.sh"
if [ $? -ne 0 ]; then
    FAILED_COMPONENTS+=("Instant Client")
fi

# ============================================
# 2. Install SQLcl
# ============================================
echo ""
log_step "[2/4] SQLcl"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/install-sqlcl.sh"
if [ $? -ne 0 ]; then
    FAILED_COMPONENTS+=("SQLcl")
fi

# ============================================
# 3. Install SQL*Plus
# ============================================
echo ""
log_step "[3/4] SQL*Plus"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    bash "$SCRIPT_DIR/install-sqlplus.sh"
    if [ $? -ne 0 ]; then
        FAILED_COMPONENTS+=("SQL*Plus")
    fi
else
    log_warn "SQL*Plus is only available for x86_64 architecture"
    log_info "Skipping SQL*Plus installation (use SQLcl instead)"
fi

# ============================================
# 4. Install APEX & ORDS
# ============================================
echo ""
log_step "[4/4] Oracle APEX & ORDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/download-apex.sh"
if [ $? -ne 0 ]; then
    FAILED_COMPONENTS+=("APEX & ORDS")
fi
if [ $? -ne 0 ]; then
    FAILED_COMPONENTS+=("ORDS")
fi

# ============================================
# Summary
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#FAILED_COMPONENTS[@]} -eq 0 ]; then
    log_success "All Oracle components installed successfully!"
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
            "Instant Client")
                echo "  ${CYAN}install-client${RESET}"
                ;;
            "SQLcl")
                echo "  ${CYAN}install-sqlcl${RESET}"
                ;;
            "SQL*Plus")
                echo "  ${CYAN}install-sqlplus${RESET}"
                ;;
            "APEX & ORDS")
                echo "  ${CYAN}install-apex${RESET}"
                ;;
        esac
    done
    echo ""
    exit 1
fi
