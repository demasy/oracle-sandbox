# ─── sandbox start ────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox start <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    mcp)
        MCP_FLAG="" MCP_CONN_NAME=""
        set -- $PARAMS
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -d|--default)
                    MCP_FLAG="default"
                    shift
                    ;;
                -conn|--connection)
                    if [[ -z "${2:-}" ]]; then
                        echo ""
                        log_error "-conn / --connection requires a connection name"
                        echo -e "  ${YELLOW}Example:${NC} ${CYAN}sandbox start mcp -conn mcp-saved${NC}"
                        echo ""
                        exit 1
                    fi
                    MCP_FLAG="conn"
                    MCP_CONN_NAME="$2"
                    shift 2
                    ;;
                *)
                    echo ""
                    log_error "Unknown parameter '${1}' for sandbox start mcp"
                    echo -e "  ${YELLOW}Parameters:${NC}"
                    echo -e "    ${CYAN}-d${NC}, ${CYAN}--default${NC}              Start MCP using the default saved connection"
                    echo -e "    ${CYAN}-conn${NC}, ${CYAN}--connection${NC} <name>  Start MCP using the specified saved connection"
                    echo ""
                    exit 1
                    ;;
            esac
        done

        if [[ -z "$MCP_FLAG" ]]; then
            echo ""
            log_error "sandbox start mcp requires a parameter"
            echo -e "  ${YELLOW}Parameters:${NC}"
            echo -e "    ${CYAN}-d${NC}, ${CYAN}--default${NC}              Start MCP using the default saved connection (demasylabs-ai-conn)"
            echo -e "    ${CYAN}-conn${NC}, ${CYAN}--connection${NC} <name>  Start MCP using the specified saved connection"
            echo ""
            exit 1
        fi

        case "$MCP_FLAG" in
            default)
                log_step "Starting MCP server with default saved connection..."
                bash /usr/demasy/scripts/oracle/mcp/start-mcp-with-saved-connection.sh
                ;;
            conn)
                log_step "Starting MCP server with saved connection: ${MCP_CONN_NAME}..."
                bash /usr/demasy/scripts/oracle/mcp/start-mcp-with-saved-connection.sh "$MCP_CONN_NAME"
                ;;
        esac
        ;;
    apex)
        log_step "Starting APEX (ORDS)..."
        bash /usr/demasy/scripts/oracle/apex/start.sh
        ;;
    healthcheck)
        log_step "Running healthcheck..."
        bash /usr/demasy/scripts/oracle/admin/healthcheck.sh
        ;;
    system)   log_warn "sandbox start system — not implemented yet" ;;
esac
