#!/bin/bash
# ============================================
# Display Available Commands
# ============================================
# Shows list of available CLI commands
# Usage: Source this file or call display_commands
# ============================================
source /usr/demasy/scripts/backbone/utils/colors.sh
source /usr/demasy/scripts/backbone/utils/logging.sh

display_commands() {
    # log_info "Available commands:"
   echo -e " Oracle Sandbox Available commands:"
    echo -e "  ${CYAN}sqlcl${NC}              - Connect to Oracle database with SQLcl"
    echo -e "  ${CYAN}sqlplus${NC}            - Connect to Oracle database with SQL*Plus"
    echo -e "  ${CYAN}install-client${NC}     - Install Oracle Instant Client"
    echo -e "  ${CYAN}install-sqlcl${NC}      - Install SQLcl"
    echo -e "  ${CYAN}download-apex${NC}      - Download APEX and ORDS software"
    echo -e "  ${CYAN}install-apex${NC}       - Install APEX into database"
    echo -e "  ${CYAN}start-apex${NC}         - Start ORDS server"
    echo -e "  ${CYAN}stop-apex${NC}          - Stop ORDS server"
    echo -e "  ${CYAN}healthcheck${NC}        - Run system health check"
    echo ""
    echo ""
}
