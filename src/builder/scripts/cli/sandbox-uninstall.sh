# ─── sandbox uninstall ────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox uninstall <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        log_step "Uninstalling APEX + ORDS..."
        bash /usr/sandbox/app/oracle/apex/uninstall.sh
        ;;
esac
