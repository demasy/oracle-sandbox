# ─── sandbox resource help ────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox <action> <resource> -h | --help
# Variables inherited: ACTION, RESOURCE, logging/color functions, SANDBOX_HELP_SHORT
# ─────────────────────────────────────────────────────────────────────────────

# ─── Renderer ─────────────────────────────────────────────────────────────────

_rh_print() {
    local key="${ACTION}/${RESOURCE}"
    local desc="${SANDBOX_HELP_SHORT[${ACTION}:${RESOURCE}]:-${SANDBOX_HELP_SHORT[${ACTION}]:-}}"

    echo ""
    echo -e "  ${CYAN}sandbox ${ACTION} ${RESOURCE}${NC} — ${desc}"
    echo ""
    echo -e "  ${WHITE}Usage:${NC}     sandbox ${ACTION} ${RESOURCE}${*:+ $*}"
    echo ""
}

_rh_params() {
    echo -e "  ${YELLOW}Parameters:${NC}"
}

_rh_p() {
    local flag="$1" meta="$2" desc="$3"
    printf "    ${CYAN}%-20s${NC}  %s\n" "${flag} ${meta}" "${desc}"
}

_rh_examples() {
    echo ""
    echo -e "  ${YELLOW}Examples:${NC}"
}

_rh_e() {
    echo -e "    $*"
}

_rh_note() {
    echo -e "  ${WHITE}Note:${NC}      $*"
}

_rh_end() {
    echo ""
}

# ─── Shared param blocks ──────────────────────────────────────────────────────

_rh_params_logs() {
    _rh_params
    _rh_p "-f, --follow"  ""      "Stream log output"
    _rh_p "-n, --lines"   "<N>"   "Lines to show (default: 50)"
}

_rh_params_export() {
    _rh_params
    _rh_p "--export" "<format>" "Output format: json|csv (default: table)"
}

_rh_params_from() {
    _rh_params
    _rh_p "--from" "<backup-id>" "Backup ID (e.g. 20260627-120000). Default: latest."
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

case "${ACTION}/${RESOURCE}" in

    # ── conn ──────────────────────────────────────────────────────────────────

    conn/list)
        _rh_print "[--export json|csv]"
        _rh_params_export
        _rh_examples
        _rh_e "sandbox conn list"
        _rh_e "sandbox conn list --export json"
        _rh_e "sandbox conn list --export csv"
        _rh_end ;;

    conn/add)
        _rh_print "[parameters]"
        _rh_params
        _rh_p "--name, -n" "<name>"      "Required. Connection name [a-zA-Z0-9_-], max 64"
        _rh_p "--user"     "<user>"      "Required. Database user"
        _rh_p "--pass"     "<password>"  "Optional. Default: env password"
        _rh_p "--host"     "<host>"      "Optional. Default: \$SANDBOX_DB_HOST"
        _rh_p "--port"     "<port>"      "Optional. Default: \$SANDBOX_DB_PORT"
        _rh_p "--pdb"      "<PDB name>"  "Optional. Default: \$SANDBOX_DB_SERVICE"
        _rh_examples
        _rh_e "sandbox conn add --name sandbox-mcp --user sandbox_ai --pdb SANDBOX_PDB"
        _rh_end ;;

    conn/delete)
        _rh_print "--name <name>"
        _rh_params
        _rh_p "--name, -n" "<name>" "Required. Connection name to delete"
        _rh_examples
        _rh_e "sandbox conn delete --name sandbox-mcp"
        _rh_end ;;

    conn/rename)
        _rh_print "--from <name> --to <name>"
        _rh_params
        _rh_p "--from" "<name>" "Required. Current connection name"
        _rh_p "--to"   "<name>" "Required. New connection name"
        _rh_examples
        _rh_e "sandbox conn rename --from sandbox-mcp --to demasy-mcp"
        _rh_end ;;

    conn/test)
        _rh_print "--name <name>"
        _rh_params
        _rh_p "--name, -n" "<name>" "Required. Connection name to test"
        _rh_examples
        _rh_e "sandbox conn test --name sandbox-mcp"
        _rh_end ;;

    # ── logs ──────────────────────────────────────────────────────────────────

    logs/apex|logs/install|logs/ords|logs/startup|logs/all)
        _rh_print "[--follow] [--lines N]"
        _rh_params_logs
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --follow"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --lines 100"
        _rh_end ;;

    logs/mcp)
        _rh_print
        _rh_note "MCP log file: /tmp/sqlcl_mcp.log (written when started via 'sandbox start mcp')"
        _rh_params_logs
        _rh_examples
        _rh_e "sandbox logs mcp"
        _rh_e "sandbox logs mcp --follow"
        _rh_end ;;

    # ── run ───────────────────────────────────────────────────────────────────

    run/sqlcl)
        _rh_print "[--user <user>] [--pass <pass>] [--pdb <pdb>]"
        _rh_params
        _rh_p "-u, --user" "<user>"     "Required. Database user"
        _rh_p "-p, --pass" "<password>" "Optional. Default: env password"
        _rh_p "--pdb"      "<PDB name>" "Optional. Override default PDB"
        echo ""
        echo -e "  ${YELLOW}Valid users:${NC}"
        _rh_e "${CYAN}sys${NC}         SYS (sysdba) — CDB root"
        _rh_e "${CYAN}system${NC}      SYSTEM — CDB root"
        _rh_e "${CYAN}sandbox${NC}     SANDBOX — application user       (default PDB: SANDBOX_PDB)"
        _rh_e "${CYAN}sandbox_ai${NC}  SANDBOX_AI — AI/MCP user         (default PDB: SANDBOX_PDB)"
        _rh_e "${CYAN}demasy${NC}      DEMASY — application user        (default PDB: SANDBOX_PDB)"
        _rh_e "${CYAN}demasy_ai${NC}   DEMASY_AI — AI/MCP user          (default PDB: SANDBOX_PDB)"
        _rh_examples
        _rh_e "sandbox run sqlcl --user system"
        _rh_e "sandbox run sqlcl -u sandbox_ai --pdb SANDBOX_PDB"
        _rh_end ;;

    run/healthcheck)
        _rh_print "[--export json|csv]"
        _rh_params_export
        _rh_examples
        _rh_e "sandbox run healthcheck"
        _rh_e "sandbox run healthcheck --export json"
        _rh_end ;;

    run/mcp)
        _rh_print
        _rh_note "Runs MCP in foreground. Use ${CYAN}sandbox start mcp${NC} to run as daemon."
        _rh_examples
        _rh_e "sandbox run mcp"
        _rh_end ;;

    run/script)
        _rh_print "<script-name>"
        _rh_examples
        _rh_e "sandbox run script cleanup"
        _rh_e "sandbox run script report"
        _rh_end ;;

    # ── start / stop / restart ────────────────────────────────────────────────

    start/apex|stop/apex|restart/apex)
        _rh_print
        _rh_examples
        _rh_e "sandbox ${ACTION} apex"
        _rh_end ;;

    start/mcp)
        _rh_print "[-d | --conn <name>]"
        _rh_params
        _rh_p "-d, --default" ""       "Use the default saved connection"
        _rh_p "-c, --conn"    "<name>" "Use specified saved connection"
        _rh_examples
        _rh_e "sandbox start mcp -d"
        _rh_e "sandbox start mcp --conn sandbox-ai-conn"
        _rh_end ;;

    stop/mcp|restart/mcp)
        _rh_print
        _rh_examples
        _rh_e "sandbox ${ACTION} mcp"
        _rh_end ;;

    # ── install / uninstall / download ────────────────────────────────────────

    install/apex|uninstall/apex|download/apex)
        _rh_print
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_end ;;

    install/oracle|install/client|install/sqlcl|install/sqlplus)
        _rh_print
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_end ;;

    # ── export ────────────────────────────────────────────────────────────────

    export/config|export/connections|export/all)
        _rh_print "[--export json|csv]"
        _rh_params_export
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --export json"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --export csv > output.csv"
        _rh_end ;;

    # ── import ────────────────────────────────────────────────────────────────

    import/config|import/connections)
        _rh_print "--file <path>"
        _rh_params
        _rh_p "--file" "<path>" "Required. Path to import file"
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE} --file ./backup.json"
        _rh_end ;;

    # ── backup ────────────────────────────────────────────────────────────────

    backup/full|backup/connections|backup/ords|backup/config)
        _rh_print
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_end ;;

    backup/schemas)
        _rh_print
        _rh_note "Requires \$SANDBOX_DB_HOST and \$SANDBOX_DB_PASS. Uses Oracle Data Pump (expdp)."
        _rh_examples
        _rh_e "sandbox backup schemas"
        _rh_end ;;

    backup/list)
        _rh_print
        _rh_examples
        _rh_e "sandbox backup list"
        _rh_end ;;

    # ── restore ───────────────────────────────────────────────────────────────

    restore/full|restore/connections|restore/ords|restore/config)
        _rh_print "[--from <backup-id>]"
        _rh_params_from
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --from 20260627-120000"
        _rh_end ;;

    restore/schemas)
        _rh_print "[--from <backup-id>]"
        _rh_params_from
        _rh_note "Requires \$SANDBOX_DB_HOST and \$SANDBOX_DB_PASS. TABLE_EXISTS_ACTION=REPLACE."
        _rh_examples
        _rh_e "sandbox restore schemas"
        _rh_e "sandbox restore schemas --from 20260627-120000"
        _rh_end ;;

    # ── audit ─────────────────────────────────────────────────────────────────

    audit/list)
        _rh_print "[--limit N] [--search <term>]"
        _rh_params
        _rh_p "--limit"  "<N>"    "Number of entries to show (default: 50)"
        _rh_p "--search" "<term>" "Filter entries by keyword"
        _rh_examples
        _rh_e "sandbox audit list"
        _rh_e "sandbox audit list --limit 20"
        _rh_e "sandbox audit list --search conn"
        _rh_end ;;

    audit/search)
        _rh_print "--search <term>"
        _rh_params
        _rh_p "--search" "<term>"   "Required. Search keyword"
        _rh_p "--export" "<format>" "Optional. json|csv"
        _rh_examples
        _rh_e "sandbox audit search --search conn"
        _rh_e "sandbox audit search --search backup --export json"
        _rh_end ;;

    audit/export)
        _rh_print "[--export json|csv]"
        _rh_params_export
        _rh_examples
        _rh_e "sandbox audit export --export json > audit.json"
        _rh_e "sandbox audit export --export csv  > audit.csv"
        _rh_end ;;

    audit/stats)
        _rh_print
        _rh_examples
        _rh_e "sandbox audit stats"
        _rh_end ;;

    audit/rollback)
        _rh_print "--search <entry-id>"
        _rh_params
        _rh_p "--search" "<entry-id>" "Required. Audit entry ID to rollback"
        _rh_examples
        _rh_e "sandbox audit rollback --search 1750000000.12345"
        _rh_end ;;

    audit/show)
        _rh_print "--search <entry-id>"
        _rh_params
        _rh_p "--search" "<entry-id>" "Required. Audit entry ID to display"
        _rh_examples
        _rh_e "sandbox audit show --search 1750000000.12345"
        _rh_end ;;

    # ── batch ─────────────────────────────────────────────────────────────────

    batch/execute|batch/apply-commands)
        _rh_print "--file <path> [--dry-run]"
        _rh_params
        _rh_p "--file"    "<path>" "Required. File with one 'cmd=sandbox ...' per line"
        _rh_p "--dry-run" ""       "Preview commands without executing"
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE} --file commands.txt"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --file commands.txt --dry-run"
        _rh_end ;;

    batch/apply-connections)
        _rh_print "--file <path>"
        _rh_params
        _rh_p "--file" "<path>" "Required. CSV file: name,user,password,host,port,pdb"
        _rh_examples
        _rh_e "sandbox batch apply-connections --file connections.csv"
        _rh_end ;;

    # ── monitor ───────────────────────────────────────────────────────────────

    monitor/system|monitor/database|monitor/apex|monitor/all)
        _rh_print "[--export json|prometheus]"
        _rh_params
        _rh_p "--export" "<format>" "Output format: json|prometheus (default: table)"
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --export json"
        _rh_end ;;

    # ── template ──────────────────────────────────────────────────────────────

    template/save)
        _rh_print "--name <name> [--description <text>]"
        _rh_params
        _rh_p "--name"        "<name>" "Required. Template name"
        _rh_p "--description" "<text>" "Optional. Short description"
        _rh_examples
        _rh_e "sandbox template save --name production --description 'Production config'"
        _rh_end ;;

    template/load)
        _rh_print "--name <name> [--apply]"
        _rh_params
        _rh_p "--name"  "<name>" "Required. Template name to load"
        _rh_p "--apply" ""       "Apply environment variables from template"
        _rh_examples
        _rh_e "sandbox template load --name production"
        _rh_e "sandbox template load --name production --apply"
        _rh_end ;;

    template/list)
        _rh_print "[--format json|csv]"
        _rh_params
        _rh_p "--format" "<format>" "Output format: json|csv|table (default: table)"
        _rh_examples
        _rh_e "sandbox template list"
        _rh_e "sandbox template list --format json"
        _rh_end ;;

    template/delete)
        _rh_print "--name <name>"
        _rh_params
        _rh_p "--name" "<name>" "Required. Template name to delete"
        _rh_examples
        _rh_e "sandbox template delete --name production"
        _rh_end ;;

    template/export)
        _rh_print "--name <name> [--file <path>]"
        _rh_params
        _rh_p "--name" "<name>" "Required. Template name"
        _rh_p "--file" "<path>" "Optional. Output path (default: current dir)"
        _rh_examples
        _rh_e "sandbox template export --name production --file ./production.template"
        _rh_end ;;

    template/import)
        _rh_print "--file <path> [--name <name>]"
        _rh_params
        _rh_p "--file" "<path>" "Required. Template file to import"
        _rh_p "--name" "<name>" "Optional. Override template name"
        _rh_examples
        _rh_e "sandbox template import --file ./production.template"
        _rh_end ;;

    # ── status ────────────────────────────────────────────────────────────────

    status/database|status/apex|status/mcp|status/network|status/all)
        _rh_print "[--export json|csv]"
        _rh_params_export
        _rh_examples
        _rh_e "sandbox ${ACTION} ${RESOURCE}"
        _rh_e "sandbox ${ACTION} ${RESOURCE} --export json"
        _rh_end ;;

    # ── fallback ──────────────────────────────────────────────────────────────

    *)
        echo ""
        echo -e "  ${CYAN}sandbox ${ACTION} ${RESOURCE}${NC}"
        echo ""
        desc="${SANDBOX_HELP_SHORT[${ACTION}:${RESOURCE}]:-${SANDBOX_HELP_SHORT[${ACTION}]:-No description available}}"
        echo -e "  ${desc}"
        echo ""
        echo -e "  ${YELLOW}Tip:${NC} Use ${CYAN}sandbox help search ${ACTION}${NC} to find related commands"
        echo ""
        ;;
esac
