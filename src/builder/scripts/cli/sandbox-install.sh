# ─── sandbox install ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox install <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Dependencies: sandbox-params.sh
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        _if_dry_run "Would run: bash /usr/sandbox/app/oracle/apex/install.sh" && exit 0
        log_step "Installing APEX + ORDS..."
        bash /usr/sandbox/app/oracle/apex/install.sh
        ;;
esac
