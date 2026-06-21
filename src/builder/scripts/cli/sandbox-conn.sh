# ─── sandbox conn ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox conn <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
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

    echo -e "  ${YELLOW}Saved connections:${NC}"
    echo ""
    while IFS= read -r props; do
        local name user conn_str
        name=$(_conn_get_prop "$props" "name")
        user=$(_conn_get_prop "$props" "userName")
        conn_str=$(_conn_get_prop "$props" "connectionString")
        echo -e "    ${CYAN}${name}${NC}   ${user}@${conn_str}"
    done <<< "$props_files"
    echo ""
}

# ── add ───────────────────────────────────────────────────────────────────────

_conn_do_add() {
    local CONN_NAME="" CONN_USER="" CONN_PASS="" CONN_HOST="" CONN_PORT="" CONN_PDB=""
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name|-n)
                [[ -z "${2:-}" ]] && { log_error "--name requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_NAME="$2"; shift 2 ;;
            --user|-u)
                [[ -z "${2:-}" ]] && { log_error "--user requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_USER="$2"; shift 2 ;;
            --pass|-p)
                [[ -z "${2:-}" ]] && { log_error "--pass requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_PASS="$2"; shift 2 ;;
            --host)
                [[ -z "${2:-}" ]] && { log_error "--host requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_HOST="$2"; shift 2 ;;
            --port)
                [[ -z "${2:-}" ]] && { log_error "--port requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_PORT="$2"; shift 2 ;;
            --pdb)
                [[ -z "${2:-}" ]] && { log_error "--pdb requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_PDB="$2"; shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn add"
                echo -e "  ${YELLOW}Parameters:${NC}"
                echo -e "    ${CYAN}--name${NC}  <name>       Required. Connection name"
                echo -e "    ${CYAN}--user${NC}  <user>       Required. Database user"
                echo -e "    ${CYAN}--pass${NC}  <password>   Optional. Default: env password"
                echo -e "    ${CYAN}--host${NC}  <host>       Optional. Default: ${DEMASYLABS_DB_HOST}"
                echo -e "    ${CYAN}--port${NC}  <port>       Optional. Default: ${DEMASYLABS_DB_PORT}"
                echo -e "    ${CYAN}--pdb${NC}   <PDB name>   Optional. Default: ${DEMASYLABS_DB_SERVICE}"
                echo ""
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    [[ -z "$CONN_NAME" ]] && { log_error "sandbox conn add requires --name <name>"; exit ${EXIT_USAGE:-1}; }
    [[ -z "$CONN_USER" ]] && { log_error "sandbox conn add requires --user <user>"; exit ${EXIT_USAGE:-1}; }

    CONN_PASS="${CONN_PASS:-${DEMASYLABS_DB_PASSWORD}}"
    CONN_HOST="${CONN_HOST:-${DEMASYLABS_DB_HOST}}"
    CONN_PORT="${CONN_PORT:-${DEMASYLABS_DB_PORT}}"
    CONN_PDB="${CONN_PDB:-${DEMASYLABS_DB_SERVICE}}"

    if [[ "${SANDBOX_DRY_RUN:-0}" == "1" ]]; then
        log_info "[dry-run] Would save connection: ${CONN_NAME} → ${CONN_USER}@${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
        return
    fi

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
                [[ -z "${2:-}" ]] && { log_error "--name requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_NAME="$2"; shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn delete"
                echo -e "  ${YELLOW}Parameters:${NC}  ${CYAN}--name${NC} <name>   Required. Connection name to delete"
                echo ""
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    [[ -z "$CONN_NAME" ]] && { log_error "sandbox conn delete requires --name <name>"; exit ${EXIT_USAGE:-1}; }

    local conn_dir
    conn_dir=$(_conn_find_dir "$CONN_NAME")
    if [[ -z "$conn_dir" ]]; then
        log_error "Connection '${CONN_NAME}' not found."
        echo -e "  ${YELLOW}Tip:${NC} Run ${CYAN}sandbox conn list${NC} to see available connections."
        echo ""
        exit ${EXIT_USAGE:-1}
    fi

    if [[ "${SANDBOX_DRY_RUN:-0}" == "1" ]]; then
        log_info "[dry-run] Would delete connection: ${CONN_NAME} (${conn_dir})"
        return
    fi

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
                [[ -z "${2:-}" ]] && { log_error "--name requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_NAME="$2"; shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn test"
                echo -e "  ${YELLOW}Parameters:${NC}  ${CYAN}--name${NC} <name>   Required. Connection name to test"
                echo ""
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    [[ -z "$CONN_NAME" ]] && { log_error "sandbox conn test requires --name <name>"; exit ${EXIT_USAGE:-1}; }

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
                [[ -z "${2:-}" ]] && { log_error "--from requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_FROM="$2"; shift 2 ;;
            --to|-t)
                [[ -z "${2:-}" ]] && { log_error "--to requires a value"; exit ${EXIT_USAGE:-1}; }
                CONN_TO="$2"; shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn rename"
                echo -e "  ${YELLOW}Parameters:${NC}"
                echo -e "    ${CYAN}--from${NC}  <name>   Required. Current connection name"
                echo -e "    ${CYAN}--to${NC}    <name>   Required. New connection name"
                echo ""
                exit ${EXIT_USAGE:-1} ;;
        esac
    done

    [[ -z "$CONN_FROM" ]] && { log_error "sandbox conn rename requires --from <name>"; exit ${EXIT_USAGE:-1}; }
    [[ -z "$CONN_TO" ]]   && { log_error "sandbox conn rename requires --to <name>"; exit ${EXIT_USAGE:-1}; }

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
