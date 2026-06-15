# ─── sandbox install ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox install <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        if [[ "${SANDBOX_DRY_RUN:-0}" == "1" ]]; then
            log_info "[dry-run] Would run: bash /usr/sandbox/app/oracle/apex/install.sh"
        else
            log_step "Installing APEX + ORDS..."
            bash /usr/sandbox/app/oracle/apex/install.sh
        fi
        ;;
esac
