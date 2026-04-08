#!/bin/bash
# ============================================
# Oracle Sandbox Startup Script
# ============================================
# Handles automatic initialization on container startup
# Usage: Called automatically by CMD in Dockerfile
# ============================================

# Set TERM environment variable if not set
export TERM=${TERM:-xterm}

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
if [[ -n "$DEMASYLABS_DB_HOST" && -n "$DEMASYLABS_DB_PORT" && -n "$DEMASYLABS_DB_SERVICE" && -n "$DEMASYLABS_DB_USER" && -n "$DEMASYLABS_DB_PASS" ]]; then
    log_info "Database connection parameters configured"
    log_info "Host: $DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT"
    log_info "Service: $DEMASYLABS_DB_SERVICE"
    log_info "User: $DEMASYLABS_DB_USER"
    echo ""
    
    # Test database connectivity (optional - uncomment if needed)
    # log_step "Testing database connection..."
    # if sqlcl -S /nolog <<EOF > /dev/null 2>&1
# CONNECT ${DEMASYLABS_DB_USER}/${DEMASYLABS_DB_PASS}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}
# SELECT 1 FROM DUAL;
# EXIT;
# EOF
    # then
    #     log_success "Database connection successful"
    #     echo ""
    # else
    #     log_warn "Database connection failed (database may still be starting)"
    #     log_info "You can test later with: ${CYAN}sqlcl${RESET}"
    #     echo ""
    # fi
else
    log_warn "Database connection not configured"
    log_info "Missing environment variables:"
    [[ -z "$DEMASYLABS_DB_HOST" ]] && echo "  ✗ DEMASYLABS_DB_HOST"
    [[ -z "$DEMASYLABS_DB_PORT" ]] && echo "  ✗ DEMASYLABS_DB_PORT"
    [[ -z "$DEMASYLABS_DB_SERVICE" ]] && echo "  ✗ DEMASYLABS_DB_SERVICE"
    [[ -z "$DEMASYLABS_DB_USER" ]] && echo "  ✗ DEMASYLABS_DB_USER"
    [[ -z "$DEMASYLABS_DB_PASS" ]] && echo "  ✗ DEMASYLABS_DB_PASS"
    echo ""
    log_info "For standalone container, pass variables with: ${CYAN}-e DEMASYLABS_DB_PASS=...${RESET}"
    echo ""
fi

# ============================================
# Auto-install APEX if enabled and not already installed
# ============================================
if [ "$INSTALL_APEX" = "true" ]; then
    log_step "Checking APEX installation in database..."
    
    # Check if APEX is installed in database (requires DB connection)
    if [[ -n "$DEMASYLABS_DB_HOST" && -n "$DEMASYLABS_DB_PASS" ]]; then
        
        # Wait for database to be ready if configured
        if [ "${DEMASYLABS_STARTUP_WAIT_FOR_DB:-true}" = "true" ]; then
            log_info "Waiting for database to be ready..."
            WAIT_TIMEOUT=${DEMASYLABS_STARTUP_DB_WAIT_TIMEOUT:-120}
            WAIT_INTERVAL=${DEMASYLABS_STARTUP_DB_WAIT_INTERVAL:-5}
            WAIT_ELAPSED=0
            
            while [ $WAIT_ELAPSED -lt $WAIT_TIMEOUT ]; do
                if sql -S ${DEMASYLABS_DB_USER}/${DEMASYLABS_DB_PASS}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE} <<EOF 2>/dev/null | grep -q "1"
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
        
        # Check if APEX schema exists in database
        APEX_INSTALLED=$(sql -S ${DEMASYLABS_DB_USER}/${DEMASYLABS_DB_PASS}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE} <<EOF 2>/dev/null | grep -E "^[0-9]+$" | tail -1
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SELECT COUNT(*) FROM dba_users WHERE username LIKE 'APEX_%';
EXIT;
EOF
)
        
        # Trim whitespace and check if it's a number greater than 0
        APEX_INSTALLED=$(echo "$APEX_INSTALLED" | tr -d '[:space:]')
        
        # if [[ "$APEX_INSTALLED" =~ ^[0-9]+$ ]] && [[ "$APEX_INSTALLED" -gt 0 ]]; then
        #     log_success "APEX already installed in database"
        #     echo ""
        # else
        #     log_info "APEX not yet installed in database"
            
        #     # Check if automatic installation is enabled
        #     if [ "${DEMASYLABS_AUTO_INSTALL_APEX_ON_STARTUP:-true}" = "true" ]; then
        #         log_info "Auto-install enabled (DEMASYLABS_AUTO_INSTALL_APEX_ON_STARTUP=true)"
        #         log_info "Installing APEX automatically (this takes 3-5 minutes)..."
                
        #         # Determine if we should show logs inline
        #         if [ "${DEMASYLABS_SHOW_APEX_INSTALL_LOGS:-true}" = "true" ]; then
        #             log_info "Installation logs will appear below..."
        #             echo ""
        #             echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    
        #             # Run installation with visible output
        #             set +e  # Don't exit on error
        #             timeout ${DEMASYLABS_APEX_INSTALL_TIMEOUT:-600} bash /usr/sandbox/app/oracle/apex/install.sh 2>&1 | tee /tmp/apex-startup-install.log
        #             INSTALL_EXIT_CODE=${PIPESTATUS[0]}
        #             set -e  # Re-enable exit on error
                    
        #             echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        #         else
        #             log_info "Running installation in background (logs saved to /tmp/apex-startup-install.log)"
        #             log_info "Monitor progress: docker exec -it demasylabs-oracle-server tail -f /tmp/apex-startup-install.log"
        #             echo ""
                    
        #             # Run installation in background
        #             set +e
        #             timeout ${DEMASYLABS_APEX_INSTALL_TIMEOUT:-600} bash /usr/sandbox/app/oracle/apex/install.sh > /tmp/apex-startup-install.log 2>&1 &
        #             INSTALL_PID=$!
                    
        #             # Wait for installation to complete
        #             wait $INSTALL_PID
        #             INSTALL_EXIT_CODE=$?
        #             set -e
        #         fi
                
        #         # Check installation result
        #         if [ $INSTALL_EXIT_CODE -eq 0 ]; then
        #             log_success "APEX installation completed successfully!"
        #         elif [ $INSTALL_EXIT_CODE -eq 124 ]; then
        #             log_error "APEX installation timed out after ${DEMASYLABS_APEX_INSTALL_TIMEOUT:-600} seconds"
        #             log_info "Increase timeout with: DEMASYLABS_APEX_INSTALL_TIMEOUT=900"
        #         else
        #             log_error "APEX installation failed with exit code: $INSTALL_EXIT_CODE"
        #             log_info "Full logs saved to: /tmp/apex-startup-install.log"
        #             log_info "Or run manually: ${CYAN}install-apex${RESET}"
        #         fi
        #     else
        #         log_info "Auto-install disabled (DEMASYLABS_AUTO_INSTALL_APEX_ON_STARTUP=false)"
        #         log_info "To install APEX, run: ${CYAN}install-apex${RESET}"
        #     fi
        #     echo ""
        # fi
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
if [[ -n "$DEMASYLABS_DB_HOST" && -n "$DEMASYLABS_DB_PORT" && -n "$DEMASYLABS_DB_SERVICE" && -n "$DEMASYLABS_DB_USER" && -n "$DEMASYLABS_DB_PASS" ]]; then

    AUTO_USER_LOG="/tmp/auto-user-setup.log"

    (
        WAIT_TIMEOUT=${DEMASYLABS_STARTUP_DB_WAIT_TIMEOUT:-600}
        WAIT_INTERVAL=${DEMASYLABS_STARTUP_DB_WAIT_INTERVAL:-10}
        WAIT_ELAPSED=0

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto-user setup started (timeout: ${WAIT_TIMEOUT}s)" >> "$AUTO_USER_LOG"

        # Wait for database to be ready
        while [ "$WAIT_ELAPSED" -lt "$WAIT_TIMEOUT" ]; do
            if sql -S "${DEMASYLABS_DB_USER}/${DEMASYLABS_DB_PASS}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}" <<EOF 2>/dev/null | grep -q "1"
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

        # Create default users — idempotent (skips if already exists)
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating default database users..." >> "$AUTO_USER_LOG"

        bash /usr/sandbox/app/oracle/admin/create-user.sh demasy Demasy1986 DEMASYLABS_PDB \
            >> "$AUTO_USER_LOG" 2>&1 \
            && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] demasy user ready" >> "$AUTO_USER_LOG" \
            || echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] demasy user setup failed" >> "$AUTO_USER_LOG"

        bash /usr/sandbox/app/oracle/admin/create-user.sh demasylabs Demasy1986 DEMASYLABS_PDB \
            >> "$AUTO_USER_LOG" 2>&1 \
            && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] demasylabs user ready" >> "$AUTO_USER_LOG" \
            || echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] demasylabs user setup failed" >> "$AUTO_USER_LOG"

        # Set up MCP saved connection (stored in ~/.dbtools inside container)
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setting up MCP saved connection..." >> "$AUTO_USER_LOG"
        DEMASYLABS_DB_MCP_USER="${DEMASYLABS_DB_MCP_USER:-${DEMASYLABS_DB_USER}}" \
        DEMASYLABS_DB_PASSWORD="${DEMASYLABS_DB_PASSWORD:-${DEMASYLABS_DB_PASS}}" \
        bash /usr/sandbox/app/oracle/mcp/setup-saved-connection.sh \
            >> "$AUTO_USER_LOG" 2>&1 \
            && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] MCP saved connection ready" >> "$AUTO_USER_LOG" \
            || echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] MCP saved connection setup failed" >> "$AUTO_USER_LOG"

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
