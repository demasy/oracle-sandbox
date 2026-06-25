# ─── sandbox shell ────────────────────────────────────────────────────────────
# Interactive REPL for the Sandbox CLI
# Usage: sandbox shell or sb shell
# Features: Command history, line editing, help
# ─────────────────────────────────────────────────────────────────────────────

source /usr/sandbox/app/system/utils/colors.sh
source /usr/sandbox/app/system/utils/logging.sh
source /usr/sandbox/app/system/cli/sandbox-config.sh

HISTORY_FILE="${HOME}/.sandbox_history"
SHELL_PROMPT="${CYAN}sandbox>${NC} "

# Initialize history file
touch "$HISTORY_FILE" 2>/dev/null || true

print_demasy_banner "Sandbox Interactive Shell"
echo ""
echo -e "  ${YELLOW}Type${NC} ${CYAN}help${NC} ${YELLOW}for available commands, or${NC} ${CYAN}quit${NC} ${YELLOW}to exit${NC}"
echo ""

# Simple REPL loop
while true; do
    # Read command
    read -e -p "$(echo -ne "$SHELL_PROMPT")" -r cmd

    # Handle empty input
    [[ -z "$cmd" ]] && continue

    # Add to history
    echo "$cmd" >> "$HISTORY_FILE"

    # Handle special commands
    case "$cmd" in
        quit|exit)
            echo -e "  ${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        help)
            echo ""
            echo -e "  ${YELLOW}Sandbox Shell Commands:${NC}"
            echo -e "    ${CYAN}help${NC}                    Show this help"
            echo -e "    ${CYAN}history${NC}                Show command history"
            echo -e "    ${CYAN}history clear${NC}         Clear history"
            echo -e "    ${CYAN}history search <keyword>${NC} Search history"
            echo -e "    ${CYAN}status${NC}                 Run: sandbox status (all resources)"
            echo -e "    ${CYAN}conn list${NC}              Run: sandbox conn list"
            echo -e "    ${CYAN}logs <resource>{{NC}       Run: sandbox logs <resource>"
            echo -e "    ${CYAN}quit | exit{{NC}           Exit the shell"
            echo ""
            echo -e "  ${YELLOW}Sandbox commands:${NC}"
            echo -e "    Any ${CYAN}sandbox${NC} command without the prefix (e.g., ${CYAN}run sqlcl${NC})"
            echo ""
            ;;
        history)
            echo ""
            tail -20 "$HISTORY_FILE" | nl -v1
            echo ""
            ;;
        history\ clear)
            > "$HISTORY_FILE"
            echo -e "  ${GREEN}History cleared${NC}"
            echo ""
            ;;
        history\ search\ *)
            keyword="${cmd#history search }"
            echo ""
            grep "$keyword" "$HISTORY_FILE" | nl -v1
            echo ""
            ;;
        status|status\ *)
            # Run: sandbox status [args]
            sandbox status ${cmd#status} 2>&1
            echo ""
            ;;
        conn\ list)
            # Run: sandbox conn list
            sandbox conn list 2>&1
            echo ""
            ;;
        logs\ *)
            # Run: sandbox logs <resource>
            resource="${cmd#logs }"
            sandbox logs "$resource" 2>&1
            echo ""
            ;;
        run\ *|start\ *|stop\ *|restart\ *|install\ *|download\ *)
            # Pass through to sandbox command
            sandbox $cmd 2>&1
            echo ""
            ;;
        *)
            # Try to pass through as sandbox command
            if [[ "$cmd" =~ ^[a-z]+(\s|$) ]]; then
                sandbox $cmd 2>&1
                echo ""
            else
                echo -e "  ${RED}Unknown command:${NC} $cmd"
                echo -e "  ${YELLOW}Type${NC} ${CYAN}help${NC} ${YELLOW}for available commands${NC}"
                echo ""
            fi
            ;;
    esac
done
