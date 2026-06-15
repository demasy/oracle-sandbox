# ─── sandbox install ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox install <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        log_step "Installing APEX + ORDS..."
        bash /usr/sandbox/app/oracle/apex/install.sh
        ;;
esac
