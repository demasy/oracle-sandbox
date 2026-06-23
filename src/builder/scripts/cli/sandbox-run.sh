# ─── sandbox run ──────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox run <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Dependencies: sandbox-params.sh, sandbox-menu.sh
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    sqlcl)
        SQLCL_USER="" SQLCL_PASS="" SQLCL_PDB=""
        set -- $PARAMS
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -u|--user)
                    _parse_flag_with_value "$1" "${2:-}" SQLCL_USER || exit ${EXIT_USAGE:-1}
                    shift 2 ;;
                -p|--pass)
                    _parse_flag_with_value "$1" "${2:-}" SQLCL_PASS || exit ${EXIT_USAGE:-1}
                    shift 2 ;;
                --pdb)
                    _parse_flag_with_value "$1" "${2:-}" SQLCL_PDB || exit ${EXIT_USAGE:-1}
                    shift 2 ;;
                *)
                    log_error "Unknown parameter '${1}' for sandbox run sqlcl"
                    _show_param_help "-u|--user" "<user>" "Required. One of: ${VALID_SQLCL_USERS}"
                    _show_param_help "-p|--pass" "<password>" "Optional. Default: Default Password"
                    _show_param_help "--pdb" "<PDB name>" "Optional. Override the default PDB"
                    exit ${EXIT_USAGE:-1} ;;
            esac
        done

        # Prompt for user if not provided
        if [[ -z "$SQLCL_USER" ]]; then
            echo ""
            echo -e "  ${YELLOW}Select a user:${NC}"
            echo ""
            _idx=1
            _u=""
            _choice=""
            for _u in $VALID_SQLCL_USERS; do
                echo -e "    ${CYAN}${_idx})${NC} ${_u}"
                _idx=$(( _idx + 1 ))
            done
            echo ""
            printf "  Enter number: "
            read -r _choice
            echo ""
            _idx=1
            for _u in $VALID_SQLCL_USERS; do
                [[ "$_idx" == "$_choice" ]] && SQLCL_USER="$_u" && break
                _idx=$(( _idx + 1 ))
            done
            if [[ -z "$SQLCL_USER" ]]; then
                log_error "Invalid selection"
                exit ${EXIT_USAGE:-1}
            fi
        fi

        # Validate user is in allowed list
        declare -a users=($VALID_SQLCL_USERS)
        valid_user=false
        for u in "${users[@]}"; do
            [[ "$u" == "$SQLCL_USER" ]] && valid_user=true && break
        done
        if [[ "$valid_user" != "true" ]]; then
            log_error "Unknown user '${SQLCL_USER}' for sandbox run sqlcl"
            echo -e "  ${YELLOW}Valid users:${NC} ${CYAN}${VALID_SQLCL_USERS}${NC}"
            echo ""
            exit ${EXIT_USAGE:-1}
        fi

        CONN_PASS="${SQLCL_PASS:-${SANDBOX_DB_PASSWORD}}"
        CONN_HOST="sandbox-oracle-database"
        CONN_PORT="${SANDBOX_DB_PORT}"

        case "$SQLCL_USER" in
            sys)
                CONN_PDB="${SQLCL_PDB:-${SANDBOX_DB_SERVICE}}"
                log_step "Connecting as SYS (sysdba) @ ${CONN_PDB}..."
                sql "sys/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}" as sysdba
                ;;
            system)
                CONN_PDB="${SQLCL_PDB:-${SANDBOX_DB_SERVICE}}"
                log_step "Connecting as SYSTEM @ ${CONN_PDB}..."
                sql "system/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
                ;;
            sandbox)
                CONN_PDB="${SQLCL_PDB:-SANDBOX_PDB}"
                log_step "Connecting as SANDBOX @ ${CONN_PDB}..."
                sql "sandbox/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
                ;;
            sandbox_ai)
                CONN_PDB="${SQLCL_PDB:-SANDBOX_PDB}"
                log_step "Connecting as SANDBOX_AI (AI/MCP user) @ ${CONN_PDB}..."
                sql "sandbox_ai/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
                ;;
            demasy)
                CONN_PDB="${SQLCL_PDB:-DEMASY_PDB}"
                log_step "Connecting as DEMASY @ ${CONN_PDB}..."
                sql "demasy/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
                ;;
            demasy_ai)
                CONN_PDB="${SQLCL_PDB:-DEMASY_PDB}"
                log_step "Connecting as DEMASY_AI (AI/MCP user) @ ${CONN_PDB}..."
                sql "demasy_ai/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
                ;;
        esac
        ;;
    mcp)
        log_step "Starting MCP server (foreground)..."
        bash /usr/sandbox/app/oracle/mcp/start-mcp-with-saved-connection.sh
        ;;
    healthcheck)
        log_step "Running healthcheck..."
        bash /usr/sandbox/app/system/admin/healthcheck.sh
        ;;
    monitor)
        # Get available monitoring scripts
        MONITOR_SCRIPT="${PARAMS%% *}"
        MONITOR_DIR="/usr/sandbox/app/oracle/admin/monitoring"
        
        if [[ -z "$MONITOR_SCRIPT" ]]; then
            echo ""
            echo -e "  ${YELLOW}Available monitoring scripts:${NC}"
            echo ""
            if [[ -d "$MONITOR_DIR" ]]; then
                _idx=1
                for _script in "$MONITOR_DIR"/*.sql; do
                    _name=$(basename "$_script" .sql)
                    echo -e "    ${CYAN}${_idx})${NC} ${_name}"
                    _idx=$(( _idx + 1 ))
                done
                echo ""
                echo -e "  ${YELLOW}Usage:${NC} ${CYAN}sandbox run monitor <script-name>${NC}"
                echo -e "  ${YELLOW}Example:${NC} ${CYAN}sandbox run monitor active-connections${NC}"
                echo ""
            else
                log_error "Monitoring scripts directory not found: $MONITOR_DIR"
                exit 1
            fi
        else
            # Execute monitoring script
            SCRIPT_FILE="${MONITOR_DIR}/${MONITOR_SCRIPT}.sql"
            
            if [[ ! -f "$SCRIPT_FILE" ]]; then
                echo ""
                log_error "Monitoring script not found: ${MONITOR_SCRIPT}"
                echo -e "  ${YELLOW}Available scripts:${NC}"
                ls -1 "$MONITOR_DIR"/*.sql | xargs -n1 basename -s .sql
                echo ""
                exit 1
            fi
            
            log_step "Running monitoring script: ${MONITOR_SCRIPT}..."
            log_info "Location: ${SCRIPT_FILE}"
            echo ""
            
            # Execute as SYSTEM user
            CONN_PASS="${SANDBOX_DB_PASSWORD}"
            CONN_HOST="sandbox-oracle-database"
            CONN_PORT="${SANDBOX_DB_PORT}"
            CONN_PDB="${SANDBOX_DB_SERVICE}"
            
            sql "system/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}" <<EOF
@${SCRIPT_FILE}
exit
EOF
        fi
        ;;
esac
