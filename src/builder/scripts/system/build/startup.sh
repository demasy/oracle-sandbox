#!/bin/bash
# ============================================
# Oracle Sandbox Startup Script
# ============================================
# Handles automatic initialization on container startup
# Usage: Called automatically by CMD in Dockerfile
# ============================================

# Set TERM environment variable if not set
export TERM=xterm

# Source utility scripts using absolute paths
source /usr/sandbox/app/system/utils/colors.sh
source /usr/sandbox/app/system/utils/logging.sh
source /usr/sandbox/app/system/utils/banner.sh
source /usr/sandbox/app/system/utils/commands.sh

print_demasy_banner "Oracle Sandbox Startup"

echo ""
log_info "Starting initialization checks..."
echo ""

# ============================================
# Check if Oracle Instant Client is installed
# ============================================
if [ ! -d "/opt/oracle/instantclient" ] || [ -z "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
    log_warn "Oracle Instant Client not found"
    log_info "Run: ${CYAN}install-client${RESET} to install"
    echo ""
else
    log_success "Oracle Instant Client detected"
    log_info "Location: /opt/oracle/instantclient"
    echo ""
fi

# ============================================
# Check if SQLcl is installed
# ============================================
if [ ! -d "/opt/oracle/sqlcl" ] || [ -z "$(ls -A /opt/oracle/sqlcl 2>/dev/null)" ]; then
    log_warn "SQLcl not found"
    log_info "Run: ${CYAN}install-sqlcl${RESET} to install"
    echo ""
else
    log_success "SQLcl detected"
    log_info "Location: /opt/oracle/sqlcl"
    echo ""
fi

# ============================================
# Check if APEX software is downloaded
# ============================================
if [ "$INSTALL_APEX" = "true" ]; then
    if [ ! -d "/opt/oracle/apex" ] || [ -z "$(ls -A /opt/oracle/apex 2>/dev/null)" ]; then
        log_warn "APEX software not found (INSTALL_APEX=true)"
        log_info "Run: ${CYAN}download-apex${RESET} to download APEX and ORDS"
        echo ""
    else
        log_success "APEX software detected"
        log_info "Location: /opt/oracle/apex"
        echo ""
        
        # Check if ORDS is also available
        if [ ! -d "/opt/oracle/ords" ] || [ -z "$(ls -A /opt/oracle/ords 2>/dev/null)" ]; then
            log_warn "ORDS software not found"
            log_info "Run: ${CYAN}download-apex${RESET} to download both APEX and ORDS"
            echo ""
        else
            log_success "ORDS software detected"
            log_info "Location: /opt/oracle/ords"
            echo ""
        fi
    fi
else
    log_info "APEX installation disabled (INSTALL_APEX=${INSTALL_APEX:-false})"
    echo ""
fi

# ============================================
# Database Connection Check
# ============================================
log_step "Checking database connectivity..."

# Check if required environment variables are set
if [[ -n "$SANDBOX_DB_HOST" && -n "$SANDBOX_DB_PORT" && -n "$SANDBOX_DB_SERVICE" && -n "$SANDBOX_DB_USER" && -n "$SANDBOX_DB_PASS" ]]; then
    log_info "Database connection parameters configured"
    log_info "Host: $SANDBOX_DB_HOST:$SANDBOX_DB_PORT"
    log_info "Service: $SANDBOX_DB_SERVICE"
    log_info "User: $SANDBOX_DB_USER"
    echo ""
else
    log_warn "Database connection not configured"
    log_info "Missing environment variables:"
    [[ -z "$SANDBOX_DB_HOST" ]] && echo "  ✗ SANDBOX_DB_HOST"
    [[ -z "$SANDBOX_DB_PORT" ]] && echo "  ✗ SANDBOX_DB_PORT"
    [[ -z "$SANDBOX_DB_SERVICE" ]] && echo "  ✗ SANDBOX_DB_SERVICE"
    [[ -z "$SANDBOX_DB_USER" ]] && echo "  ✗ SANDBOX_DB_USER"
    [[ -z "$SANDBOX_DB_PASS" ]] && echo "  ✗ SANDBOX_DB_PASS"
    echo ""
    log_info "For standalone container, pass variables with: ${CYAN}-e SANDBOX_DB_PASS=...${RESET}"
    echo ""
fi

# ============================================
# Auto-install APEX if enabled and not already installed
# ============================================
if [ "$INSTALL_APEX" = "true" ]; then
    log_step "Checking APEX installation in database..."
    
    # Check if APEX is installed in database (requires DB connection)
    if [[ -n "$SANDBOX_DB_HOST" && -n "$SANDBOX_DB_PASS" ]]; then
        
        # Wait for database to be ready if configured
        if [ "${SANDBOX_STARTUP_WAIT_FOR_DB:-true}" = "true" ]; then
            log_info "Waiting for database to be ready..."
            WAIT_TIMEOUT=${SANDBOX_STARTUP_DB_WAIT_TIMEOUT:-120}
            WAIT_INTERVAL=${SANDBOX_STARTUP_DB_WAIT_INTERVAL:-5}
            WAIT_ELAPSED=0
            
            while [ $WAIT_ELAPSED -lt $WAIT_TIMEOUT ]; do
                if sql -S ${SANDBOX_DB_USER}/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT}/${SANDBOX_DB_SERVICE} <<EOF 2>/dev/null | grep -q "1"
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SELECT 1 FROM DUAL;
EXIT;
EOF
                then
                    log_success "Database is ready"
                    echo ""
                    break
                fi
                
                log_info "Database not ready yet, waiting... ($WAIT_ELAPSED/$WAIT_TIMEOUT seconds)"
                sleep $WAIT_INTERVAL
                WAIT_ELAPSED=$((WAIT_ELAPSED + WAIT_INTERVAL))
            done
            
            if [ $WAIT_ELAPSED -ge $WAIT_TIMEOUT ]; then
                log_warn "Database readiness timeout reached ($WAIT_TIMEOUT seconds)"
                log_info "Proceeding anyway - APEX check may fail"
                echo ""
            fi
        fi
        
    else
        log_warn "Cannot check APEX installation (database not accessible)"
        log_info "Once database is ready, run: ${CYAN}install-apex${RESET}"
        echo ""
    fi
fi

# ============================================
# Auto-create default database users (background)
# Runs after server starts — waits until DB is ready
# ============================================
if [[ -n "$SANDBOX_DB_HOST" && -n "$SANDBOX_DB_PORT" && -n "$SANDBOX_DB_SERVICE" && -n "$SANDBOX_DB_USER" && -n "$SANDBOX_DB_PASS" ]]; then

    AUTO_USER_LOG="/tmp/auto-user-setup.log"

    (
        export TERM=xterm
        WAIT_TIMEOUT=${SANDBOX_STARTUP_DB_WAIT_TIMEOUT:-600}
        WAIT_INTERVAL=${SANDBOX_STARTUP_DB_WAIT_INTERVAL:-10}
        WAIT_ELAPSED=0

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto-user setup started (timeout: ${WAIT_TIMEOUT}s)" >> "$AUTO_USER_LOG"

        # Wait for database to be ready
        while [ "$WAIT_ELAPSED" -lt "$WAIT_TIMEOUT" ]; do
            if sql -S "${SANDBOX_DB_USER}/${SANDBOX_DB_PASS}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT}/${SANDBOX_DB_SERVICE}" <<EOF 2>/dev/null | grep -q "1"
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SELECT 1 FROM DUAL;
EXIT;
EOF
            then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Database is ready" >> "$AUTO_USER_LOG"
                break
            fi
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for database... (${WAIT_ELAPSED}/${WAIT_TIMEOUT}s)" >> "$AUTO_USER_LOG"
            sleep "$WAIT_INTERVAL"
            WAIT_ELAPSED=$((WAIT_ELAPSED + WAIT_INTERVAL))
        done

        if [ "$WAIT_ELAPSED" -ge "$WAIT_TIMEOUT" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Database readiness timeout (${WAIT_TIMEOUT}s) — users not created" >> "$AUTO_USER_LOG"
            exit 1
        fi

        # ─── Extract PDB list from YAML (dynamic, no hardcoding) ────────────────────
        YAML_CONFIG="/usr/sandbox/app/oracle/admin/config/database-objects.yaml"
        PDBS_ARRAY=()
        
        while IFS= read -r pdb_name; do
            [[ -z "$pdb_name" ]] && continue
            PDBS_ARRAY+=("$pdb_name")
        done < <(bash /usr/sandbox/app/oracle/admin/utils/parse-yaml-pdbs.sh "$YAML_CONFIG" 2>/dev/null)
        
        if [[ ${#PDBS_ARRAY[@]} -eq 0 ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: No PDBs found in YAML configuration" >> "$AUTO_USER_LOG"
            exit 1
        fi

        # ─── Create PDBs (idempotent) ─────────────────────────────────────────────
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating PDBs: ${PDBS_ARRAY[*]}" >> "$AUTO_USER_LOG"

        for pdb in "${PDBS_ARRAY[@]}"; do
            bash /usr/sandbox/app/oracle/admin/ddl/create-pdb.sh "$pdb" \
                >> "$AUTO_USER_LOG" 2>&1 \
                && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] $pdb ready" >> "$AUTO_USER_LOG" \
                || echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $pdb creation failed" >> "$AUTO_USER_LOG"
        done

        # ─── Provision users dynamically from YAML config ──────────────────────────
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating database users from configuration..." >> "$AUTO_USER_LOG"
        echo "" >> "$AUTO_USER_LOG"

        for pdb in "${PDBS_ARRAY[@]}"; do
            bash /usr/sandbox/app/oracle/admin/ddl/provision-users-from-config.sh "$pdb" \
                "$YAML_CONFIG" \
                "$AUTO_USER_LOG" \
                2>&1
            
            if [[ $? -eq 0 ]]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] Users provisioned for $pdb" >> "$AUTO_USER_LOG"
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] User provisioning failed for $pdb" >> "$AUTO_USER_LOG"
            fi
            
            echo "" >> "$AUTO_USER_LOG"
        done

        # ─── Set up MCP saved connection (after SANDBOX_PDB users ready) ──────────
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setting up MCP saved connection..." >> "$AUTO_USER_LOG"
        SANDBOX_DB_MCP_USER="${SANDBOX_DB_MCP_USER:-${SANDBOX_DB_USER}}" \
        SANDBOX_DB_MCP_SERVICE="${SANDBOX_DB_MCP_SERVICE}" \
        SANDBOX_DB_PASSWORD="${SANDBOX_DB_PASSWORD:-${SANDBOX_DB_PASS}}" \
        bash /usr/sandbox/app/oracle/mcp/setup-saved-connection.sh \
            >> "$AUTO_USER_LOG" 2>&1 \
            && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] MCP saved connection ready" >> "$AUTO_USER_LOG" \
            || echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] MCP saved connection setup failed" >> "$AUTO_USER_LOG"

        # ─── Set up default SQLcl saved connections for sandbox users ────────────
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setting up default SQLcl saved connections..." >> "$AUTO_USER_LOG"
        
        # Define default connections: name→user→PDB mappings
        declare -A SANDBOX_CONNS=(
            ["sandbox-sandbox-conn"]="sandbox:SANDBOX_PDB"
            ["sandbox-sandbox-ai-conn"]="sandbox_ai:SANDBOX_PDB"
            ["sandbox-demasy-conn"]="demasy:DEMASY_PDB"
            ["sandbox-demasy-ai-conn"]="demasy_ai:DEMASY_PDB"
        )
        
        # For connections inside Docker containers, use the service name instead of external IP
        # This ensures reliable inter-container communication via Docker DNS
        DB_HOST="sandbox-oracle-database"
        DB_PORT="${SANDBOX_DB_PORT}"
        DB_PASS="${SANDBOX_DB_PASSWORD:-${SANDBOX_DB_PASS}}"
        CONN_DIR="${HOME:-/home/sandbox}/.dbtools/connections"
        mkdir -p "$CONN_DIR" 2>/dev/null
        
        for conn_name in "${!SANDBOX_CONNS[@]}"; do
            IFS=':' read -r conn_user conn_pdb <<< "${SANDBOX_CONNS[$conn_name]}"
            
            # Skip if connection already exists
            if grep -Rq "^name=${conn_name}$" "$CONN_DIR" 2>/dev/null; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Connection '${conn_name}' already exists" >> "$AUTO_USER_LOG"
                continue
            fi
            
            # Create the saved connection using SQLcl
            if /opt/oracle/sqlcl/bin/sql /nolog <<EOSQL >> "$AUTO_USER_LOG" 2>&1
CONN -save "${conn_name}" -savepwd ${conn_user}/${DB_PASS}@//${DB_HOST}:${DB_PORT}/${conn_pdb}
EXIT
EOSQL
            then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] Saved connection '${conn_name}' ready" >> "$AUTO_USER_LOG"
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] Failed to create connection '${conn_name}'" >> "$AUTO_USER_LOG"
            fi
        done
        
        echo "" >> "$AUTO_USER_LOG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto-user setup complete" >> "$AUTO_USER_LOG"
    ) &

    log_info "Auto-user setup running in background"
    log_info "Monitor: tail -f /tmp/auto-user-setup.log"
    echo ""
else
    log_warn "Skipping auto-user creation (database connection not configured)"
    echo ""
fi

log_success "Startup checks complete!"
echo ""
log_info "Starting management server..."
echo ""

# Display available commands
display_commands

# Start the Node.js management server
exec node /usr/sandbox/app/app.js
