# ─── sandbox help search ──────────────────────────────────────────────────────
# Implements: sandbox help search <keyword> | sandbox help [search]
# Provides command discovery by keyword, category, and aliases
# Called by sandbox.sh when ACTION="help"
# ─────────────────────────────────────────────────────────────────────────────

# Arguments from sandbox.sh:
#   $1 = RESOURCE (e.g., "search" or empty for full help)
#   $2 = PARAMS (e.g., keyword if RESOURCE="search")

HELP_RESOURCE="${1:-}"
HELP_KEYWORD="${2:-}"

# ─── Helper: search help by keyword ────────────────────────────────────────────

_help_search_by_keyword() {
    local keyword="$1"
    local matches=""

    # 1. Exact keyword map hit
    if [[ -n "${SANDBOX_HELP_KEYWORDS[$keyword]:-}" ]]; then
        matches="${SANDBOX_HELP_KEYWORDS[$keyword]}"
    fi

    # 2. Prefix/substring match in keyword map
    for kw in "${!SANDBOX_HELP_KEYWORDS[@]}"; do
        if [[ "$kw" != "$keyword" && ( "$kw" == "${keyword}"* || "$kw" == *"${keyword}"* ) ]]; then
            matches="$matches ${SANDBOX_HELP_KEYWORDS[$kw]}"
        fi
    done

    # 3. Fallback: scan SANDBOX_HELP_SHORT keys for action:resource containing the keyword
    if [[ -z "${matches// /}" ]]; then
        for cmd in "${!SANDBOX_HELP_SHORT[@]}"; do
            if [[ "$cmd" == *"$keyword"* ]]; then
                matches="$matches $cmd"
            fi
        done
    fi

    echo "$matches"
}

# ─── Helper: display help for a command ───────────────────────────────────────

_help_display_command() {
    local cmd="$1"  # Format: "action:resource" or just "action"
    local action="${cmd%%:*}"
    local resource="${cmd##*:}"
    
    if [[ "$resource" == "$action" ]]; then
        # Action-only help
        local desc="${SANDBOX_HELP_SHORT[$action]:-No description}"
        echo -e "  ${CYAN}sandbox ${action}${NC}  ${desc}"
    else
        # Action:resource help
        local desc="${SANDBOX_HELP_SHORT[$cmd]:-No description}"
        echo -e "  ${CYAN}sandbox ${action} ${resource}${NC}  ${desc}"
    fi
}

# ─── Determine search mode ─────────────────────────────────────────────────────

search_term=""

# If RESOURCE is "search", use PARAMS as the keyword
if [[ "$HELP_RESOURCE" == "search" ]]; then
    search_term="$HELP_KEYWORD"
fi

# ─── Display help ─────────────────────────────────────────────────────────────

if [[ -z "$search_term" ]]; then
    echo ""
    echo -e "  ${WHITE}Oracle Sandbox CLI${NC} — Command Reference"
    echo -e "  ${WHITE}─────────────────────────────────────────────────${NC}"
    echo ""

    for category_line in "${SANDBOX_HELP_CATEGORIES[@]}"; do
        category_name="${category_line%%:  *}"
        commands="${category_line#*:  }"

        echo -e "  ${YELLOW}${category_name}${NC}"
        for cmd in $commands; do
            action="${cmd%%:*}"
            resource="${cmd##*:}"
            desc="${SANDBOX_HELP_SHORT[$cmd]:-}"
            [[ -z "$desc" ]] && desc="${SANDBOX_HELP_SHORT[$action]:-}"
            if [[ "$resource" == "$action" ]]; then
                printf "    ${CYAN}%-18s${NC}  %s\n" "sb ${action}" "$desc"
            else
                printf "    ${CYAN}%-18s${NC}  %s\n" "sb ${action} ${resource}" "$desc"
            fi
        done
        echo ""
    done

    echo -e "  ${WHITE}Aliases${NC}"
    for alias in sb sr sc sl ss si sk sp sx; do
        target="${SANDBOX_ALIASES[$alias]:-}"
        [[ -n "$target" ]] && printf "    ${CYAN}%-4s${NC}  →  %s\n" "$alias" "$target"
    done
    echo ""
    echo -e "  ${WHITE}Tips${NC}"
    echo -e "    ${CYAN}sb help search <keyword>${NC}      Find commands by keyword"
    echo -e "    ${CYAN}sb <action> -h${NC}                Action-level help"
    echo -e "    ${CYAN}sb <action> <resource> -h${NC}     Resource-level help"
    echo ""
    
else
    # Search for keyword
    echo ""
    echo -e "  ${WHITE}Help Search${NC} — Results for: ${CYAN}${search_term}${NC}"
    echo ""
    
    results=$(_help_search_by_keyword "$search_term")
    
    if [[ -z "$results" ]]; then
        echo -e "  ${YELLOW}No commands found for '${search_term}'${NC}"
        echo ""
        echo -e "  ${WHITE}Try searching for:${NC}"
        echo -e "    ${CYAN}Connections:${NC}   sqlcl, conn, connection, mcp"
        echo -e "    ${CYAN}Services:${NC}      apex, ords, start, stop, restart"
        echo -e "    ${CYAN}Status:${NC}        status, health, healthcheck, network"
        echo -e "    ${CYAN}Logs:${NC}          logs, startup, debug, error"
        echo -e "    ${CYAN}Install:${NC}       install, download, deploy, setup"
        echo -e "    ${CYAN}Backup:${NC}        backup, restore, schemas, full"
        echo -e "    ${CYAN}Data:${NC}          export, import"
        echo -e "    ${CYAN}Audit:${NC}         audit, rollback"
        echo -e "    ${CYAN}Automation:${NC}    batch, template, monitor, script"
        echo ""
    else
        # Display results (deduplicate by checking if cmd already printed)
        declare -A seen
        result_count=0
        for cmd in $results; do
            if [[ -z "${seen[$cmd]:-}" ]]; then
                _help_display_command "$cmd"
                seen[$cmd]=1
                (( result_count++ ))
            fi
        done
        
        echo ""
        echo -e "  ${YELLOW}Found ${result_count} command(s). Use:${NC}"
        echo -e "    ${CYAN}sandbox <action> <resource> -h${NC}  for detailed help"
        echo ""
    fi
fi
