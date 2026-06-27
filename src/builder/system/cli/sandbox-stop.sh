# ─── sandbox stop ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox stop <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Dependencies: sandbox-params.sh
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        _if_dry_run "Would run: bash /usr/sandbox/app/oracle/apex/stop.sh" && exit 0
        log_step "Stopping APEX (ORDS)..."
        bash /usr/sandbox/app/oracle/apex/stop.sh
        ;;
    mcp)
        _if_dry_run "Would stop MCP server" && exit 0
        log_step "Stopping MCP server..."
        MCP_STATE="/tmp/sandbox_mcp.state"
        _mcp_pids=$(pgrep -f "SqlCli.*-mcp" 2>/dev/null || true)
        if [[ -z "$_mcp_pids" ]]; then
            log_info "MCP server is not running"
            rm -f "$MCP_STATE"
        else
            for _pid in $_mcp_pids; do
                kill "$_pid" 2>/dev/null || true
            done
            sleep 1
            for _pid in $_mcp_pids; do
                kill -0 "$_pid" 2>/dev/null && kill -9 "$_pid" 2>/dev/null || true
            done
            rm -f "$MCP_STATE"
            log_success "MCP server stopped (PIDs: $(echo $_mcp_pids | tr '\n' ' '))"
        fi
        ;;
esac
