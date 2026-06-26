# ─── sandbox download ─────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox download <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        log_step "Downloading APEX + ORDS..."
        bash /usr/sandbox/app/download/download-apex.sh
        ;;
    *)
        log_error "Unknown resource '${RESOURCE}' for sandbox download"
        echo -e "  ${YELLOW}Valid resources:${NC} apex"
        exit 1
        ;;
esac
