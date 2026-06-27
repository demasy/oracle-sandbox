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

        MCP_LOG="${SANDBOX_LOG_PATHS[mcp]:-/tmp/sqlcl_mcp.log}"
        MCP_STATE="/tmp/sandbox_mcp.state"

        # Reject if already running
        if pgrep -f "SqlCli.*-mcp" >/dev/null 2>&1; then
            log_info "MCP server is already running"
            exit 0
        fi

        [[ -z "$MCP_CONN" ]] && MCP_CONN="sandbox-ai-conn"
        log_step "Starting MCP server with connection: ${MCP_CONN}..."

        nohup bash /usr/sandbox/app/oracle/mcp/start-mcp-with-saved-connection.sh "$MCP_CONN" \
            >>"$MCP_LOG" 2>&1 &
        _WRAPPER_PID=$!
        sleep 2

        # The wrapper uses `exec sql -mcp` — after exec, the Java process takes over.
        # Find the actual Java MCP PID.
        MCP_PID=$(pgrep -f "SqlCli.*-mcp" 2>/dev/null | head -1)
        if [[ -n "$MCP_PID" ]]; then
            printf '%s\n%s\n' "$MCP_PID" "$MCP_CONN" > "$MCP_STATE"
            log_success "MCP server started (PID ${MCP_PID}, conn: ${MCP_CONN}) — logs: ${MCP_LOG}"
        else
            log_error "MCP server failed to start — check: ${MCP_LOG}"
            exit ${EXIT_SERVICE:-4}
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
