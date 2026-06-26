# ─── sandbox backup ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox backup [full|config|connections|ords]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

source /usr/sandbox/app/system/utils/paths.sh

BACKUP_BASE="${SANDBOX_BACKUP_DIR:-/tmp/sandbox/backups}"
BACKUP_TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
BACKUP_DIR="${BACKUP_BASE}/${BACKUP_TIMESTAMP}"

_backup_init() {
    mkdir -p "$BACKUP_DIR"
}

# ── connections ───────────────────────────────────────────────────────────────
_backup_connections() {
    log_step "Backing up saved connections..."
    local dest="$BACKUP_DIR/connections"
    mkdir -p "$dest"

    if [[ -d "$SANDBOX_CONNECTIONS" ]]; then
        cp -r "$SANDBOX_CONNECTIONS"/. "$dest/"
        local count=$(find "$dest" -name "*.properties" | wc -l | xargs)
        log_success "Connections backed up ($count file(s)) → ${dest}"
    else
        log_warning "No connections directory found at $SANDBOX_CONNECTIONS"
    fi
}

# ── ords config ───────────────────────────────────────────────────────────────
_backup_ords() {
    log_step "Backing up ORDS configuration..."
    local dest="$BACKUP_DIR/ords-config"
    mkdir -p "$dest"

    if [[ -d "$ORACLE_ORDS_CONFIG" && -n "$(ls -A "$ORACLE_ORDS_CONFIG" 2>/dev/null)" ]]; then
        cp -r "$ORACLE_ORDS_CONFIG"/. "$dest/"
        log_success "ORDS config backed up → ${dest}"
    else
        log_warning "ORDS config is empty or not found — skipping"
    fi
}

# ── sandbox config (env + paths) ──────────────────────────────────────────────
_backup_config() {
    log_step "Backing up sandbox configuration..."
    local dest="$BACKUP_DIR/config"
    mkdir -p "$dest"

    # Export env config via sandbox export
    sandbox export config --format json > "$dest/env-config.json" 2>/dev/null && \
        log_success "Env config exported → ${dest}/env-config.json" || \
        log_warning "Could not export env config"
}

# ── oracle schemas via Data Pump ──────────────────────────────────────────────
_backup_schemas() {
    log_step "Running Oracle Data Pump export..."
    local dest="$BACKUP_DIR/datapump"
    mkdir -p "$dest"

    if [[ -z "$SANDBOX_DB_HOST" || -z "$SANDBOX_DB_PASS" ]]; then
        log_error "SANDBOX_DB_HOST / SANDBOX_DB_PASS not set — cannot run Data Pump"
        return 1
    fi

    local dumpfile="sandbox_backup_${BACKUP_TIMESTAMP}.dmp"
    local logfile="$dest/datapump.log"

    # expdp runs on the DB host; call it via sqlcl to avoid SSH dependency
    local expdp_sql="HOST expdp system/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT:-1521}/${SANDBOX_DB_SERVICE:-FREEPDB1} SCHEMAS=SANDBOX_AI DIRECTORY=DATA_PUMP_DIR DUMPFILE=${dumpfile} LOGFILE=expdp_${BACKUP_TIMESTAMP}.log REUSE_DUMPFILES=YES"
    echo "$expdp_sql" | sql -S "system/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT:-1521}/${SANDBOX_DB_SERVICE:-FREEPDB1}" > "$logfile" 2>&1
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        log_success "Data Pump export completed → check DATA_PUMP_DIR on the DB host"
        log_info "Log: $logfile"
    else
        log_warning "Data Pump export may have issues — check $logfile"
    fi
    return $rc
}

# ── write manifest ─────────────────────────────────────────────────────────────
_backup_manifest() {
    cat > "$BACKUP_DIR/manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "backup_id": "${BACKUP_TIMESTAMP}",
  "host": "$(hostname)",
  "user": "${USER:-sandbox}",
  "components": $(printf '%s\n' "$@" | jq -R . | jq -s .)
}
EOF
    log_info "Manifest written → ${BACKUP_DIR}/manifest.json"
}

# ─── dispatch ─────────────────────────────────────────────────────────────────
case "${RESOURCE:-full}" in
    full)
        _backup_init
        _backup_connections
        _backup_ords
        _backup_config
        _backup_schemas
        _backup_manifest "connections" "ords" "config" "schemas"
        log_success "Full backup complete → ${BACKUP_DIR}"
        ;;
    connections)
        _backup_init
        _backup_connections
        _backup_manifest "connections"
        log_success "Connections backup complete → ${BACKUP_DIR}"
        ;;
    ords)
        _backup_init
        _backup_ords
        _backup_manifest "ords"
        log_success "ORDS backup complete → ${BACKUP_DIR}"
        ;;
    config)
        _backup_init
        _backup_config
        _backup_manifest "config"
        log_success "Config backup complete → ${BACKUP_DIR}"
        ;;
    schemas)
        _backup_init
        _backup_schemas
        _backup_manifest "schemas"
        log_success "Schema backup complete → ${BACKUP_DIR}"
        ;;
    list)
        if [[ -d "$BACKUP_BASE" ]]; then
            echo ""
            echo -e "  ${CYAN}Available backups in ${BACKUP_BASE}:${NC}"
            echo ""
            for d in "$BACKUP_BASE"/*/; do
                [[ -d "$d" ]] || continue
                local bname=$(basename "$d")
                local manifest="$d/manifest.json"
                if [[ -f "$manifest" ]]; then
                    local comps=$(jq -r '.components | join(", ")' "$manifest" 2>/dev/null || echo "unknown")
                    echo -e "    ${GREEN}•${NC} ${CYAN}${bname}${NC}  [${comps}]"
                else
                    echo -e "    ${GREEN}•${NC} ${CYAN}${bname}${NC}"
                fi
            done
            echo ""
        else
            log_info "No backups found in ${BACKUP_BASE}"
        fi
        ;;
    *)
        log_error "Unknown resource '${RESOURCE}' for sandbox backup"
        echo -e "  ${YELLOW}Valid resources:${NC} full | connections | ords | config | schemas | list"
        exit 1
        ;;
esac
