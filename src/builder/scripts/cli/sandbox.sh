#!/bin/bash
# ============================================
# Sandbox CLI
# ============================================
# Main entrypoint for the Demasylabs Oracle Sandbox
# Usage: sandbox <action> <resource> [parameters]
#        sandbox -h | --help
#        sandbox <action> -h | --help
#        sandbox <action> <resource> -h | --help
#
# Actions:
#   run        Run / connect to a service
#   start      Start a service
#   stop       Stop a service
#   restart    Restart a service
#   install    Install Oracle components
#   uninstall  Uninstall Oracle components
#   download   Download Oracle components
#
# Resources:
#   run:                            oracle | mcp | sqlcl | healthcheck
#   start / stop / restart:         apex | mcp
#   install:                        oracle | client | sqlcl | sqlplus | apex
#   uninstall:                      apex
#   download:                       apex | ords
#
# Examples:
#   sandbox run healthcheck
#   sandbox run sqlcl -u system
#   sandbox start mcp --conn sandbox-mcp-conn
# ============================================

source /usr/sandbox/app/system/utils/colors.sh
source /usr/sandbox/app/system/utils/logging.sh
source /usr/sandbox/app/system/utils/banner.sh

# ─── Resource sets per action ─────────────────────────────────────────────────

resources_for() {
    case "$1" in
        download)                   echo "apex ords" ;;
        install)                    echo "oracle client sqlcl sqlplus apex" ;;
        uninstall)                  echo "apex" ;;
        start)                      echo "apex mcp" ;;
        stop|restart)               echo "apex mcp" ;;
        run)                        echo "oracle mcp sqlcl healthcheck" ;;
        *)                          echo "" ;;
    esac
}

# ─── Usage ───────────────────────────────────────────────────────────────────

print_usage() {
    echo ""
    echo -e "  ${CYAN}sandbox${NC} — Oracle Sandbox CLI"
    echo ""
    echo -e "  ${WHITE}Usage:${NC}   sandbox <action> <resource> [parameters]"
    echo -e "           sandbox -h | --help"
    echo -e "           sandbox <action> -h | --help"
    echo -e "           sandbox <action> <resource> -h | --help"
    echo ""
    echo -e "  ${YELLOW}Actions & Resources:${NC}"
    echo -e "    ${CYAN}run${NC}        oracle | mcp | sqlcl | healthcheck"
    echo -e "    ${CYAN}start${NC}      apex | mcp"
    echo -e "    ${CYAN}stop${NC}       apex | mcp"
    echo -e "    ${CYAN}restart${NC}    apex | mcp"
    echo -e "    ${CYAN}install${NC}    oracle | client | sqlcl | sqlplus | apex"
    echo -e "    ${CYAN}uninstall${NC}  apex"
    echo -e "    ${CYAN}download${NC}   apex | ords"
    echo ""
    echo -e "  ${YELLOW}SQLcl parameters:${NC}"
    echo -e "    ${CYAN}-u${NC}, ${CYAN}--user${NC} sys | system | demasy | sandbox | demasylabs | demasy_ai"
    echo -e "    ${CYAN}-p${NC}, ${CYAN}--pass${NC} <password>   (default: \$DEMASYLABS_DB_PASSWORD)"
    echo ""
    echo -e "  ${YELLOW}Download parameters:${NC}"
    echo -e "    ${CYAN}apex -s${NC}, ${CYAN}--standalone${NC}   Download APEX only"
    echo -e "    ${CYAN}apex -a${NC}, ${CYAN}--all${NC}         Download APEX + ORDS"
    echo ""
    echo -e "  ${YELLOW}Examples:${NC}"
    echo -e "    sandbox run healthcheck"
    echo -e "    sandbox run sqlcl -u system"
    echo -e "    sandbox start mcp --conn sandbox-mcp-conn"
    echo ""
}

# ─── Validation ──────────────────────────────────────────────────────────────

VALID_ACTIONS="download install uninstall start stop restart run"

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

# ─── Help intercept ──────────────────────────────────────────────────────────
if [[ "$ACTION" == "-h" || "$ACTION" == "--help" ]]; then
    print_usage
    exit 0
fi
if [[ "$RESOURCE" == "-h" || "$RESOURCE" == "--help" ]]; then
    source /usr/sandbox/app/cli/sandbox-help.sh
    exit 0
fi
if [[ "$PARAMS" == "-h" || "$PARAMS" == "--help" ]]; then
    source /usr/sandbox/app/cli/sandbox-resource-help.sh
    exit 0
fi

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

# ─── Dispatch ───────────────────────────────────────────────────────────

echo ""
log_step "sandbox ${ACTION} ${RESOURCE}${PARAMS:+ ${PARAMS}}"
echo ""

source /usr/sandbox/app/cli/sandbox-${ACTION}.sh

echo ""
