# ─── sandbox download ─────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox download <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

# ─── Apex parameter parser ────────────────────────────────────────────────────

parse_apex_param() {
    local param="$1"
    if [[ -z "$param" ]]; then
        echo ""
        log_error "sandbox download apex requires a parameter"
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-s${NC}, ${CYAN}--standalone${NC}   Download APEX only"
        echo -e "    ${CYAN}-a${NC}, ${CYAN}--all${NC}         Download APEX + ORDS"
        echo ""
        exit 1
    fi
    case "$param" in
        -s|--standalone) echo "standalone" ;;
        -a|--all)        echo "full" ;;
        *)
            echo ""
            log_error "Unknown parameter '${param}' for sandbox download apex"
            echo -e "  ${YELLOW}Parameters:${NC}"
            echo -e "    ${CYAN}-s${NC}, ${CYAN}--standalone${NC}   Download APEX only"
            echo -e "    ${CYAN}-a${NC}, ${CYAN}--all${NC}         Download APEX + ORDS"
            echo ""
            exit 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    apex)
        APEX_MODE=$(parse_apex_param "$PARAMS")
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
