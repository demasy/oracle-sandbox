# ─── sandbox stop ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox stop <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        log_step "Stopping APEX (ORDS)..."
        bash /usr/sandbox/app/oracle/apex/stop.sh
        ;;
    mcp)
        log_step "Stopping MCP server..."
        _mcp_pid=$(pgrep -f "sql.*-mcp" 2>/dev/null | head -1)
        if [[ -z "$_mcp_pid" ]]; then
            log_info "MCP server is not running"
        else
            kill "$_mcp_pid" 2>/dev/null
            sleep 1
            if kill -0 "$_mcp_pid" 2>/dev/null; then
                kill -9 "$_mcp_pid" 2>/dev/null
            fi
            log_success "MCP server stopped (PID: $_mcp_pid)"
        fi
        ;;
esac
