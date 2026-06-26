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
source /usr/sandbox/app/system/cli/sandbox-config.sh
source /usr/sandbox/app/system/cli/sandbox-params.sh
source /usr/sandbox/app/system/cli/sandbox-status-helpers.sh
source /usr/sandbox/app/system/cli/sandbox-menu.sh
source /usr/sandbox/app/system/cli/sandbox-format.sh

# ─── Resource lookup helper ───────────────────────────────────────────────────
# Wraps centralized SANDBOX_RESOURCES map (from sandbox-config.sh)

resources_for() {
    local action="$1"
    echo "${SANDBOX_RESOURCES[$action]:-}"
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
    echo -e "    ${CYAN}run${NC}        sqlcl | mcp | healthcheck | script"
    echo -e "    ${CYAN}status${NC}     database | apex | mcp | all"
    echo -e "    ${CYAN}conn${NC}       list | add | delete | rename | test"
    echo -e "    ${CYAN}logs${NC}       apex | install | ords | startup | mcp | all"
    echo -e "    ${CYAN}start${NC}      apex | mcp"
    echo -e "    ${CYAN}stop${NC}       apex | mcp"
    echo -e "    ${CYAN}restart${NC}    apex | mcp"
    echo -e "    ${CYAN}install${NC}    apex"
    echo -e "    ${CYAN}uninstall${NC}  apex"
    echo -e "    ${CYAN}download${NC}   apex | ords"
    echo -e "    ${CYAN}export${NC}     config | connections | all"
    echo -e "    ${CYAN}import${NC}     config | connections | all"
    echo -e "    ${CYAN}batch${NC}      apply-connections | apply-commands | execute"
    echo -e "    ${CYAN}monitor${NC}    system | database | apex | all"
    echo -e "    ${CYAN}audit${NC}      list | show | search | export | stats | rollback"
    echo -e "    ${CYAN}template${NC}   save | load | list | delete | export | import"
    echo ""
    echo -e "  ${YELLOW}Examples:${NC}"
    echo -e "    sandbox run sqlcl -u system"
    echo -e "    sandbox status apex"
    echo -e "    sandbox monitor --export json"
    echo -e "    sandbox audit list"
    echo -e "    sandbox template save --name production"
    echo -e "    sandbox batch execute --file commands.txt"
    echo -e "    sandbox export config"
    echo -e "    sandbox import connections --file conns.json"
    echo -e "    sandbox conn list"
    echo -e "    sandbox install apex"
    echo ""
    echo -e "  ${WHITE}Tip:${NC} Use ${CYAN}sandbox <action> -h${NC} or ${CYAN}sandbox <action> <resource> -h${NC} for details."
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

VALID_ACTIONS="download install uninstall start stop restart run status conn logs export help monitor audit template import batch"

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
    echo -e "  ${YELLOW}Tip:${NC} Use ${CYAN}sandbox help search <keyword>${NC} to find commands"
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
    echo -e "  ${YELLOW}Tip:${NC} Use ${CYAN}sandbox help search ${resource}${NC} to learn more"
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
_first_real_arg="${_filtered_args[0]:-}"
set -- "${_filtered_args[@]}"
unset _filtered_args _arg

if [[ $# -lt 1 ]]; then
    clear
    _suppress_banner=0
    [[ "${SANDBOX_QUIET:-0}" == "1" ]] && _suppress_banner=1
    [[ "$_suppress_banner" == "0" ]] && print_demasy_banner "Sandbox CLI"
    unset _suppress_banner
    print_usage
    exit 0
fi

ACTION="$1"
RESOURCE="${2:-}"
# For optional resource actions, if second arg is a flag (starts with --), treat as param
if [[ -n "$RESOURCE" && "$RESOURCE" == --* ]]; then
    shift 1
    PARAMS="$*"
    RESOURCE=""
else
    shift 2 2>/dev/null || true
    PARAMS="$*"
fi

# Auto-suppress banner for machine-readable formats
if [[ "$PARAMS" == *"--format json"* || "$PARAMS" == *"--format csv"* ]]; then
    SANDBOX_QUIET=1
fi

# ─── Print banner (defer clear for non-help actions to preserve banner) ──────
_suppress_banner=0
[[ "${SANDBOX_QUIET:-0}" == "1" ]] && _suppress_banner=1
if [[ "$ACTION" != "help" ]]; then
    clear
fi
[[ "$_suppress_banner" == "0" ]] && print_demasy_banner "Sandbox CLI"
unset _suppress_banner

# ─── Help intercept ──────────────────────────────────────────────────────────
if [[ "$ACTION" == "-h" || "$ACTION" == "--help" ]]; then
    print_usage
    exit 0
fi
if [[ "$RESOURCE" == "-h" || "$RESOURCE" == "--help" ]]; then
    source /usr/sandbox/app/system/cli/sandbox-help.sh
    exit 0
fi
if [[ "$PARAMS" == "-h" || "$PARAMS" == "--help" ]]; then
    source /usr/sandbox/app/system/cli/sandbox-resource-help.sh
    exit 0
fi

# ─── Special handling for help action (Phase 2) ────────────────────────────────
if [[ "$ACTION" == "help" ]]; then
    source /usr/sandbox/app/system/cli/sandbox-help-search.sh "$RESOURCE" "$PARAMS"
    exit 0
fi

validate_action "$ACTION"

# Actions that allow omitting the resource (run all resources as dashboard)
# Now loaded from SANDBOX_OPTIONAL_RESOURCE_ACTIONS in sandbox-config.sh
_optional_resource_actions="$SANDBOX_OPTIONAL_RESOURCE_ACTIONS"

if [[ -z "$RESOURCE" ]]; then
    _is_optional=false
    for _a in $_optional_resource_actions; do
        [[ "$_a" == "$ACTION" ]] && _is_optional=true && break
    done
    if [[ "$_is_optional" == false ]]; then
        echo ""
        log_error "Missing resource for action '${ACTION}'"
        valid=$(resources_for "$ACTION")
        echo -e "  ${YELLOW}Available resources:${NC} ${CYAN}${valid}${NC}"
        echo -e "  ${YELLOW}Tip:${NC} Use ${CYAN}sandbox help search ${ACTION}${NC} to learn more"
        echo ""
        exit $EXIT_USAGE
    fi
    unset _is_optional _a _optional_resource_actions
else
    unset _optional_resource_actions
    validate_resource "$ACTION" "$RESOURCE"
fi

# ─── Dispatch ───────────────────────────────────────────────────────────

echo ""
log_step "sandbox ${ACTION} ${RESOURCE}${PARAMS:+ ${PARAMS}}"
[[ "$SANDBOX_DRY_RUN" == "1" ]] && log_info "[dry-run] No changes will be made."
echo ""

source /usr/sandbox/app/system/cli/sandbox-${ACTION}.sh

echo ""
