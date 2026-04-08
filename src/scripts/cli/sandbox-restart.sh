# ─── sandbox restart ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox restart <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        log_step "Restarting APEX (ORDS)..."
        bash /usr/demasy/scripts/oracle/apex/stop.sh
        bash /usr/demasy/scripts/oracle/apex/start.sh
        ;;
    mcp)      log_warn "sandbox restart mcp    — not implemented yet" ;;
    system)   log_warn "sandbox restart system — not implemented yet" ;;
esac
