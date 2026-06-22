# ─── sandbox download ─────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox download <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Dependencies: sandbox-params.sh
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        APEX_MODE=""
        set -- $PARAMS
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -s|--standalone)
                    APEX_MODE="standalone"
                    shift ;;
                -a|--all)
                    APEX_MODE="full"
                    shift ;;
                *)
                    log_error "Unknown parameter '${1}' for sandbox download apex"
                    _show_param_help "-s|--standalone" "" "Download APEX only"
                    _show_param_help "-a|--all" "" "Download APEX + ORDS"
                    exit 1 ;;
            esac
        done

        if [[ -z "$APEX_MODE" ]]; then
            log_error "sandbox download apex requires a parameter"
            _show_param_help "-s|--standalone" "" "Download APEX only"
            _show_param_help "-a|--all" "" "Download APEX + ORDS"
            exit 1
        fi

        case "$APEX_MODE" in
            standalone)
                log_step "Downloading APEX (standalone)..."
                bash /usr/sandbox/app/system/download/download-apex-standalone.sh
                ;;
            full)
                log_step "Downloading APEX + ORDS..."
                bash /usr/sandbox/app/system/download/download-apex.sh
                ;;
        esac
        ;;
    ords)
        log_step "Downloading ORDS..."
        bash /usr/sandbox/app/system/download/download-ords.sh
        ;;
esac
