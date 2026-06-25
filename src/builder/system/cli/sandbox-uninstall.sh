# ─── sandbox uninstall ────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox uninstall <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Uses: sandbox-params.sh for dry-run support
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        _if_dry_run "Uninstalling APEX + ORDS" || {
            log_step "Uninstalling APEX + ORDS..."
            bash /usr/sandbox/app/oracle/apex/uninstall.sh
        }
        ;;
esac
