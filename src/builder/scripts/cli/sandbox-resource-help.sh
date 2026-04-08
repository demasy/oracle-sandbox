# ─── sandbox resource help ────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox <action> <resource> -h | --help
# Variables inherited: ACTION, RESOURCE, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "${ACTION}/${RESOURCE}" in

    # ── run ──────────────────────────────────────────────────────────────────

    run/sqlcl)
        echo ""
        echo -e "  ${CYAN}sandbox run sqlcl${NC} — Open an interactive SQLcl session"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox run sqlcl [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-u${NC}, ${CYAN}--user${NC} <user>       Required. Database user to connect as"
        echo -e "    ${CYAN}-p${NC}, ${CYAN}--pass${NC} <password>   Optional. Default: Default Password"
        echo ""
        echo -e "  ${YELLOW}Valid users:${NC}"
        echo -e "    ${CYAN}sys${NC}          SYS (sysdba) — CDB root"
        echo -e "    ${CYAN}system${NC}       SYSTEM — CDB root"
        echo -e "    ${CYAN}sandbox${NC}      SANDBOX — application user (PDB)"
        echo -e "    ${CYAN}sandbox_ai${NC}   SANDBOX_AI — AI/MCP user (PDB)"
        echo -e "    ${CYAN}demasy${NC}       DEMASY — application user (PDB)"
        echo -e "    ${CYAN}demasy_ai${NC}    DEMASY_AI — AI/MCP user (PDB)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox run sqlcl --user system"
        echo -e "    sandbox run sqlcl --user demasy"
        echo -e "    sandbox run sqlcl -u sandbox"
        echo -e "    sandbox run sqlcl --user demasy --pass mypassword"
        echo ""
        ;;

    run/healthcheck)
        echo ""
        echo -e "  ${CYAN}sandbox run healthcheck${NC} — Run the Oracle sandbox healthcheck"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox run healthcheck"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox run healthcheck"
        echo ""
        ;;

    run/mcp)
        echo ""
        echo -e "  ${CYAN}sandbox run mcp${NC} — Run the MCP server"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox run mcp"
        echo ""
        echo -e "  ${WHITE}Note:${NC}      Not yet implemented. Use ${CYAN}sandbox start mcp${NC} instead."
        echo ""
        ;;

    run/oracle)
        echo ""
        echo -e "  ${CYAN}sandbox run oracle${NC} — Run Oracle tools"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox run oracle"
        echo ""
        echo -e "  ${WHITE}Note:${NC}      Not yet implemented."
        echo ""
        ;;

    # ── start ─────────────────────────────────────────────────────────────────

    start/apex)
        echo ""
        echo -e "  ${CYAN}sandbox start apex${NC} — Start Oracle APEX (ORDS)"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox start apex"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox start apex"
        echo ""
        ;;

    start/mcp)
        echo ""
        echo -e "  ${CYAN}sandbox start mcp${NC} — Start the MCP server"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox start mcp [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-d${NC}, ${CYAN}--default${NC}                       Use the default saved connection"
        echo -e "    ${CYAN}-c${NC}, ${CYAN}--conn${NC}, ${CYAN}--connection${NC} <name>  Use the specified saved connection"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox start mcp -d"
        echo -e "    sandbox start mcp --default"
        echo -e "    sandbox start mcp -c mcp-saved"
        echo -e "    sandbox start mcp --conn mcp-saved"
        echo -e "    sandbox start mcp --connection mcp-saved"
        echo ""
        ;;

    # ── stop ──────────────────────────────────────────────────────────────────

    stop/apex)
        echo ""
        echo -e "  ${CYAN}sandbox stop apex${NC} — Stop Oracle APEX (ORDS)"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox stop apex"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox stop apex"
        echo ""
        ;;

    stop/mcp)
        echo ""
        echo -e "  ${CYAN}sandbox stop mcp${NC} — Stop the MCP server"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox stop mcp"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox stop mcp"
        echo ""
        ;;

    # ── restart ───────────────────────────────────────────────────────────────

    restart/apex)
        echo ""
        echo -e "  ${CYAN}sandbox restart apex${NC} — Restart Oracle APEX (ORDS)"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox restart apex"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox restart apex"
        echo ""
        ;;

    restart/mcp)
        echo ""
        echo -e "  ${CYAN}sandbox restart mcp${NC} — Restart the MCP server"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox restart mcp"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox restart mcp"
        echo ""
        ;;

    # ── install ───────────────────────────────────────────────────────────────

    install/oracle)
        echo ""
        echo -e "  ${CYAN}sandbox install oracle${NC} — Install Oracle Instant Client"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox install oracle"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox install oracle"
        echo ""
        ;;

    install/client)
        echo ""
        echo -e "  ${CYAN}sandbox install client${NC} — Install Oracle Instant Client"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox install client"
        echo ""
        echo -e "  ${WHITE}Note:${NC}      Alias for ${CYAN}sandbox install oracle${NC}"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox install client"
        echo ""
        ;;

    install/sqlcl)
        echo ""
        echo -e "  ${CYAN}sandbox install sqlcl${NC} — Install Oracle SQLcl"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox install sqlcl"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox install sqlcl"
        echo ""
        ;;

    install/sqlplus)
        echo ""
        echo -e "  ${CYAN}sandbox install sqlplus${NC} — Install Oracle SQL*Plus"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox install sqlplus"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox install sqlplus"
        echo ""
        ;;

    install/apex)
        echo ""
        echo -e "  ${CYAN}sandbox install apex${NC} — Install Oracle APEX + ORDS"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox install apex"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox install apex"
        echo ""
        ;;

    # ── uninstall ─────────────────────────────────────────────────────────────

    uninstall/apex)
        echo ""
        echo -e "  ${CYAN}sandbox uninstall apex${NC} — Uninstall Oracle APEX + ORDS"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox uninstall apex"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox uninstall apex"
        echo ""
        ;;

    # ── download ──────────────────────────────────────────────────────────────

    download/apex)
        echo ""
        echo -e "  ${CYAN}sandbox download apex${NC} — Download Oracle APEX"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox download apex <parameter>"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-s${NC}, ${CYAN}--standalone${NC}   Download APEX only (without ORDS)"
        echo -e "    ${CYAN}-a${NC}, ${CYAN}--all${NC}          Download APEX + ORDS together"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox download apex -s"
        echo -e "    sandbox download apex --standalone"
        echo -e "    sandbox download apex -a"
        echo -e "    sandbox download apex --all"
        echo ""
        ;;

    download/ords)
        echo ""
        echo -e "  ${CYAN}sandbox download ords${NC} — Download Oracle REST Data Services"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox download ords"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox download ords"
        echo ""
        ;;

esac
