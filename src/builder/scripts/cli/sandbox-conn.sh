# ─── sandbox conn ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox conn <resource> [parameters]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

CONN_DIR="/root/.dbtools/connections"

# ── Helpers ───────────────────────────────────────────────────────────────────

_conn_list_names() {
    find "$CONN_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | xargs -I{} basename {}
}

_conn_props_file() {
    # SQLcl 26.x: ~/.dbtools/connections/<name>/dbtools.properties
    echo "${CONN_DIR}/${1}/dbtools.properties"
}

_conn_get_prop() {
    local props_file="$1" key="$2"
    grep -m1 "^${key}=" "$props_file" 2>/dev/null | cut -d= -f2-
}

# ── list ──────────────────────────────────────────────────────────────────────

_conn_do_list() {
    local names
    names=$(_conn_list_names)

    if [[ -z "$names" ]]; then
        log_info "No saved connections found."
        echo -e "  ${YELLOW}Tip:${NC} Use ${CYAN}sandbox conn add --name <name> --user <user> --pdb <PDB>${NC} to create one."
        echo ""
        return
    fi

    echo -e "  ${YELLOW}Saved connections:${NC}"
    echo ""
    while IFS= read -r name; do
        local props
        props=$(_conn_props_file "$name")
        if [[ -f "$props" ]]; then
            local url
            url=$(_conn_get_prop "$props" "db_url")
            echo -e "    ${CYAN}${name}${NC}  ${url}"
        else
            echo -e "    ${CYAN}${name}${NC}  ${YELLOW}(no properties file)${NC}"
        fi
    done <<< "$names"
    echo ""
}

# ── add ───────────────────────────────────────────────────────────────────────

_conn_do_add() {
    local CONN_NAME="" CONN_USER="" CONN_PASS="" CONN_HOST="" CONN_PORT="" CONN_PDB=""
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name|-name|-n)
                [[ -z "${2:-}" ]] && { log_error "--name requires a value"; exit 1; }
                CONN_NAME="$2"; shift 2 ;;
            --user|-u)
                [[ -z "${2:-}" ]] && { log_error "--user requires a value"; exit 1; }
                CONN_USER="$2"; shift 2 ;;
            --pass|-p)
                [[ -z "${2:-}" ]] && { log_error "--pass requires a value"; exit 1; }
                CONN_PASS="$2"; shift 2 ;;
            --host)
                [[ -z "${2:-}" ]] && { log_error "--host requires a value"; exit 1; }
                CONN_HOST="$2"; shift 2 ;;
            --port)
                [[ -z "${2:-}" ]] && { log_error "--port requires a value"; exit 1; }
                CONN_PORT="$2"; shift 2 ;;
            --pdb)
                [[ -z "${2:-}" ]] && { log_error "--pdb requires a value"; exit 1; }
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
                exit 1 ;;
        esac
    done

    [[ -z "$CONN_NAME" ]] && { log_error "sandbox conn add requires --name <name>"; exit 1; }
    [[ -z "$CONN_USER" ]] && { log_error "sandbox conn add requires --user <user>"; exit 1; }

    CONN_PASS="${CONN_PASS:-${DEMASYLABS_DB_PASSWORD}}"
    CONN_HOST="${CONN_HOST:-${DEMASYLABS_DB_HOST}}"
    CONN_PORT="${CONN_PORT:-${DEMASYLABS_DB_PORT}}"
    CONN_PDB="${CONN_PDB:-${DEMASYLABS_DB_SERVICE}}"

    log_step "Adding saved connection '${CONN_NAME}'..."
    echo -e "  ${YELLOW}User:${NC} ${CONN_USER}@${CONN_HOST}:${CONN_PORT}/${CONN_PDB}"
    echo ""

    /opt/oracle/sqlcl/bin/sql /nolog <<EOSQL
CONN -save "${CONN_NAME}" -savepwd ${CONN_USER}/${CONN_PASS}@//${CONN_HOST}:${CONN_PORT}/${CONN_PDB}
EXIT
EOSQL

    local props
    props=$(_conn_props_file "$CONN_NAME")
    if [[ -f "$props" ]]; then
        log_success "Connection '${CONN_NAME}' saved successfully."
    else
        log_error "Connection '${CONN_NAME}' was not saved — SQLcl may have reported an error above."
        exit 1
    fi
}

# ── delete ────────────────────────────────────────────────────────────────────

_conn_do_delete() {
    local CONN_NAME=""
    set -- $PARAMS
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name|-name|-n)
                [[ -z "${2:-}" ]] && { log_error "--name requires a value"; exit 1; }
                CONN_NAME="$2"; shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn delete"
                echo -e "  ${YELLOW}Parameters:${NC}  ${CYAN}--name${NC} <name>   Required. Connection name to delete"
                echo ""
                exit 1 ;;
        esac
    done

    [[ -z "$CONN_NAME" ]] && { log_error "sandbox conn delete requires --name <name>"; exit 1; }

    local conn_dir="${CONN_DIR}/${CONN_NAME}"
    if [[ ! -d "$conn_dir" ]]; then
        log_error "Connection '${CONN_NAME}' not found."
        echo -e "  ${YELLOW}Tip:${NC} Run ${CYAN}sandbox conn list${NC} to see available connections."
        echo ""
        exit 1
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
            --name|-name|-n)
                [[ -z "${2:-}" ]] && { log_error "--name requires a value"; exit 1; }
                CONN_NAME="$2"; shift 2 ;;
            *)
                log_error "Unknown parameter '${1}' for sandbox conn test"
                echo -e "  ${YELLOW}Parameters:${NC}  ${CYAN}--name${NC} <name>   Required. Connection name to test"
                echo ""
                exit 1 ;;
        esac
    done

    [[ -z "$CONN_NAME" ]] && { log_error "sandbox conn test requires --name <name>"; exit 1; }

    local props
    props=$(_conn_props_file "$CONN_NAME")
    if [[ ! -f "$props" ]]; then
        log_error "Connection '${CONN_NAME}' not found."
        echo -e "  ${YELLOW}Tip:${NC} Run ${CYAN}sandbox conn list${NC} to see available connections."
        echo ""
        exit 1
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
        exit 1
    fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    list)    _conn_do_list ;;
    add)     _conn_do_add ;;
    delete)  _conn_do_delete ;;
    test)    _conn_do_test ;;
esac
