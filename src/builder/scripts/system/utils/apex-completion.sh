#!/bin/bash
################################################################################
# APEX Installation Completion Message
# Displays final success message and access information
# NOTE: This script is meant to be sourced, not executed directly
################################################################################

# Get the directory of this script to source banner.sh from same location
_APEX_COMPLETION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_APEX_COMPLETION_DIR/banner.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Function to display completion message
display_completion_message() {
    local APEX_ADMIN_USERNAME="${1}"
    local APEX_PASSWORD="${2}"
    local APEX_EMAIL="${3}"
    local ORDS_PORT="${4:-8080}"
    
    # Clear terminal and show Demasy Labs banner
    print_demasy_banner "APEX Installation Complete ✅"
    echo ""
    echo ""
    
    # APEX Details Section
    echo -e "${BOLD}${BLUE}🚀 APEX Details:${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}Application Builder:${NC}  http://localhost:${ORDS_PORT}/ords/f?p=4550:1"
    echo -e "  ${GREEN}SQL Developer Web:${NC}    http://localhost:${ORDS_PORT}/ords/sql-developer"
    echo -e "  ${GREEN}APEX Admin:${NC}           http://localhost:${ORDS_PORT}/ords/apex_admin"
    echo ""
    
    # Login Credentials Section
    echo -e "${BOLD}${BLUE}🔐 Login Credentials:${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}Workspace:${NC} ${BOLD}INTERNAL${NC}"
    echo -e "  ${GREEN}Username:${NC}  ${BOLD}${APEX_ADMIN_USERNAME}${NC}"
    echo -e "  ${GREEN}Password:${NC}  ${BOLD}${APEX_PASSWORD}${NC}"
    echo -e "  ${GREEN}Email:${NC}     ${BOLD}${APEX_EMAIL}${NC}"
    echo ""
    
    # Management Commands Section
    echo -e "${BOLD}${BLUE}📋 Management Commands:${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}Start ORDS:${NC}  ${BOLD}start-apex${NC}"
    echo -e "  ${GREEN}Stop ORDS:${NC}   ${BOLD}stop-apex${NC}"
    echo -e "  ${GREEN}View Logs:${NC}   ${BOLD}tail -f /tmp/ords.log${NC}"
    echo -e "  ${GREEN}APEX Logs:${NC}   ${BOLD}tail -f /tmp/apex_install.log${NC}"
    echo ""
    
    # Installed Components Section
    echo -e "${BOLD}${BLUE}📦 Installed Components:${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────────────${NC}"
    local apex_size=$(du -sh /opt/oracle/apex 2>/dev/null | cut -f1 || echo 'N/A')
    local ords_size=$(du -sh /opt/oracle/ords 2>/dev/null | cut -f1 || echo 'N/A')
    local images_size=$(du -sh /tmp/i 2>/dev/null | cut -f1 || echo 'N/A')
    local images_count=$(find /tmp/i -type f 2>/dev/null | wc -l)
    echo -e "  ${GREEN}APEX:${NC}   /opt/oracle/apex/ ${DIM}[${apex_size}]${NC}"
    echo -e "  ${GREEN}ORDS:${NC}   /opt/oracle/ords/ ${DIM}[${ords_size}]${NC}"
    echo -e "  ${GREEN}Images:${NC} /tmp/i/ ${DIM}[${images_size} - ${images_count} files]${NC}"
    echo -e "  ${GREEN}Config:${NC} /opt/oracle/ords/config/"
    echo ""
    
    # Troubleshooting Section
    echo -e "${BOLD}${BLUE}🔧 Troubleshooting:${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${BOLD}If APEX images not loading:${NC}"
    echo -e "    ${CYAN}1.${NC} Verify: ${DIM}ls -la /tmp/i | wc -l${NC} [should show ~855 files]"
    echo -e "    ${CYAN}2.${NC} Restart: ${BOLD}stop-apex && start-apex${NC}"
    echo -e "    ${CYAN}3.${NC} Check logs: ${DIM}tail -f /tmp/ords.log${NC}"
    echo ""
    echo -e "  ${BOLD}If connection errors:${NC}"
    echo -e "    ${CYAN}1.${NC} Check accounts:"
    echo -e "       ${DIM}SELECT username, account_status FROM dba_users${NC}"
    echo -e "       ${DIM}WHERE username LIKE 'APEX%' OR username LIKE 'ORDS%';${NC}"
    echo -e "    ${CYAN}2.${NC} Unlock: ${DIM}ALTER USER ORDS_PUBLIC_USER ACCOUNT UNLOCK;${NC}"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW} 💡 TIP:${NC} For complete documentation, tutorials, and troubleshooting:"
    echo -e "      ${BLUE}https://github.com/demasy/oracle-sandbox${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}
