# ─── sandbox resource help ────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox <action> <resource> -h | --help
# Variables inherited: ACTION, RESOURCE, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "${ACTION}/${RESOURCE}" in

    # ── conn ─────────────────────────────────────────────────────────────────

    conn/list)
        echo ""
        echo -e "  ${CYAN}sandbox conn list${NC} — List all saved MCP connections"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox conn list [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--format${NC}  <format>   Output format: json|csv|table (default: table)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox conn list"
        echo -e "    sandbox conn list --format json"
        echo -e "    sandbox conn list --format csv"
        echo ""
        ;;

    conn/add)
        echo ""
        echo -e "  ${CYAN}sandbox conn add${NC} — Add a new saved MCP connection"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox conn add [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--name${NC}  <name>       Required. Connection name"
        echo -e "    ${CYAN}--user${NC}  <user>       Required. Database user"
        echo -e "    ${CYAN}--pass${NC}  <password>   Optional. Default: env password"
        echo -e "    ${CYAN}--host${NC}  <host>       Optional. Default: env host"
        echo -e "    ${CYAN}--port${NC}  <port>       Optional. Default: env port"
        echo -e "    ${CYAN}--pdb${NC}   <PDB name>   Optional. Default: env service"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox conn add --name sandbox-mcp --user demasy_ai --pdb SANDBOX_PDB"
        echo -e "    sandbox conn add --name sandbox-mcp --user sandbox_ai --pdb SANDBOX_PDB"
        echo ""
        ;;

    conn/delete)
        echo ""
        echo -e "  ${CYAN}sandbox conn delete${NC} — Delete a saved MCP connection"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox conn delete --name <name>"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--name${NC}  <name>   Required. Connection name to delete"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox conn delete --name sandbox-mcp"
        echo ""
        ;;

    conn/rename)
        echo ""
        echo -e "  ${CYAN}sandbox conn rename${NC} — Rename a saved MCP connection"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox conn rename --from <name> --to <name>"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--from${NC}  <name>   Required. Current connection name"
        echo -e "    ${CYAN}--to${NC}    <name>   Required. New connection name"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox conn rename --from sandbox-mcp --to demasy-mcp"
        echo ""
        ;;

    conn/test)
        echo ""
        echo -e "  ${CYAN}sandbox conn test${NC} — Test a saved MCP connection"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox conn test --name <name>"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--name${NC}  <name>   Required. Connection name to test"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox conn test --name sandbox-mcp"
        echo ""
        ;;

    # ── logs ─────────────────────────────────────────────────────────────────

    logs/apex)
        echo ""
        echo -e "  ${CYAN}sandbox logs apex${NC} — View APEX installation logs"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox logs apex [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-f${NC}, ${CYAN}--follow${NC}        Stream log output"
        echo -e "    ${CYAN}-n${NC}, ${CYAN}--lines${NC} <N>     Lines to show (default: 50)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox logs apex"
        echo -e "    sandbox logs apex --follow"
        echo ""
        ;;

    logs/install)
        echo ""
        echo -e "  ${CYAN}sandbox logs install${NC} — View all installation logs (APEX + ORDS)"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox logs install [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-f${NC}, ${CYAN}--follow${NC}        Stream log output"
        echo -e "    ${CYAN}-n${NC}, ${CYAN}--lines${NC} <N>     Lines to show (default: 50)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox logs install"
        echo -e "    sandbox logs install --lines 100"
        echo ""
        ;;

    logs/ords)
        echo ""
        echo -e "  ${CYAN}sandbox logs ords${NC} — View ORDS runtime log"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox logs ords [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-f${NC}, ${CYAN}--follow${NC}        Stream log output"
        echo -e "    ${CYAN}-n${NC}, ${CYAN}--lines${NC} <N>     Lines to show (default: 50)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox logs ords"
        echo -e "    sandbox logs ords --follow"
        echo ""
        ;;

    logs/startup)
        echo ""
        echo -e "  ${CYAN}sandbox logs startup${NC} — View container startup / user-setup log"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox logs startup [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-f${NC}, ${CYAN}--follow${NC}        Stream log output"
        echo -e "    ${CYAN}-n${NC}, ${CYAN}--lines${NC} <N>     Lines to show (default: 50)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox logs startup"
        echo -e "    sandbox logs startup --follow"
        echo ""
        ;;

    logs/mcp)
        echo ""
        echo -e "  ${CYAN}sandbox logs mcp${NC} — View MCP server log"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox logs mcp"
        echo ""
        echo -e "  ${WHITE}Note:${NC}      MCP server does not write a log file."
        echo -e "             Use ${CYAN}sandbox run mcp${NC} to see output in the foreground."
        echo ""
        ;;

    logs/all)
        echo ""
        echo -e "  ${CYAN}sandbox logs all${NC} — View all sandbox log files"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox logs all [parameters]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}-f${NC}, ${CYAN}--follow${NC}        Stream log output"
        echo -e "    ${CYAN}-n${NC}, ${CYAN}--lines${NC} <N>     Lines to show (default: 50)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox logs all"
        echo -e "    sandbox logs all --lines 20"
        echo ""
        ;;

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
        echo -e "    ${CYAN}--pdb${NC} <PDB name>          Optional. Override the default PDB for the user"
        echo ""
        echo -e "  ${YELLOW}Valid users:${NC}"
        echo -e "    ${CYAN}sys${NC}          SYS (sysdba) — CDB root          (default: CDB service)"
        echo -e "    ${CYAN}system${NC}       SYSTEM — CDB root                (default: CDB service)"
        echo -e "    ${CYAN}sandbox${NC}      SANDBOX — application user       (default: SANDBOX_PDB)"
        echo -e "    ${CYAN}sandbox_ai${NC}   SANDBOX_AI — AI/MCP user         (default: SANDBOX_PDB)"
        echo -e "    ${CYAN}demasy${NC}       DEMASY — application user        (default: SANDBOX_PDB)"
        echo -e "    ${CYAN}demasy_ai${NC}    DEMASY_AI — AI/MCP user          (default: SANDBOX_PDB)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox run sqlcl --user system"
        echo -e "    sandbox run sqlcl --user demasy"
        echo -e "    sandbox run sqlcl -u sandbox"
        echo -e "    sandbox run sqlcl --user demasy --pass mypassword"
        echo -e "    sandbox run sqlcl --user demasy --pdb SANDBOX_PDB"
        echo -e "    sandbox run sqlcl -u sandbox --pdb SANDBOX_PDB"
        echo -e "    sandbox run sqlcl --user demasy --pdb SANDBOX_PDB"
        echo -e "    sandbox run sqlcl -u sandbox --pdb SANDBOX_PDB"
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
        echo -e "    ${CYAN}-c${NC}, ${CYAN}--conn${NC} <name>  Use the specified saved connection"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox start mcp -d"
        echo -e "    sandbox start mcp --default"
        echo -e "    sandbox start mcp -c sandbox-mcp-conn"
        echo -e "    sandbox start mcp --conn sandbox-mcp-conn"
        echo -e "    sandbox start mcp --conn demasy-mcp-conn"
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

    # ── export ────────────────────────────────────────────────────────────────

    export/config)
        echo ""
        echo -e "  ${CYAN}sandbox export config${NC} — Export all sandbox settings"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox export config [--format json|csv|table]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--format${NC}  <format>   Output format: json|csv|table (default: table)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox export config"
        echo -e "    sandbox export config --format json"
        echo -e "    sandbox export config --format csv"
        echo ""
        ;;

    export/connections)
        echo ""
        echo -e "  ${CYAN}sandbox export connections${NC} — Export saved database connections"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox export connections [--format json|csv|table]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--format${NC}  <format>   Output format: json|csv|table (default: table)"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox export connections"
        echo -e "    sandbox export connections --format json"
        echo -e "    sandbox export connections --format csv > connections.csv"
        echo ""
        ;;

    export/all)
        echo ""
        echo -e "  ${CYAN}sandbox export all${NC} — Export all settings and connections"
        echo ""
        echo -e "  ${WHITE}Usage:${NC}     sandbox export all [--format json|csv|table]"
        echo ""
        echo -e "  ${YELLOW}Parameters:${NC}"
        echo -e "    ${CYAN}--format${NC}  <format>   Output format: json|csv|table (default: table)"
        echo ""
        echo -e "  ${WHITE}Note:${NC}      Same as ${CYAN}sandbox export config${NC}"
        echo ""
        echo -e "  ${YELLOW}Examples:${NC}"
        echo -e "    sandbox export all"
        echo -e "    sandbox export all --format json > config.json"
        echo ""
        ;;

esac
