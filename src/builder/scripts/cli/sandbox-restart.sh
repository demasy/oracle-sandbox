# ─── sandbox restart ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox restart <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        log_step "Restarting APEX (ORDS)..."
        bash /usr/sandbox/app/oracle/apex/stop.sh
        bash /usr/sandbox/app/oracle/apex/start.sh
        ;;
    mcp)
        log_step "Restarting MCP server..."
        _mcp_pid=$(pgrep -f "sql.*-mcp" 2>/dev/null | head -1)
        if [[ -n "$_mcp_pid" ]]; then
            kill "$_mcp_pid" 2>/dev/null
            sleep 1
            if kill -0 "$_mcp_pid" 2>/dev/null; then
                kill -9 "$_mcp_pid" 2>/dev/null
            fi
            log_info "MCP server stopped (PID: $_mcp_pid)"
        fi
        log_step "Starting MCP server..."
        bash /usr/sandbox/app/oracle/mcp/start-mcp-with-saved-connection.sh
        ;;
esac
