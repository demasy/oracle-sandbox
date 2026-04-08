# ─── sandbox run ──────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox run <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

VALID_SQLCL_USERS="sys system demasy sandbox demasylabs demasy_ai"

case "$RESOURCE" in
    sqlcl)
        SQLCL_USER="" SQLCL_PASS=""
        set -- $PARAMS
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -user)
                    if [[ -z "${2:-}" ]]; then
                        echo ""
                        log_error "-user requires a value"
                        echo -e "  ${YELLOW}Valid users:${NC} ${CYAN}${VALID_SQLCL_USERS}${NC}"
                        echo ""
                        exit 1
                    fi
                    SQLCL_USER="$2"; shift 2
                    ;;
                -pass)
                    if [[ -z "${2:-}" ]]; then
                        echo ""
                        log_error "-pass requires a value"
                        echo ""
                        exit 1
                    fi
                    SQLCL_PASS="$2"; shift 2
                    ;;
                *)
                    echo ""
                    log_error "Unknown parameter '${1}' for sandbox run sqlcl"
                    echo -e "  ${YELLOW}Parameters:${NC}"
                    echo -e "    ${CYAN}-user${NC} <user>       Required. One of: ${VALID_SQLCL_USERS}"
                    echo -e "    ${CYAN}-pass${NC} <password>   Optional. Default: \$DEMASYLABS_DB_PASSWORD"
                    echo ""
                    exit 1
                    ;;
            esac
        done

        if [[ -z "$SQLCL_USER" ]]; then
            echo ""
            log_error "sandbox run sqlcl requires -user <user>"
            echo -e "  ${YELLOW}Valid users:${NC} ${CYAN}${VALID_SQLCL_USERS}${NC}"
            echo -e "  ${YELLOW}Example:${NC}    ${CYAN}sandbox run sqlcl -user system${NC}"
            echo ""
            exit 1
        fi

        VALID_USER=false
        for u in $VALID_SQLCL_USERS; do
            [[ "$u" == "$SQLCL_USER" ]] && VALID_USER=true && break
        done
        if [[ "$VALID_USER" == false ]]; then
            echo ""
            log_error "Unknown user '${SQLCL_USER}' for sandbox run sqlcl"
            echo -e "  ${YELLOW}Valid users:${NC} ${CYAN}${VALID_SQLCL_USERS}${NC}"
            echo ""
            exit 1
        fi

        CONN_PASS="${SQLCL_PASS:-${DEMASYLABS_DB_PASSWORD}}"
        CONN_HOST="${DEMASYLABS_DB_HOST}"
        CONN_PORT="${DEMASYLABS_DB_PORT}"

        case "$SQLCL_USER" in
            sys)
                log_step "Connecting as SYS (sysdba) @ ${DEMASYLABS_DB_SERVICE}..."
                sql "sys/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${DEMASYLABS_DB_SERVICE}" as sysdba
                ;;
            system)
                log_step "Connecting as SYSTEM @ ${DEMASYLABS_DB_SERVICE}..."
                sql "system/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${DEMASYLABS_DB_SERVICE}"
                ;;
            demasy)
                log_step "Connecting as DEMASY @ DEMASYLABS_PDB..."
                sql "demasy/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/DEMASYLABS_PDB"
                ;;
            sandbox)
                log_step "Connecting as SANDBOX @ DEMASYLABS_PDB..."
                sql "sandbox/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/DEMASYLABS_PDB"
                ;;
            demasylabs)
                log_step "Connecting as C##DEMASY (common user) @ DEMASYLABS_PDB..."
                sql "c##demasy/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/DEMASYLABS_PDB"
                ;;
            demasy_ai)
                log_step "Connecting as ${DEMASYLABS_DB_MCP_USER} (AI/MCP user) @ DEMASYLABS_PDB..."
                sql "${DEMASYLABS_DB_MCP_USER}/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/DEMASYLABS_PDB"
                ;;
        esac
        ;;
    oracle)   log_warn "sandbox run oracle — not implemented yet" ;;
    mcp)      log_warn "sandbox run mcp    — not implemented yet" ;;
    system)   log_warn "sandbox run system — not implemented yet" ;;
    healthcheck)
        log_step "Running healthcheck..."
        bash /usr/sandbox/app/system/admin/healthcheck.sh
        ;;
esac
