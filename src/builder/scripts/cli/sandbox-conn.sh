# ─── sandbox conn ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox conn <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Dependencies: sandbox-params.sh
# ─────────────────────────────────────────────────────────────────────────────

CONN_DIR="${HOME:-/home/sandbox}/.dbtools/connections"

# ── Helpers ───────────────────────────────────────────────────────────────────

# SQLcl stores connections in hashed subdirs — find by name= property
_conn_find_dir() {
    local name="$1"
    grep -rl "^name=${name}$" "${CONN_DIR}" 2>/dev/null | head -1 | xargs -I{} dirname {}
}

_conn_get_prop() {
    local props_file="$1" key="$2"
    grep -m1 "^${key}=" "$props_file" 2>/dev/null | cut -d= -f2-
}

# ── list ──────────────────────────────────────────────────────────────────────

_conn_do_list() {
    # Parse --format flag
    _parse_output_format $PARAMS
    
    local props_files
    props_files=$(find "$CONN_DIR" -name "dbtools.properties" 2>/dev/null | sort)

    if [[ -z "$props_files" ]]; then
        local setup_log="/tmp/auto-user-setup.log"
        if [[ -f "$setup_log" ]] && ! grep -q "Auto-user setup complete" "$setup_log" 2>/dev/null; then
            log_info "Setup still in progress — connections will be available shortly."
            echo -e "  ${YELLOW}Tip:${NC} Monitor progress with: ${CYAN}tail -f ${setup_log}${NC}"
        else
            log_info "No saved connections found."
            echo -e "  ${YELLOW}Tip:${NC} Use ${CYAN}sandbox conn add --name <name> --user <user> --pdb <PDB>${NC} to create one."
        fi
        echo ""
        return
    fi

    # Collect connections into array
    local -a conn_names conn_users conn_strings
    local count=0
    
    while IFS= read -r props; do
        local name user conn_str
        name=$(_conn_get_prop "$props" "name")
        user=$(_conn_get_prop "$props" "userName")
        conn_str=$(_conn_get_prop "$props" "connectionString")
        
        conn_names[$count]="$name"
        conn_users[$count]="$user"
        conn_strings[$count]="$conn_str"
        ((count++))
    done <<< "$props_files"

    # Output in requested format
    case "$OUTPUT_FORMAT" in
        json)
            printf "{\n"
            printf "  \"connections\": [\n"
            for i in "${!conn_names[@]}"; do
                [[ $i -gt 0 ]] && printf ",\n"
                printf "    {\n"
                printf "      \"name\": \"%s\",\n" "${conn_names[$i]}"
                printf "      \"user\": \"%s\",\n" "${conn_users[$i]}"
                printf "      \"connection\": \"%s\"\n" "${conn_strings[$i]}"
                printf "    }"
            done
            printf "\n  ]\n"
            printf "}\n"
            ;;
        csv)
            printf "name,user,connection\n"
            for i in "${!conn_names[@]}"; do
                printf "%s,%s,%s\n" "${conn_names[$i]}" "${conn_users[$i]}" "${conn_strings[$i]}"
            done
            ;;
        *)
            # Default table format
            echo -e "  ${YELLOW}Saved connections:${NC}"
            echo ""
            for i in "${!conn_names[@]}"; do
                echo -e "    ${CYAN}${conn_names[$i]}${NC}   ${conn_users[$i]}@${conn_strings[$i]}"
            done
            echo ""
            ;;
    esac
}

# ── add ───────────────────────────────────────────────────────────────────────

_conn_do_add() {
    local CONN_NAME="" CONN_USER="" CONN_PASS="" CONN_HOST="" CONN_PORT="" CONN_PDB=""
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name|-n)
                _parse_flag_with_value "$1" "${2:-}" CONN_NAME || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            --user|-u)
                _parse_flag_with_value "$1" "${2:-}" CONN_USER || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            --pass|-p)
                _parse_flag_with_value "$1" "${2:-}" CONN_PASS "optional" || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            --host)
                _parse_flag_with_value "$1" "${2:-}" CONN_HOST "optional" || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            --port)
                _parse_flag_with_value "$1" "${2:-}" CONN_PORT "optional" || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            --pdb)
                _parse_flag_with_value "$1" "${2:-}" CONN_PDB "optional" || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn add"
                _show_param_help "--name|-n" "<name>" "Required. Connection name"
                _show_param_help "--user|-u" "<user>" "Required. Database user"
                _show_param_help "--pass|-p" "<password>" "Optional. Default: env password"
                _show_param_help "--host" "<host>" "Optional. Default: ${SANDBOX_DB_HOST}"
                _show_param_help "--port" "<port>" "Optional. Default: ${SANDBOX_DB_PORT}"
                _show_param_help "--pdb" "<PDB name>" "Optional. Default: ${SANDBOX_DB_SERVICE}"
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    _require_param_flag "$CONN_NAME" "--name" "sandbox conn add" || exit ${EXIT_USAGE:-1}
    _require_param_flag "$CONN_USER" "--user" "sandbox conn add" || exit ${EXIT_USAGE:-1}

    CONN_PASS="${CONN_PASS:-${SANDBOX_DB_PASSWORD}}"
    CONN_HOST="${CONN_HOST:-${SANDBOX_DB_HOST}}"
    CONN_PORT="${CONN_PORT:-${SANDBOX_DB_PORT}}"
    CONN_PDB="${CONN_PDB:-${SANDBOX_DB_SERVICE}}"

    _if_dry_run "Would save connection: ${CONN_NAME} → ${CONN_USER}@${CONN_HOST}:${CONN_PORT}/${CONN_PDB}" && return

    # Remove existing connection with the same name so SQLcl won't refuse
    _existing=$(_conn_find_dir "$CONN_NAME")
    if [[ -n "$_existing" ]]; then
        log_info "Replacing existing connection '${CONN_NAME}'..."
        rm -rf "$_existing"
    fi

    log_step "Adding saved connection '${CONN_NAME}'..."
    echo -e "  ${YELLOW}User:${NC} ${CONN_USER}@${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
    echo ""

    /opt/oracle/sqlcl/bin/sql /nolog <<EOSQL
CONN -save "${CONN_NAME}" -savepwd ${CONN_USER}/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}
EXIT
EOSQL

    if [[ -n "$(_conn_find_dir "$CONN_NAME")" ]]; then
        log_success "Connection '${CONN_NAME}' saved successfully."
    else
        log_error "Connection '${CONN_NAME}' was not saved — SQLcl may have reported an error above."
        exit ${EXIT_DB:-2}
    fi
}

# ── delete ────────────────────────────────────────────────────────────────────

_conn_do_delete() {
    local CONN_NAME=""
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name|-n)
                _parse_flag_with_value "$1" "${2:-}" CONN_NAME || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn delete"
                _show_param_help "--name|-n" "<name>" "Required. Connection name to delete"
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    _require_param_flag "$CONN_NAME" "--name" "sandbox conn delete" || exit ${EXIT_USAGE:-1}

    local conn_dir
    conn_dir=$(_conn_find_dir "$CONN_NAME")
    if [[ -z "$conn_dir" ]]; then
        log_error "Connection '${CONN_NAME}' not found."
        echo -e "  ${YELLOW}Tip:${NC} Run ${CYAN}sandbox conn list${NC} to see available connections."
        echo ""
        exit ${EXIT_USAGE:-1}
    fi

    _if_dry_run "Would delete connection: ${CONN_NAME} (${conn_dir})" && return

    rm -rf "$conn_dir"
    log_success "Connection '${CONN_NAME}' deleted."
}

# ── test ──────────────────────────────────────────────────────────────────────

_conn_do_test() {
    local CONN_NAME=""
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name|-n)
                _parse_flag_with_value "$1" "${2:-}" CONN_NAME || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn test"
                _show_param_help "--name|-n" "<name>" "Required. Connection name to test"
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    _require_param_flag "$CONN_NAME" "--name" "sandbox conn test" || exit ${EXIT_USAGE:-1}

    local conn_dir
    conn_dir=$(_conn_find_dir "$CONN_NAME")
    if [[ -z "$conn_dir" ]]; then
        log_error "Connection '${CONN_NAME}' not found."
        echo -e "  ${YELLOW}Tip:${NC} Run ${CYAN}sandbox conn list${NC} to see available connections."
        echo ""
        exit ${EXIT_USAGE:-1}
    fi

    log_step "Testing connection '${CONN_NAME}'..."

    local result
    result=$(echo "SELECT 'OK' FROM DUAL; EXIT" | \
        /opt/oracle/sqlcl/bin/sql -name "${CONN_NAME}" 2>&1)

    if echo "$result" | grep -q "^OK$\|'OK'"; then
        log_success "Connection '${CONN_NAME}' is working."
    else
        log_error "Connection '${CONN_NAME}' failed."
        echo "$result" | tail -10
        echo ""
        exit ${EXIT_DB:-2}
    fi
}

# ── rename ────────────────────────────────────────────────────────────────────

_conn_do_rename() {
    local CONN_FROM="" CONN_TO=""
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from|-f)
                _parse_flag_with_value "$1" "${2:-}" CONN_FROM || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            --to|-t)
                _parse_flag_with_value "$1" "${2:-}" CONN_TO || exit ${EXIT_USAGE:-1}
                shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn rename"
                _show_param_help "--from|-f" "<name>" "Required. Current connection name"
                _show_param_help "--to|-t" "<name>" "Required. New connection name"
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    _require_param_flag "$CONN_FROM" "--from" "sandbox conn rename" || exit ${EXIT_USAGE:-1}
    _require_param_flag "$CONN_TO" "--to" "sandbox conn rename" || exit ${EXIT_USAGE:-1}

    local conn_dir
    conn_dir=$(_conn_find_dir "$CONN_FROM")
    if [[ -z "$conn_dir" ]]; then
        log_error "Connection '${CONN_FROM}' not found."
        echo -e "  ${YELLOW}Tip:${NC} Run ${CYAN}sandbox conn list${NC} to see available connections."
        echo ""
        exit ${EXIT_USAGE:-1}
    fi

    if [[ -n "$(_conn_find_dir "$CONN_TO")" ]]; then
        log_error "A connection named '${CONN_TO}' already exists. Delete it first."
        exit ${EXIT_USAGE:-1}
    fi

    local props="${conn_dir}/dbtools.properties"
    sed -i "s/^name=${CONN_FROM}$/name=${CONN_TO}/" "$props"
    log_success "Connection renamed: '${CONN_FROM}' → '${CONN_TO}'"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    list)    _conn_do_list ;;
    add)     _conn_do_add ;;
    delete)  _conn_do_delete ;;
    test)    _conn_do_test ;;
    rename)  _conn_do_rename ;;
esac
