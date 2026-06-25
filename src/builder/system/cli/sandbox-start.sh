# ─── sandbox start ────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox start <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Uses: sandbox-params.sh for parameter parsing helpers
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    mcp)
        MCP_DEFAULT=false MCP_CONN=""
        set -- $PARAMS
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -d|--default)
                    MCP_DEFAULT=true
                    shift
                    ;;
                -c|--conn)
                    _parse_flag_with_value "$1" "${2:-}" MCP_CONN || exit ${EXIT_USAGE:-1}
                    shift 2
                    ;;
                *)
                    echo ""
                    log_error "Unknown parameter '${1}' for sandbox start mcp"
                    _show_param_help "-d" "--default" "Start with default connection"
                    _show_param_help "-c" "--conn <name>" "Start with specific connection"
                    echo ""
                    exit ${EXIT_USAGE:-1}
                    ;;
            esac
        done

        if ! $MCP_DEFAULT && [[ -z "$MCP_CONN" ]]; then
            echo ""
            log_error "sandbox start mcp requires: --default or --conn <name>"
            _show_param_help "-d" "--default" "Start MCP with default connection (demasylabs-ai-conn)"
            _show_param_help "-c" "--conn <name>" "Start MCP with specified connection"
            echo ""
            exit ${EXIT_USAGE:-1}
        fi

        if $MCP_DEFAULT; then
            log_step "Starting MCP server with default saved connection..."
            bash /usr/sandbox/app/oracle/mcp/start-mcp-with-saved-connection.sh
        elif [[ -n "$MCP_CONN" ]]; then
            log_step "Starting MCP server with saved connection: ${MCP_CONN}..."
            bash /usr/sandbox/app/oracle/mcp/start-mcp-with-saved-connection.sh "$MCP_CONN"
        fi
        ;;
    apex)
        log_step "Starting APEX (ORDS)..."
        bash /usr/sandbox/app/oracle/apex/start.sh
        ;;
    system)   
        log_warn "sandbox start system — not implemented yet"
        ;;
esac
