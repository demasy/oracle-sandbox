#!/bin/bash
# ============================================
# Sandbox CLI
# ============================================
# Main entrypoint for the Demasylabs Oracle Sandbox
# Usage: sandbox <action> <resource> [parameters]
#
# Actions:
#   download   Download Oracle components
#   install    Install Oracle components
#   uninstall  Uninstall Oracle components
#   start      Start a service
#   stop       Stop a service
#   run        Run / connect to a service
#
# Resources:
#   download:                       apex | ords
#   install / uninstall:            oracle | client | sqlcl | sqlplus
#   start / stop:                   mcp | system
#   run:                            oracle | mcp | system
#
# Examples:
#   sandbox download apex -s
#   sandbox download apex -standalone
#   sandbox download apex -a
#   sandbox download apex --all
#   sandbox download ords
#   sandbox install sqlcl
#   sandbox start mcp -d
#   sandbox start mcp --default
#   sandbox start mcp -conn mcp-saved
#   sandbox start mcp --connection mcp-saved
#   sandbox run mcp
# ============================================

source /usr/demasy/scripts/backbone/utils/colors.sh
source /usr/demasy/scripts/backbone/utils/logging.sh
source /usr/demasy/scripts/backbone/utils/banner.sh

# ─── Resource sets per action ─────────────────────────────────────────────────

resources_for() {
    case "$1" in
        download)                   echo "apex ords" ;;
        install|uninstall)          echo "oracle client sqlcl sqlplus apex" ;;
        start|stop|restart)         echo "apex mcp system" ;;
        run)                        echo "oracle mcp system" ;;
        *)                          echo "" ;;
    esac
}

# ─── Apex parameter parser ────────────────────────────────────────────────────

parse_apex_param() {
    local param="$1"
    if [[ -z "$param" ]]; then
        echo ""
        log_error "sandbox download apex requires a parameter"
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-s${NC}, ${CYAN}-standalone${NC}   Download APEX only"
        echo -e "    ${CYAN}-a${NC}, ${CYAN}--all${NC}         Download APEX + ORDS"
        echo ""
        exit 1
    fi
    case "$param" in
        -s|-standalone) echo "standalone" ;;
        -a|--all)       echo "full" ;;
        *)
            echo ""
            log_error "Unknown parameter '${param}' for sandbox download apex"
            echo -e "  ${YELLOW}Parameters:${NC}"
            echo -e "    ${CYAN}-s${NC}, ${CYAN}-standalone${NC}   Download APEX only"
            echo -e "    ${CYAN}-a${NC}, ${CYAN}--all${NC}         Download APEX + ORDS"
            echo ""
            exit 1
            ;;
    esac
}

# ─── Usage ───────────────────────────────────────────────────────────────────

print_usage() {
    echo ""
    echo -e "  ${CYAN}sandbox${NC} — Oracle Sandbox CLI"
    echo ""
    echo -e "  ${WHITE}Usage:${NC}   sandbox <action> <resource> [parameters]"
    echo ""
    echo -e "  ${YELLOW}Actions & Resources:${NC}"
    echo -e "    ${CYAN}download${NC}   apex | ords"
    echo -e "    ${CYAN}install${NC}    oracle | client | sqlcl | sqlplus | apex"
    echo -e "    ${CYAN}uninstall${NC}  oracle | client | sqlcl | sqlplus | apex"
    echo -e "    ${CYAN}start${NC}      apex | mcp | system"
    echo -e "    ${CYAN}stop${NC}       apex | mcp | system"
    echo -e "    ${CYAN}restart${NC}    apex | mcp | system"
    echo -e "    ${CYAN}run${NC}        oracle | mcp | system"
    echo ""
    echo -e "  ${YELLOW}Download parameters:${NC}"
    echo -e "    ${CYAN}apex -s${NC}, ${CYAN}-standalone${NC}   Download APEX only"
    echo -e "    ${CYAN}apex -a${NC}, ${CYAN}--all${NC}         Download APEX + ORDS"
    echo ""
    echo -e "  ${YELLOW}Examples:${NC}"
    echo -e "    sandbox download apex -s"
    echo -e "    sandbox download apex --all"
    echo -e "    sandbox download ords"
    echo -e "    sandbox install sqlcl"
    echo -e "    sandbox start apex"
    echo -e "    sandbox stop apex"
    echo -e "    sandbox restart apex"
    echo -e "    sandbox start mcp -d"
    echo -e "    sandbox start mcp --default"
    echo -e "    sandbox start mcp -conn mcp-saved"
    echo -e "    sandbox start mcp --connection mcp-saved"
    echo -e "    sandbox run mcp"
    echo ""
}

# ─── Validation ──────────────────────────────────────────────────────────────

VALID_ACTIONS="download install uninstall start stop restart run"

validate_action() {
    local action="$1"
    for a in $VALID_ACTIONS; do
        [[ "$a" == "$action" ]] && return 0
    done
    echo ""
    log_error "Unknown action: '${action}'"
    echo -e "  ${YELLOW}Available actions:${NC} ${CYAN}${VALID_ACTIONS}${NC}"
    print_usage
    exit 1
}

validate_resource() {
    local action="$1" resource="$2"
    local valid
    valid=$(resources_for "$action")
    for r in $valid; do
        [[ "$r" == "$resource" ]] && return 0
    done
    echo ""
    log_error "Invalid resource '${resource}' for action '${action}'"
    echo -e "  ${YELLOW}Valid resources for ${CYAN}${action}${YELLOW}:${NC} ${CYAN}${valid}${NC}"
    echo ""
    exit 1
}

# ─── Entry point ─────────────────────────────────────────────────────────────

clear
print_demasy_banner "Sandbox CLI"

if [[ $# -lt 1 ]]; then
    print_usage
    exit 0
fi

ACTION="$1"
RESOURCE="${2:-}"
shift 2 2>/dev/null || true
PARAMS="$*"

validate_action "$ACTION"

if [[ -z "$RESOURCE" ]]; then
    echo ""
    log_error "Missing resource for action '${ACTION}'"
    valid=$(resources_for "$ACTION")
    echo -e "  ${YELLOW}Available resources:${NC} ${CYAN}${valid}${NC}"
    echo ""
    exit 1
fi

validate_resource "$ACTION" "$RESOURCE"

# ─── Dispatch ────────────────────────────────────────────────────────────────

echo ""
log_step "sandbox ${ACTION} ${RESOURCE}${PARAMS:+ ${PARAMS}}"
echo ""

case "$ACTION" in
    download)
        case "$RESOURCE" in
            apex)
                APEX_MODE=$(parse_apex_param "$PARAMS")
                case "$APEX_MODE" in
                    standalone)
                        log_step "Downloading APEX (standalone)..."
                        bash /usr/demasy/scripts/oracle/admin/download-apex-standalone.sh
                        ;;
                    full)
                        log_step "Downloading APEX + ORDS..."
                        bash /usr/demasy/scripts/oracle/admin/download-apex.sh
                        ;;
                esac
                ;;
            ords)
                log_step "Downloading ORDS..."
                bash /usr/demasy/scripts/oracle/admin/download-ords.sh
                ;;
        esac
        ;;
    install)
        case "$RESOURCE" in
            oracle|client)
                log_step "Installing Oracle Instant Client..."
                bash /usr/demasy/scripts/oracle/admin/install-client.sh
                ;;
            sqlcl)
                log_step "Installing SQLcl..."
                bash /usr/demasy/scripts/oracle/admin/install-sqlcl.sh
                ;;
            sqlplus)
                log_step "Installing SQL*Plus..."
                bash /usr/demasy/scripts/oracle/admin/install-sqlplus.sh
                ;;
            apex)
                log_step "Installing APEX + ORDS..."
                bash /usr/demasy/scripts/oracle/apex/install.sh
                ;;
        esac
        ;;
    uninstall)
        case "$RESOURCE" in
            oracle)   log_warn "sandbox uninstall oracle  — not implemented yet" ;;
            client)   log_warn "sandbox uninstall client  — not implemented yet" ;;
            sqlcl)    log_warn "sandbox uninstall sqlcl   — not implemented yet" ;;
            sqlplus)  log_warn "sandbox uninstall sqlplus — not implemented yet" ;;
            apex)
                log_step "Uninstalling APEX + ORDS..."
                bash /usr/demasy/scripts/oracle/apex/uninstall.sh
                ;;
        esac
        ;;
    start)
        case "$RESOURCE" in
            mcp)
                # Re-parse remaining params for flag + optional value
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
            system)   log_warn "sandbox start system — not implemented yet" ;;
        esac
        ;;
    stop)
        case "$RESOURCE" in
            apex)
                log_step "Stopping APEX (ORDS)..."
                bash /usr/demasy/scripts/oracle/apex/stop.sh
                ;;
            mcp)      log_warn "sandbox stop mcp    — not implemented yet" ;;
            system)   log_warn "sandbox stop system — not implemented yet" ;;
        esac
        ;;
    restart)
        case "$RESOURCE" in
            apex)
                log_step "Restarting APEX (ORDS)..."
                bash /usr/demasy/scripts/oracle/apex/stop.sh
                bash /usr/demasy/scripts/oracle/apex/start.sh
                ;;
            mcp)      log_warn "sandbox restart mcp    — not implemented yet" ;;
            system)   log_warn "sandbox restart system — not implemented yet" ;;
        esac
        ;;
    run)
        case "$RESOURCE" in
            oracle)   log_warn "sandbox run oracle — not implemented yet" ;;
            mcp)      log_warn "sandbox run mcp    — not implemented yet" ;;
            system)   log_warn "sandbox run system — not implemented yet" ;;
        esac
        ;;
esac

echo ""
