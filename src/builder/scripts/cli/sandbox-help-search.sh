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
    
    # Check if keyword exists in SANDBOX_HELP_KEYWORDS
    if [[ -n "${SANDBOX_HELP_KEYWORDS[$keyword]:-}" ]]; then
        matches="${SANDBOX_HELP_KEYWORDS[$keyword]}"
    else
        # Fuzzy match against keywords (prefix match)
        for kw in "${!SANDBOX_HELP_KEYWORDS[@]}"; do
            if [[ "$kw" == "${keyword}"* || "$kw" == *"${keyword}"* ]]; then
                matches="$matches ${SANDBOX_HELP_KEYWORDS[$kw]}"
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
    # No search term — show all categories
    echo ""
    echo -e "  ${WHITE}Sandbox CLI Help${NC} — Commands by category"
    echo ""
    
    for category_line in "${SANDBOX_HELP_CATEGORIES[@]}"; do
        category_name="${category_line%%:*}"
        commands="${category_line##*:}"
        
        echo -e "  ${YELLOW}${category_name}${NC}"
        for cmd in $commands; do
            _help_display_command "$cmd"
        done
        echo ""
    done
    
    echo -e "  ${WHITE}Aliases:${NC}"
    for alias in "${!SANDBOX_ALIASES[@]}"; do
        target="${SANDBOX_ALIASES[$alias]}"
        echo -e "    ${CYAN}${alias}${NC} → ${target}"
    done
    echo ""
    echo -e "  ${WHITE}Usage:${NC}"
    echo -e "    ${CYAN}sandbox help${NC}                        Show this help"
    echo -e "    ${CYAN}sandbox help search <keyword>${NC}        Find commands by keyword"
    echo -e "    ${CYAN}sandbox <action> -h${NC}                  Show action help"
    echo -e "    ${CYAN}sandbox <action> <resource> -h${NC}       Show resource help"
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
        echo -e "    sql, database, connection, connect, mcp, apex, ords"
        echo -e "    web, http, start, stop, restart, service"
        echo -e "    status, health, monitor, dashboard, performance"
        echo -e "    log, logs, debug, error, trace"
        echo -e "    install, setup, deploy"
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
