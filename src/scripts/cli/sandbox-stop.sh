# ─── sandbox stop ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox stop <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        log_step "Stopping APEX (ORDS)..."
        bash /usr/demasy/scripts/oracle/apex/stop.sh
        ;;
    mcp)      log_warn "sandbox stop mcp    — not implemented yet" ;;
    system)   log_warn "sandbox stop system — not implemented yet" ;;
esac
