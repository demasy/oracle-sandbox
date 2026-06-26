# ─── sandbox restore ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox restore [connections|ords|config|schemas] --from <backup-id>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

source /usr/sandbox/app/system/utils/paths.sh

BACKUP_BASE="${SANDBOX_BACKUP_DIR:-/tmp/sandbox/backups}"

# Parse --from <backup-id> from PARAMS
_RESTORE_FROM=""
set -- $PARAMS
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--from" && -n "${2:-}" ]]; then
        _RESTORE_FROM="$2"
        shift 2
    else
        shift
    fi
done

_restore_resolve_dir() {
    if [[ -z "$_RESTORE_FROM" ]]; then
        # Default to most recent backup
        _RESTORE_FROM=$(ls -1t "$BACKUP_BASE" 2>/dev/null | head -1)
        if [[ -z "$_RESTORE_FROM" ]]; then
            log_error "No backups found in ${BACKUP_BASE}. Run 'sandbox backup' first."
            exit 1
        fi
        log_info "No --from specified, using latest: ${_RESTORE_FROM}"
    fi
    RESTORE_DIR="${BACKUP_BASE}/${_RESTORE_FROM}"
    if [[ ! -d "$RESTORE_DIR" ]]; then
        log_error "Backup not found: ${RESTORE_DIR}"
        log_info "Run 'sandbox backup list' to see available backups."
        exit 1
    fi
}

# ── connections ───────────────────────────────────────────────────────────────
_restore_connections() {
    _restore_resolve_dir
    local src="$RESTORE_DIR/connections"
    if [[ ! -d "$src" ]]; then
        log_error "No connections backup found in ${RESTORE_DIR}"
        return 1
    fi
    log_step "Restoring connections from ${_RESTORE_FROM}..."
    mkdir -p "$SANDBOX_CONNECTIONS"
    cp -r "$src"/. "$SANDBOX_CONNECTIONS/"
    local count=$(find "$SANDBOX_CONNECTIONS" -name "*.properties" | wc -l | xargs)
    log_success "Connections restored ($count file(s)) → ${SANDBOX_CONNECTIONS}"
}

# ── ords config ───────────────────────────────────────────────────────────────
_restore_ords() {
    _restore_resolve_dir
    local src="$RESTORE_DIR/ords-config"
    if [[ ! -d "$src" || -z "$(ls -A "$src" 2>/dev/null)" ]]; then
        log_error "No ORDS config backup found in ${RESTORE_DIR}"
        return 1
    fi
    log_step "Restoring ORDS configuration from ${_RESTORE_FROM}..."
    mkdir -p "$ORACLE_ORDS_CONFIG"
    cp -r "$src"/. "$ORACLE_ORDS_CONFIG/"
    log_success "ORDS config restored → ${ORACLE_ORDS_CONFIG}"
    log_info "Restart ORDS for changes to take effect: sandbox run ords"
}

# ── sandbox config ────────────────────────────────────────────────────────────
_restore_config() {
    _restore_resolve_dir
    local src="$RESTORE_DIR/config/env-config.json"
    if [[ ! -f "$src" ]]; then
        log_error "No config backup found in ${RESTORE_DIR}"
        return 1
    fi
    log_step "Restoring sandbox configuration from ${_RESTORE_FROM}..."
    sandbox import config --file "$src" 2>/dev/null && \
        log_success "Config restored from ${src}" || \
        log_warning "Config restore encountered issues — check manually"
}

# ── oracle schemas via Data Pump ──────────────────────────────────────────────
_restore_schemas() {
    _restore_resolve_dir
    local logfile="$RESTORE_DIR/datapump/datapump.log"
    log_step "Restoring Oracle schemas via Data Pump..."

    if [[ -z "$SANDBOX_DB_HOST" || -z "$SANDBOX_DB_PASS" ]]; then
        log_error "SANDBOX_DB_HOST / SANDBOX_DB_PASS not set — cannot run Data Pump"
        return 1
    fi

    # Find the dump file name from the manifest or datapump log
    local dumpfile=$(grep -oP 'sandbox_backup_\S+\.dmp' "$logfile" 2>/dev/null | head -1)
    if [[ -z "$dumpfile" ]]; then
        dumpfile="sandbox_backup_${_RESTORE_FROM}.dmp"
    fi

    log_info "Importing dump: ${dumpfile} (must exist in DATA_PUMP_DIR on DB host)"

    local impdp_sql="HOST impdp system/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT:-1521}/${SANDBOX_DB_SERVICE:-FREEPDB1} SCHEMAS=SANDBOX_AI DIRECTORY=DATA_PUMP_DIR DUMPFILE=${dumpfile} LOGFILE=impdp_restore.log TABLE_EXISTS_ACTION=REPLACE"
    echo "$impdp_sql" | sql -S "system/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT:-1521}/${SANDBOX_DB_SERVICE:-FREEPDB1}" 2>&1
    local rc=$?
    [[ $rc -eq 0 ]] && log_success "Schema restore completed" || log_warning "Schema restore may have issues — check impdp_restore.log on DB host"
    return $rc
}

# ─── dispatch ─────────────────────────────────────────────────────────────────
case "${RESOURCE:-}" in
    connections)
        _restore_connections ;;
    ords)
        _restore_ords ;;
    config)
        _restore_config ;;
    schemas)
        _restore_schemas ;;
    full)
        _restore_resolve_dir
        log_step "Full restore from ${_RESTORE_FROM}..."
        _restore_connections
        _restore_ords
        _restore_config
        _restore_schemas
        log_success "Full restore complete"
        ;;
    "")
        log_error "Missing resource for sandbox restore"
        echo -e "  ${YELLOW}Valid resources:${NC} full | connections | ords | config | schemas"
        echo -e "  ${YELLOW}Usage:${NC} sandbox restore <resource> [--from <backup-id>]"
        echo -e "  ${YELLOW}Example:${NC} sandbox restore full --from 20260626-210000"
        exit 1
        ;;
    *)
        log_error "Unknown resource '${RESOURCE}' for sandbox restore"
        echo -e "  ${YELLOW}Valid resources:${NC} full | connections | ords | config | schemas"
        exit 1
        ;;
esac
