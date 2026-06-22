# ─── sandbox logs ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox logs <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Dependencies: sandbox-params.sh
# ─────────────────────────────────────────────────────────────────────────────

# ── Log file registry ─────────────────────────────────────────────────────────

LOGS_APEX=(
    "/tmp/apex_install.log"
    "/tmp/apex_rest_config.log"
)
LOGS_ORDS=(
    "/tmp/ords.log"
)
LOGS_INSTALL=(
    "/tmp/apex_install.log"
    "/tmp/apex_rest_config.log"
    "/tmp/ords_install.log"
)
LOGS_STARTUP=(
    "/tmp/auto-user-setup.log"
)

# ── Helpers ───────────────────────────────────────────────────────────────────

_logs_print_file() {
    local file="$1" lines="$2" follow="$3"
    if [[ ! -f "$file" ]]; then
        echo -e "  ${YELLOW}(not found)${NC}  $file"
        return
    fi
    echo -e "  ${CYAN}▶ ${file}${NC}"
    echo "  $(printf '─%.0s' {1..70})"
    if [[ "$follow" == "true" ]]; then
        tail -f "$file"
    else
        tail -n "$lines" "$file" | sed 's/^/  /'
    fi
    echo ""
}

_logs_parse_params() {
    LOGS_LINES=50
    LOGS_FOLLOW=false
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --follow|-f)
                LOGS_FOLLOW=true
                shift ;;
            --lines|-n)
                _parse_flag_with_value "$1" "${2:-}" LOGS_LINES || exit 1
                shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox logs"
                _show_param_help "-f|--follow" "" "Stream log output (like tail -f)"
                _show_param_help "-n|--lines" "<N>" "Number of lines to show (default: 50)"
                exit 1 ;;
        esac
    done
}

# ── Resources ─────────────────────────────────────────────────────────────────

_logs_do_apex() {
    log_step "APEX logs"
    echo ""
    for f in "${LOGS_APEX[@]}"; do
        _logs_print_file "$f" "$LOGS_LINES" "$LOGS_FOLLOW"
    done
}

_logs_do_install() {
    log_step "Install logs (APEX + ORDS)"
    echo ""
    for f in "${LOGS_INSTALL[@]}"; do
        _logs_print_file "$f" "$LOGS_LINES" "$LOGS_FOLLOW"
    done
}

_logs_do_ords() {
    log_step "ORDS runtime log"
    echo ""
    for f in "${LOGS_ORDS[@]}"; do
        _logs_print_file "$f" "$LOGS_LINES" "$LOGS_FOLLOW"
    done
}

_logs_do_startup() {
    log_step "Startup / user-setup log"
    echo ""
    for f in "${LOGS_STARTUP[@]}"; do
        _logs_print_file "$f" "$LOGS_LINES" "$LOGS_FOLLOW"
    done
}

_logs_do_mcp() {
    log_step "MCP log"
    echo ""
    log_info "MCP server does not write a log file."
    echo -e "  ${YELLOW}Tip:${NC} Run ${CYAN}sandbox run mcp${NC} in the foreground to see output."
    echo ""
}

_logs_do_all() {
    log_step "All sandbox logs"
    echo ""
    if [[ "$LOGS_FOLLOW" == "true" ]]; then
        # Multiplex all log files into one stream with file labels
        local _all_files=()
        for f in "${LOGS_STARTUP[@]}" "${LOGS_INSTALL[@]}" "${LOGS_ORDS[@]}"; do
            [[ -f "$f" ]] && _all_files+=("$f")
        done
        if [[ ${#_all_files[@]} -eq 0 ]]; then
            log_info "No log files found."
            return
        fi
        tail -f "${_all_files[@]}" | awk '
            /^==> .+ <==$/ { sub(/^==> /,""); sub(/ <==$/, ""); file=$0; next }
            { print "  \033[36m[" file "]\033[0m " $0 }
        '
    else
        for f in "${LOGS_STARTUP[@]}" "${LOGS_INSTALL[@]}" "${LOGS_ORDS[@]}"; do
            _logs_print_file "$f" "$LOGS_LINES" "false"
        done
    fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

_logs_parse_params

case "$RESOURCE" in
    apex)     _logs_do_apex ;;
    install)  _logs_do_install ;;
    ords)     _logs_do_ords ;;
    startup)  _logs_do_startup ;;
    mcp)      _logs_do_mcp ;;
    all)      _logs_do_all ;;
esac
