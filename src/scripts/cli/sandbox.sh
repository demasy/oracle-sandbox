#!/bin/bash
# ============================================
# Sandbox CLI
# ============================================
# Main entrypoint for the Demasylabs Oracle Sandbox
# Usage: sandbox <action> <resource> [parameters]
#
# Actions:
#   download   Download Oracle components
#   install    Install Oracle components
#   uninstall  Uninstall Oracle components
#   start      Start a service
#   stop       Stop a service
#   run        Run / connect to a service
#
# Resources:
#   download / install / uninstall: oracle | client | sqlcl | sqlplus
#   start / stop:                   mcp | system
#   run:                            oracle | mcp | system
#
# Examples:
#   sandbox download oracle
#   sandbox install sqlcl
#   sandbox start mcp -d
#   sandbox start mcp --default
#   sandbox run mcp
# ============================================

source /usr/demasy/scripts/backbone/utils/colors.sh
source /usr/demasy/scripts/backbone/utils/logging.sh
source /usr/demasy/scripts/backbone/utils/banner.sh

# ─── Resource sets per action ─────────────────────────────────────────────────

resources_for() {
    case "$1" in
        download|install|uninstall) echo "oracle client sqlcl sqlplus" ;;
        start|stop)                 echo "mcp system" ;;
        run)                        echo "oracle mcp system" ;;
        *)                          echo "" ;;
    esac
}

# ─── Usage ───────────────────────────────────────────────────────────────────

print_usage() {
    echo ""
    echo -e "  ${CYAN}sandbox${NC} — Oracle Sandbox CLI"
    echo ""
    echo -e "  ${WHITE}Usage:${NC}   sandbox <action> <resource> [parameters]"
    echo ""
    echo -e "  ${YELLOW}Actions & Resources:${NC}"
    echo -e "    ${CYAN}download${NC}   oracle | client | sqlcl | sqlplus"
    echo -e "    ${CYAN}install${NC}    oracle | client | sqlcl | sqlplus"
    echo -e "    ${CYAN}uninstall${NC}  oracle | client | sqlcl | sqlplus"
    echo -e "    ${CYAN}start${NC}      mcp | system"
    echo -e "    ${CYAN}stop${NC}       mcp | system"
    echo -e "    ${CYAN}run${NC}        oracle | mcp | system"
    echo ""
    echo -e "  ${YELLOW}Examples:${NC}"
    echo -e "    sandbox download oracle"
    echo -e "    sandbox install sqlcl"
    echo -e "    sandbox start mcp -d"
    echo -e "    sandbox start mcp --default"
    echo -e "    sandbox run mcp"
    echo ""
}

# ─── Validation ──────────────────────────────────────────────────────────────

VALID_ACTIONS="download install uninstall start stop run"

validate_action() {
    local action="$1"
    for a in $VALID_ACTIONS; do
        [[ "$a" == "$action" ]] && return 0
    done
    echo ""
    log_error "Unknown action: '${action}'"
    echo -e "  ${YELLOW}Available actions:${NC} ${CYAN}${VALID_ACTIONS}${NC}"
    print_usage
    exit 1
}

validate_resource() {
    local action="$1" resource="$2"
    local valid
    valid=$(resources_for "$action")
    for r in $valid; do
        [[ "$r" == "$resource" ]] && return 0
    done
    echo ""
    log_error "Invalid resource '${resource}' for action '${action}'"
    echo -e "  ${YELLOW}Valid resources for ${CYAN}${action}${YELLOW}:${NC} ${CYAN}${valid}${NC}"
    echo ""
    exit 1
}

# ─── Entry point ─────────────────────────────────────────────────────────────

clear
print_demasy_banner "Sandbox CLI"

if [[ $# -lt 1 ]]; then
    print_usage
    exit 0
fi

ACTION="$1"
RESOURCE="${2:-}"
shift 2 2>/dev/null || true
PARAMS="$*"

validate_action "$ACTION"

if [[ -z "$RESOURCE" ]]; then
    echo ""
    log_error "Missing resource for action '${ACTION}'"
    valid=$(resources_for "$ACTION")
    echo -e "  ${YELLOW}Available resources:${NC} ${CYAN}${valid}${NC}"
    echo ""
    exit 1
fi

validate_resource "$ACTION" "$RESOURCE"

# ─── Dispatch ────────────────────────────────────────────────────────────────

echo ""
log_step "sandbox ${ACTION} ${RESOURCE}${PARAMS:+ ${PARAMS}}"
echo ""

case "$ACTION" in
    download)
        case "$RESOURCE" in
            oracle)   log_warn "sandbox download oracle  — not implemented yet" ;;
            client)   log_warn "sandbox download client  — not implemented yet" ;;
            sqlcl)    log_warn "sandbox download sqlcl   — not implemented yet" ;;
            sqlplus)  log_warn "sandbox download sqlplus — not implemented yet" ;;
        esac
        ;;
    install)
        case "$RESOURCE" in
            oracle)   log_warn "sandbox install oracle  — not implemented yet" ;;
            client)   log_warn "sandbox install client  — not implemented yet" ;;
            sqlcl)    log_warn "sandbox install sqlcl   — not implemented yet" ;;
            sqlplus)  log_warn "sandbox install sqlplus — not implemented yet" ;;
        esac
        ;;
    uninstall)
        case "$RESOURCE" in
            oracle)   log_warn "sandbox uninstall oracle  — not implemented yet" ;;
            client)   log_warn "sandbox uninstall client  — not implemented yet" ;;
            sqlcl)    log_warn "sandbox uninstall sqlcl   — not implemented yet" ;;
            sqlplus)  log_warn "sandbox uninstall sqlplus — not implemented yet" ;;
        esac
        ;;
    start)
        case "$RESOURCE" in
            mcp)
                if [[ -z "$PARAMS" ]]; then
                    echo ""
                    log_error "sandbox start mcp requires a parameter"
                    echo -e "  ${YELLOW}Parameters:${NC}"
                    echo -e "    ${CYAN}-d${NC}, ${CYAN}--default${NC}   Start MCP using the default saved connection (demasylabs-ai-conn)"
                    echo ""
                    exit 1
                fi
                case "$PARAMS" in
                    -d|--default)
                        log_step "Starting MCP server with default saved connection..."
                        bash /usr/demasy/scripts/oracle/mcp/start-mcp-with-saved-connection.sh
                        ;;
                    *)
                        echo ""
                        log_error "Unknown parameter '${PARAMS}' for sandbox start mcp"
                        echo -e "  ${YELLOW}Parameters:${NC}"
                        echo -e "    ${CYAN}-d${NC}, ${CYAN}--default${NC}   Start MCP using the default saved connection (demasylabs-ai-conn)"
                        echo ""
                        exit 1
                        ;;
                esac
                ;;
            system)   log_warn "sandbox start system — not implemented yet" ;;
        esac
        ;;
    stop)
        case "$RESOURCE" in
            mcp)      log_warn "sandbox stop mcp    — not implemented yet" ;;
            system)   log_warn "sandbox stop system — not implemented yet" ;;
        esac
        ;;
    run)
        case "$RESOURCE" in
            oracle)   log_warn "sandbox run oracle — not implemented yet" ;;
            mcp)      log_warn "sandbox run mcp    — not implemented yet" ;;
            system)   log_warn "sandbox run system — not implemented yet" ;;
        esac
        ;;
esac

echo ""
