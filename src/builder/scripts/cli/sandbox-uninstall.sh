# ─── sandbox uninstall ────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox uninstall <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    oracle)   log_warn "sandbox uninstall oracle  — not implemented yet" ;;
    client)   log_warn "sandbox uninstall client  — not implemented yet" ;;
    sqlcl)    log_warn "sandbox uninstall sqlcl   — not implemented yet" ;;
    sqlplus)  log_warn "sandbox uninstall sqlplus — not implemented yet" ;;
    apex)
        log_step "Uninstalling APEX + ORDS..."
        bash /usr/sandbox/app/oracle/apex/uninstall.sh
        ;;
esac
