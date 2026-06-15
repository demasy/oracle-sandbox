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
#   status     Show running status of a service
#   start      Start a service
#   stop       Stop a service
#   restart    Restart a service
#   install    Install Oracle components
#   uninstall  Uninstall Oracle components
#   download   Download Oracle components
#
# Resources:
#   run:                            sqlcl | mcp | healthcheck
#   status:                         database | apex | mcp
#   conn:                           list | add | delete | test
#   logs:                           apex | install | ords | startup | mcp | all
#   start / stop / restart:         apex | mcp
#   install:                        apex
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
        install)                    echo "apex" ;;
        uninstall)                  echo "apex" ;;
        start)                      echo "apex mcp" ;;
        stop|restart)               echo "apex mcp" ;;
        run)                        echo "sqlcl mcp healthcheck" ;;
        status)                     echo "database apex mcp" ;;
        conn)                       echo "list add delete test" ;;
        logs)                       echo "apex install ords startup mcp all" ;;
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
    echo -e "    ${CYAN}run${NC}        sqlcl | mcp | healthcheck"
    echo -e "    ${CYAN}status${NC}     database | apex | mcp"
    echo -e "    ${CYAN}conn${NC}       list | add | delete | test"
    echo -e "    ${CYAN}logs${NC}       apex | install | ords | startup | mcp | all"
    echo -e "    ${CYAN}start${NC}      apex | mcp"
    echo -e "    ${CYAN}stop${NC}       apex | mcp"
    echo -e "    ${CYAN}restart${NC}    apex | mcp"
    echo -e "    ${CYAN}install${NC}    apex"
    echo -e "    ${CYAN}uninstall${NC}  apex"
    echo -e "    ${CYAN}download${NC}   apex | ords"
    echo ""
    echo -e "  ${YELLOW}SQLcl parameters:${NC}"
    echo -e "    ${CYAN}-u${NC}, ${CYAN}--user${NC} sys | system | sandbox | sandbox_ai | demasy | demasy_ai"
    echo -e "    ${CYAN}-p${NC}, ${CYAN}--pass${NC} <password>   (default: Default Password)"
    echo -e "    ${CYAN}--pdb${NC} <PDB name>      (override default PDB for user)"
    echo ""
    echo -e "  ${YELLOW}Download parameters:${NC}"
    echo -e "    ${CYAN}apex -s${NC}, ${CYAN}--standalone${NC}   Download APEX only"
    echo -e "    ${CYAN}apex -a${NC}, ${CYAN}--all${NC}         Download APEX + ORDS"
    echo ""
    echo -e "  ${YELLOW}Global flags:${NC}"
    echo -e "    ${CYAN}--dry-run${NC}   Preview what would run without executing"
    echo -e "    ${CYAN}--quiet${NC}     Suppress info/progress output (errors and success only)"
    echo -e "    ${CYAN}--verbose${NC}   Show full command output"
    echo ""
    echo -e "  ${YELLOW}Examples:${NC}"
    echo -e "    sandbox run healthcheck"
    echo -e "    sandbox run sqlcl -u system"
    echo -e "    sandbox start mcp --conn sandbox-mcp-conn"
    echo -e "    sandbox install apex --dry-run"
    echo -e "    sandbox conn add --name my-conn --user demasy --pdb DEMASYLABS_PDB --quiet"
    echo ""
}

# ─── Exit codes ──────────────────────────────────────────────────────────────

EXIT_USAGE=1      # bad args, unknown action/resource, missing params
EXIT_DB=2         # ORA-* errors, connection failures
EXIT_INSTALL=3    # install/uninstall failures
EXIT_SERVICE=4    # service not running, start/stop/restart failures

# ─── "Did you mean?" ─────────────────────────────────────────────────────────

_did_you_mean() {
    local input="$1" candidates="$2"
    local best="" best_score=99
    for candidate in $candidates; do
        # Accept if input is a prefix of candidate
        if [[ "$candidate" == "${input}"* ]]; then
            echo "$candidate"; return
        fi
        # Accept if off by one char (deletion or substitution)
        local score=0
        local len_i=${#input} len_c=${#candidate}
        local diff=$(( len_i - len_c ))
        [[ $diff -lt 0 ]] && diff=$(( -diff ))
        if (( diff <= 1 )); then
            local i j mismatches=0
            for (( i=0, j=0; i<len_i && j<len_c; )); do
                if [[ "${input:$i:1}" != "${candidate:$j:1}" ]]; then
                    (( mismatches++ ))
                    (( len_i > len_c )) && (( i++ )) || (( len_c > len_i )) && (( j++ )) || { (( i++ )); (( j++ )); }
                else
                    (( i++ )); (( j++ ))
                fi
                (( mismatches > 2 )) && break
            done
            score=$(( mismatches + diff ))
        else
            score=99
        fi
        if (( score < best_score && score <= 2 )); then
            best="$candidate"; best_score=$score
        fi
    done
    [[ -n "$best" ]] && echo "$best"
}

# ─── Validation ──────────────────────────────────────────────────────────────

VALID_ACTIONS="download install uninstall start stop restart run status conn logs"

validate_action() {
    local action="$1"
    for a in $VALID_ACTIONS; do
        [[ "$a" == "$action" ]] && return 0
    done
    echo ""
    log_error "Unknown action: '${action}'"
    local suggestion
    suggestion=$(_did_you_mean "$action" "$VALID_ACTIONS")
    [[ -n "$suggestion" ]] && echo -e "  ${YELLOW}Did you mean:${NC} ${CYAN}${suggestion}${NC}?"
    echo -e "  ${YELLOW}Available actions:${NC} ${CYAN}${VALID_ACTIONS}${NC}"
    echo ""
    exit $EXIT_USAGE
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
    local suggestion
    suggestion=$(_did_you_mean "$resource" "$valid")
    [[ -n "$suggestion" ]] && echo -e "  ${YELLOW}Did you mean:${NC} ${CYAN}${suggestion}${NC}?"
    echo -e "  ${YELLOW}Valid resources for ${CYAN}${action}${YELLOW}:${NC} ${CYAN}${valid}${NC}"
    echo ""
    exit $EXIT_USAGE
}

# ─── Entry point ─────────────────────────────────────────────────────────────

# ─── Global flags (parse before banner so --quiet suppresses it) ──────────────
export SANDBOX_DRY_RUN=0
export SANDBOX_QUIET=0
export SANDBOX_VERBOSE=0

_filtered_args=()
for _arg in "$@"; do
    case "$_arg" in
        --dry-run)  SANDBOX_DRY_RUN=1 ;;
        --quiet|-q) SANDBOX_QUIET=1 ;;
        --verbose)  SANDBOX_VERBOSE=1 ;;
        *)          _filtered_args+=("$_arg") ;;
    esac
done
set -- "${_filtered_args[@]}"
unset _filtered_args _arg

clear
[[ "${SANDBOX_QUIET:-0}" != "1" ]] && print_demasy_banner "Sandbox CLI"

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
[[ "$SANDBOX_DRY_RUN" == "1" ]] && log_info "[dry-run] No changes will be made."
echo ""

source /usr/sandbox/app/cli/sandbox-${ACTION}.sh

echo ""
