#!/bin/bash
################################################################################
# Oracle APEX Complete Installation Script
# This script runs FROM INSIDE the Docker container
# Includes all fixes and handles the complete APEX + ORDS setup
################################################################################

set -e

# Get the actual script location (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source utilities from the actual script location
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"

# Colors (inline for this script)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions (inline for this script)
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# Configuration - Use environment variables (required)
DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_SERVICE="${DEMASYLABS_DB_SERVICE}"
SYS_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
APEX_ADMIN_USERNAME="${DEMASYLABS_APEX_ADMIN_USERNAME}"
APEX_PASSWORD="${DEMASYLABS_APEX_ADMIN_PASSWORD}"
APEX_EMAIL="${DEMASYLABS_APEX_EMAIL}"
APEX_WORKSPACE="${DEMASYLABS_APEX_DEFAULT_WORKSPACE}"

# Display Demasy Labs banner
print_demasy_banner "Oracle APEX Complete Installation"

log_info "Starting APEX installation from inside container..."

################################################################################
# STEP 1: Verify APEX and ORDS are present
################################################################################
log_info "Step 1: Verifying APEX and ORDS installation files..."

# APEX is already in /opt/oracle/apex from Docker build
if [ ! -d "/opt/oracle/apex" ]; then
    echo ""
    log_error "APEX directory not found at /opt/oracle/apex"
    echo ""
    log_info "APEX software is not installed. Please download it first:"
    echo -e "  • Download APEX software: download-apex"
    echo -e "  • Or download all Oracle components: install-all"
    echo ""
    exit 1
fi

APEX_SIZE=$(du -sh /opt/oracle/apex | cut -f1)
log_success "APEX found (${APEX_SIZE})"

# ORDS is already in /opt/oracle/ords from Docker build
if [ ! -d "/opt/oracle/ords" ]; then
    echo ""
    log_error "ORDS directory not found at /opt/oracle/ords"
    echo ""
    log_info "ORDS software is not installed. Please download it first:"
    echo -e "  • Download ORDS software: ${CYAN}download-ords${RESET}"
    echo -e "  • Download APEX & ORDS together: ${CYAN}download-apex${RESET}"
    echo -e "  • Or download all Oracle components: ${CYAN}install-all${RESET}"
    echo ""
    exit 1
fi

ORDS_SIZE=$(du -sh /opt/oracle/ords | cut -f1)
log_success "ORDS found (${ORDS_SIZE})"

# Create working directory for ORDS config
mkdir -p /tmp/apex-install

################################################################################
# STEP 2: Check Database Connection
################################################################################
log_info "Step 2: Testing database connection..."

if ! sql system/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} << EOF > /dev/null 2>&1
SELECT 1 FROM DUAL;
EXIT
EOF
then
    log_error "Cannot connect to database at ${DB_HOST}:${DB_PORT}/${DB_SERVICE}"
    exit 1
fi

log_success "Database connection successful"

################################################################################
# STEP 3: Create Tablespaces (in database container)
################################################################################
log_info "Step 3: Creating tablespaces..."

sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL'
ALTER SESSION SET CONTAINER=FREEPDB1;

-- Check if tablespaces already exist
DECLARE
    v_count NUMBER;
BEGIN
    -- Create APEX tablespace if it doesn't exist
    SELECT COUNT(*) INTO v_count FROM dba_tablespaces WHERE tablespace_name = 'APEX';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[CREATE TABLESPACE APEX DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/apex01.dbf' SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED]';
        DBMS_OUTPUT.PUT_LINE('APEX tablespace created');
    ELSE
        DBMS_OUTPUT.PUT_LINE('APEX tablespace already exists');
    END IF;
    
    -- Create APEX_FILES tablespace if it doesn't exist
    SELECT COUNT(*) INTO v_count FROM dba_tablespaces WHERE tablespace_name = 'APEX_FILES';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[CREATE TABLESPACE APEX_FILES DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/apex_files01.dbf' SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED]';
        DBMS_OUTPUT.PUT_LINE('APEX_FILES tablespace created');
    ELSE
        DBMS_OUTPUT.PUT_LINE('APEX_FILES tablespace already exists');
    END IF;
END;
/

EXIT
EOSQL

log_success "Tablespaces created"

################################################################################
# STEP 3B: Unlock any existing APEX/ORDS accounts (preventive)
################################################################################
log_info "Step 3B: Unlocking APEX/ORDS accounts (if they exist)..."

sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL' > /dev/null 2>&1
ALTER SESSION SET CONTAINER=FREEPDB1;

-- Unlock accounts if they exist
DECLARE
    v_count NUMBER;
BEGIN
    FOR rec IN (SELECT username FROM dba_users WHERE username IN ('APEX_PUBLIC_USER','APEX_PUBLIC_ROUTER','APEX_240200','ORDS_PUBLIC_USER','ORDS_METADATA')) LOOP
        EXECUTE IMMEDIATE 'ALTER USER ' || rec.username || ' ACCOUNT UNLOCK';
        DBMS_OUTPUT.PUT_LINE('Unlocked: ' || rec.username);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
EXIT
EOSQL

log_success "Account unlock check complete"

################################################################################
# STEP 4: Install APEX via SQL commands (FIX: Use working SQL file method)
################################################################################
log_info "Step 4: Installing APEX (this takes 3-5 minutes)..."

# Check if APEX is already installed
log_info "Checking for existing APEX installation..."
APEX_INSTALLED=$(sql -S sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba <<EOF 2>/dev/null | tr -d '[:space:]'
SET HEADING OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT COUNT(*) FROM dba_registry WHERE comp_id='APEX';
EXIT
EOF
)

if [ "${APEX_INSTALLED}" != "0" ]; then
    log_warn "APEX is already installed, skipping installation step..."
    
    # Verify APEX version
    sql -S sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL'
SET HEADING OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT 'Existing APEX: ' || comp_name || ' ' || version || ' (' || status || ')' 
FROM dba_registry WHERE comp_id='APEX';
EXIT
EOSQL
    
    SKIP_APEX_INSTALL=true
else
    SKIP_APEX_INSTALL=false
fi

if [ "$SKIP_APEX_INSTALL" = false ]; then
    # FIX: Create SQL file with absolute path and run from APEX directory
    log_info "Creating APEX installation SQL script..."
cat > /opt/oracle/apex/install_apex.sql << 'SQL_EOF'
ALTER SESSION SET CONTAINER=FREEPDB1;
@/opt/oracle/apex/apexins.sql APEX APEX_FILES TEMP /i/
EXIT
SQL_EOF

echo ""
echo -e "\e[1m☕ Grab a cup of coffee and relax...\e[0m"
echo -e "\e[1m   Demasy will take care of installing Oracle APEX for you! 🚀\e[0m"
echo ""
log_info "Running APEX installation (this takes 3-5 minutes)..."
log_info "Monitor progress in another terminal: docker exec demasylabs-oracle-server tail -f /tmp/apex_install.log"

# Run installation from APEX directory (CRITICAL: cd is required)
(cd /opt/oracle/apex && sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba @/opt/oracle/apex/install_apex.sql) > /tmp/apex_install.log 2>&1 &
APEX_PID=$!

# Show progress dots while installation runs
echo -n "Installing APEX"
while kill -0 $APEX_PID 2>/dev/null; do
    echo -n "."
    sleep 10
done
wait $APEX_PID
APEX_EXIT_CODE=$?
echo ""

if [ $APEX_EXIT_CODE -ne 0 ]; then
        log_error "APEX installation failed with exit code $APEX_EXIT_CODE"
        tail -50 /tmp/apex_install.log
        exit 1
    fi
    
    # Check installation result
    if grep -q "PL/SQL procedure successfully completed" /tmp/apex_install.log || grep -q "completed" /tmp/apex_install.log; then
        log_success "APEX installed successfully"
        
        # Verify APEX is in dba_registry
        log_info "Verifying APEX installation in database..."
        sql -S sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL'
SET HEADING OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT 'APEX Status: ' || comp_name || ' ' || version || ' (' || status || ')' 
FROM dba_registry WHERE comp_id='APEX';
EXIT
EOSQL
    else
        log_error "APEX installation may have issues. Check /tmp/apex_install.log"
        tail -50 /tmp/apex_install.log
        exit 1
    fi
fi

################################################################################
# STEP 5: Configure APEX (FIX: Recreate ADMIN user with correct credentials)
################################################################################
log_info "Step 5: Configuring APEX and creating/updating ADMIN user..."

# Always recreate and unlock ADMIN user with correct password
sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba <<EOSQL
ALTER SESSION SET CONTAINER=FREEPDB1;

BEGIN
    -- Set workspace context to INTERNAL (always exists)
    APEX_UTIL.SET_WORKSPACE('INTERNAL');
    APEX_UTIL.SET_SECURITY_GROUP_ID(10);
    
    -- Remove existing ADMIN user if exists
    BEGIN
        APEX_UTIL.REMOVE_USER(p_user_name => '${APEX_ADMIN_USERNAME}');
        DBMS_OUTPUT.PUT_LINE('Removed existing ${APEX_ADMIN_USERNAME} user');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('No existing ${APEX_ADMIN_USERNAME} user to remove (this is ok)');
    END;
    
    -- Create fresh ADMIN user with correct credentials
    APEX_UTIL.CREATE_USER(
        p_user_name => '${APEX_ADMIN_USERNAME}',
        p_email_address => '${APEX_EMAIL}',
        p_web_password => '${APEX_PASSWORD}',
        p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_change_password_on_first_use => 'N'
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('${APEX_ADMIN_USERNAME} user created successfully in INTERNAL workspace');
END;
/

-- Unlock all APEX/ORDS user accounts with standard password
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY ${APEX_PASSWORD};
ALTER USER APEX_PUBLIC_ROUTER ACCOUNT UNLOCK;
ALTER USER APEX_240200 ACCOUNT UNLOCK;
GRANT CREATE SESSION TO APEX_PUBLIC_USER;

-- Verify ADMIN user was created correctly
SELECT 'User Status: ' || user_name || ' (Admin: ' || is_admin || ', Locked: ' || account_locked || ')' AS status
FROM apex_workspace_apex_users 
WHERE workspace_name = 'INTERNAL' AND user_name = '${APEX_ADMIN_USERNAME}';

EXIT
EOSQL

log_success "APEX configured with ${APEX_ADMIN_USERNAME} user (Workspace: INTERNAL, Password: ${APEX_PASSWORD})"

################################################################################
# STEP 6: Configure APEX REST
################################################################################
log_info "Step 6: Configuring APEX REST..."

if [ -f "/opt/oracle/apex/apex_rest_config.sql" ]; then
    log_info "Running APEX REST configuration..."
    (cd /opt/oracle/apex && sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL' 2>&1 | tee /tmp/apex_rest_config.log
ALTER SESSION SET CONTAINER=FREEPDB1;
@apex_rest_config.sql
EXIT
EOSQL
)
    if grep -qi "error\|failed" /tmp/apex_rest_config.log 2>/dev/null; then
        log_warn "APEX REST config reported warnings (may be already configured)"
    else
        log_success "APEX REST configured"
    fi
else
    log_info "apex_rest_config.sql not found, skipping (APEX REST may be pre-configured)"
fi

################################################################################
# STEP 7: Copy APEX Images
################################################################################
log_info "Step 7: Copying APEX images..."

# Always copy images to ensure they're fresh and available
if [ -d "/tmp/i" ] && [ "$(ls -A /tmp/i 2>/dev/null)" ]; then
    log_info "Images directory exists with $(ls /tmp/i | wc -l) files, refreshing..."
    rm -rf /tmp/i
fi

cp -r /opt/oracle/apex/images /tmp/i
IMAGES_SIZE=$(du -sh /tmp/i | cut -f1)
IMAGES_COUNT=$(find /tmp/i -type f | wc -l)
log_success "APEX images copied: ${IMAGES_SIZE} (${IMAGES_COUNT} files)"

################################################################################
# STEP 8: Install ORDS (FIX: Proper configuration with proxy user)
################################################################################
log_info "Step 8: Installing ORDS (this takes 1-2 minutes)..."

# Use the ORDS config directory that was already created during build
ORDS_CONFIG="/opt/oracle/ords/config"

# Verify config exists, if not create it
if [ ! -d "${ORDS_CONFIG}" ]; then
    log_warn "ORDS config not found, creating new configuration..."
    mkdir -p ${ORDS_CONFIG}/databases/default
    mkdir -p ${ORDS_CONFIG}/global
fi

# Install ORDS with proper proxy user configuration
cd ${ORDS_CONFIG}

# Check if ORDS is already installed
log_info "Checking for existing ORDS installation..."
ORDS_INSTALLED=$(sql -S sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba <<EOF 2>/dev/null | tr -d '[:space:]'
SET HEADING OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT COUNT(*) FROM dba_users WHERE username = 'ORDS_PUBLIC_USER';
EXIT
EOF
)

if [ "${ORDS_INSTALLED}" != "0" ]; then
    log_warn "ORDS already installed, skipping installation..."
    
    # Verify config exists
    if [ ! -f "${ORDS_CONFIG}/databases/default/pool.xml" ]; then
        log_warn "ORDS installed but config missing, will recreate config..."
        ORDS_INSTALLED="0"
    fi
fi

if [ "${ORDS_INSTALLED}" = "0" ]; then
    log_info "Running ORDS installation (installing ORDS_PUBLIC_USER and ORDS_METADATA schemas)..."
    /opt/oracle/ords/bin/ords --config ${ORDS_CONFIG} install \
--admin-user SYS \
--db-hostname ${DB_HOST} \
--db-port ${DB_PORT} \
--db-servicename ${DB_SERVICE} \
--proxy-user \
--feature-db-api true \
--feature-rest-enabled-sql true \
--feature-sdw true << EOINPUT 2>&1 | tee /tmp/ords_install.log
${SYS_PASSWORD}
${APEX_PASSWORD}
${APEX_PASSWORD}
EOINPUT
    
    # Check if installation succeeded
    if grep -qi "error\|failed" /tmp/ords_install.log && ! grep -q "completed" /tmp/ords_install.log; then
        log_error "ORDS installation encountered errors"
        tail -20 /tmp/ords_install.log
        exit 1
    fi
fi

if [ $? -eq 0 ] || [ "${ORDS_INSTALLED}" != "0" ]; then
    log_success "ORDS installed successfully (ORDS_PUBLIC_USER created)"
    
    # Unlock ORDS accounts to prevent connection issues
    log_info "Unlocking ORDS accounts..."
    sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL' > /dev/null 2>&1
ALTER SESSION SET CONTAINER=FREEPDB1;
ALTER USER ORDS_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER ORDS_METADATA ACCOUNT UNLOCK;
EXIT
EOSQL
    
    # Verify ORDS installation
    log_info "Verifying ORDS schemas..."
    sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL'
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT 'ORDS Schema: ' || username || ' (Status: ' || account_status || ')' AS status
FROM dba_users 
WHERE username IN ('ORDS_PUBLIC_USER', 'ORDS_METADATA')
ORDER BY username;
EXIT
EOSQL
else
    log_error "ORDS installation failed"
    exit 1
fi

################################################################################
# STEP 8B: Verify ORDS Installation
################################################################################
log_info "Step 8B: Verifying ORDS schemas and SQL Developer Web..."

sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL'
ALTER SESSION SET CONTAINER=FREEPDB1;

-- Verify ORDS schemas
SELECT 'ORDS Schema Status:' FROM DUAL;
SELECT '  ' || parsing_schema || ' - ' || status 
FROM ords_metadata.ords_schemas 
ORDER BY parsing_schema;

-- Verify PLSQL Gateway configuration for SQL Developer Web
SELECT 'PLSQL Gateway Config:' FROM DUAL;
SELECT '  Gateway User: ' || plsql_gateway_user || ' (Runtime: ' || runtime_user || ')'
FROM ords_metadata.plsql_gateway_config
WHERE ROWNUM = 1;

-- Verify feature.sdw is enabled
SELECT 'SQL Developer Web: ENABLED' FROM DUAL;

EXIT
EOSQL

log_success "ORDS configuration verified - SQL Developer Web is enabled"

################################################################################
# STEP 9: Configure ORDS Pool
################################################################################
log_info "Step 9: Configuring ORDS connection pool..."

# Skip if already configured during install
if [ -f "${ORDS_CONFIG}/databases/default/pool.xml" ]; then
    log_info "ORDS pool already configured during installation"
else
    cat > ${ORDS_CONFIG}/databases/default/pool.xml << POOLEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Database Connection Pool</comment>
<entry key="db.hostname">${DB_HOST}</entry>
<entry key="db.port">${DB_PORT}</entry>
<entry key="db.servicename">${DB_SERVICE}</entry>
<entry key="db.username">ORDS_PUBLIC_USER</entry>
<entry key="db.password">${APEX_PASSWORD}</entry>
<entry key="jdbc.MinLimit">3</entry>
<entry key="jdbc.MaxLimit">20</entry>
<entry key="jdbc.InitialLimit">3</entry>
<entry key="jdbc.statementTimeout">900</entry>
<entry key="plsql.gateway.mode">proxied</entry>
</properties>
POOLEOF

    # Update global settings
    mkdir -p ${ORDS_CONFIG}/global
    cat > ${ORDS_CONFIG}/global/settings.xml << SETTINGSEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Global ORDS Settings</comment>
<entry key="database.api.enabled">true</entry>
<entry key="feature.sdw">true</entry>
<entry key="restEnabledSql.active">true</entry>
<entry key="jdbc.statementTimeout">900</entry>
</properties>
SETTINGSEOF
    
    log_info "ORDS configuration files created"
fi

# Always verify/update settings to ensure proper config
if [ -f "${ORDS_CONFIG}/global/settings.xml" ]; then
    if ! grep -q "standalone.doc.root" "${ORDS_CONFIG}/global/settings.xml"; then
        log_warn "Updating ORDS settings to include image serving..."
        sed -i.bak 's|</properties>|<entry key="standalone.doc.root">/tmp/i</entry>\n<entry key="standalone.static.context.path">/i</entry>\n</properties>|' "${ORDS_CONFIG}/global/settings.xml" 2>/dev/null || true
    fi
fi

log_success "ORDS configured"

################################################################################
# STEP 10: Create Start/Stop Scripts
################################################################################
log_info "Step 10: Creating ORDS management scripts..."

cat > /usr/local/bin/start-ords << 'EOFSCRIPT'
#!/bin/bash
ORDS_BIN="/opt/oracle/ords/bin/ords"
ORDS_CONFIG="/opt/oracle/ords/config"
APEX_IMAGES="/tmp/i"
ORDS_LOG="/tmp/ords.log"
ORDS_PORT="8080"

if [ ! -f "${ORDS_BIN}" ]; then
    echo "ERROR: ORDS not found at ${ORDS_BIN}. Please run installation first."
    exit 1
fi

echo "Starting ORDS..."

# Kill existing ORDS if running (more thorough cleanup)
echo "Stopping any existing ORDS processes..."
PORT_PID=$(netstat -tulnp 2>/dev/null | grep :${ORDS_PORT} | awk '{print $7}' | cut -d/ -f1)
if [ ! -z "$PORT_PID" ]; then
    echo "Killing process $PORT_PID on port ${ORDS_PORT}..."
    kill -9 $PORT_PID 2>/dev/null
fi
pkill -9 -f "ords" 2>/dev/null
sleep 3

# Ensure images directory exists and is populated
if [ ! -d "${APEX_IMAGES}" ] || [ -z "$(ls -A ${APEX_IMAGES} 2>/dev/null)" ]; then
    echo "Copying APEX images to ${APEX_IMAGES}..."
    rm -rf ${APEX_IMAGES}
    cp -r /opt/oracle/apex/images ${APEX_IMAGES}
    echo "Copied $(find ${APEX_IMAGES} -type f | wc -l) image files"
fi

# Verify ORDS config exists
if [ ! -f "${ORDS_CONFIG}/databases/default/pool.xml" ]; then
    echo "ERROR: ORDS configuration not found at ${ORDS_CONFIG}"
    echo "Please run ORDS installation first"
    exit 1
fi

# Verify images directory
if [ ! -d "${APEX_IMAGES}" ] || [ -z "$(ls -A ${APEX_IMAGES} 2>/dev/null)" ]; then
    echo "WARNING: Images directory empty or missing, this will cause image serving issues"
fi

# Start ORDS with proper image serving
cd "${ORDS_CONFIG}"
echo "Starting ORDS from config: ${ORDS_CONFIG}"
echo "Using images from: ${APEX_IMAGES}"

nohup ${ORDS_BIN} --config "${ORDS_CONFIG}" serve \
  --apex-images "${APEX_IMAGES}" \
  --port ${ORDS_PORT} > "${ORDS_LOG}" 2>&1 &

ORDS_PID=$!
echo "ORDS started with PID: ${ORDS_PID}"
echo "Waiting for initialization (log: ${ORDS_LOG})..."

for i in {1..60}; do
    if grep -q "Oracle REST Data Services initialized" "${ORDS_LOG}" 2>/dev/null; then
        echo "✓ ORDS started successfully!"
        sleep 2
        
        # Quick verification
        if netstat -tulnp 2>/dev/null | grep -q :${ORDS_PORT}; then
            echo "✓ ORDS listening on port ${ORDS_PORT}"
        fi
        
        echo ""
        echo "=================================================================="
        echo "🚀 APEX Access URLs:"
        echo "=================================================================="
        echo "  Application Builder:  http://localhost:${ORDS_PORT}/ords/f?p=4550:1"
        echo "  SQL Developer Web:    http://localhost:${ORDS_PORT}/ords/sql-developer/"
        echo "  Images:              http://localhost:${ORDS_PORT}/i/apex_ui/css/Core.css"
        echo ""
        echo "🔐 Login Credentials:"
        echo "  Workspace: INTERNAL"
        echo "  Username:  ADMIN"
        echo "  Password:  Demasy1986"
        echo "=================================================================="
        exit 0
    fi
    
    # Check for errors
    if grep -qi "error\|failed\|exception" "${ORDS_LOG}" 2>/dev/null; then
        echo "⚠ Detected errors in log, but continuing to wait..."
    fi
    
    sleep 1
done

echo "⚠ Timeout waiting for ORDS initialization"
echo "Check logs: tail -f ${ORDS_LOG}"
exit 1
EOFSCRIPT

chmod +x /usr/local/bin/start-ords

cat > /usr/local/bin/stop-ords << 'EOFSCRIPT'
#!/bin/bash
echo "Stopping ORDS..."

# Kill any Java process on port 8080
PORT_PID=$(netstat -tulnp 2>/dev/null | grep :8080 | awk '{print $7}' | cut -d/ -f1)
if [ ! -z "$PORT_PID" ]; then
    echo "Killing process $PORT_PID on port 8080..."
    kill -9 $PORT_PID 2>/dev/null
    sleep 2
fi

# Kill ORDS process (matches java command running ords)
ORDS_PIDS=$(pgrep -f "ords" 2>/dev/null)
if [ ! -z "$ORDS_PIDS" ]; then
    echo "Killing ORDS processes: $ORDS_PIDS"
    pkill -9 -f "ords" 2>/dev/null
    sleep 2
fi

# Verify stopped
if netstat -tulnp 2>/dev/null | grep -q :8080; then
    echo "✗ ORDS still running on port 8080"
    netstat -tulnp 2>/dev/null | grep :8080
    exit 1
else
    echo "✓ ORDS stopped successfully"
fi
EOFSCRIPT

chmod +x /usr/local/bin/stop-ords

log_success "Management scripts created"

################################################################################
# STEP 11: Start ORDS and Verify Installation
################################################################################
log_info "Step 11: Starting ORDS..."

# Ensure all accounts are unlocked before starting ORDS
log_info "Final account unlock and password verification (resetting to default password)..."
# Reset and unlock a standard list of users to the configured APEX_PASSWORD.
sql sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba <<EOSQL
ALTER SESSION SET CONTAINER=FREEPDB1;
BEGIN
    FOR r IN (
        SELECT username FROM dba_users
        WHERE username IN ('APEX_PUBLIC_USER','APEX_PUBLIC_ROUTER','APEX_240200','ORDS_PUBLIC_USER','ORDS_METADATA')
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'ALTER USER ' || r.username || ' IDENTIFIED BY ${APEX_PASSWORD}';
            EXECUTE IMMEDIATE 'ALTER USER ' || r.username || ' ACCOUNT UNLOCK';
            DBMS_OUTPUT.PUT_LINE('✓ Reset & unlocked: ' || r.username);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  Could not reset/unlock ' || r.username || ': ' || SQLERRM);
        END;
    END LOOP;
END;
/

-- Verify account status
SELECT 'Account Status: ' || username || ' - ' || account_status 
FROM dba_users 
WHERE username IN ('APEX_PUBLIC_USER','APEX_PUBLIC_ROUTER','APEX_240200','ORDS_PUBLIC_USER','ORDS_METADATA')
ORDER BY username;

EXIT
EOSQL

# Kill any existing ORDS processes thoroughly
log_info "Stopping any existing ORDS processes..."
PORT_PID=$(netstat -tulnp 2>/dev/null | grep :8080 | awk '{print $7}' | cut -d/ -f1 | head -1)
if [ ! -z "$PORT_PID" ]; then
    log_info "Killing process $PORT_PID on port 8080..."
    kill -9 $PORT_PID 2>/dev/null || true
fi
pkill -9 -f "ords" 2>/dev/null || true
sleep 3

# Verify ORDS config and images before starting
if [ ! -f "/opt/oracle/ords/config/databases/default/pool.xml" ]; then
    log_error "ORDS configuration missing! Installation may have failed."
    exit 1
fi

if [ ! -d "/tmp/i" ] || [ -z "$(ls -A /tmp/i 2>/dev/null)" ]; then
    log_warn "Images directory empty, copying now..."
    rm -rf /tmp/i
    cp -r /opt/oracle/apex/images /tmp/i
    log_info "Copied $(find /tmp/i -type f | wc -l) image files"
fi

# Start ORDS in background
log_info "Starting ORDS service..."
nohup /opt/oracle/ords/bin/ords --config /opt/oracle/ords/config serve --apex-images /tmp/i --port 8080 > /tmp/ords.log 2>&1 &
ORDS_PID=$!
log_info "ORDS started with PID: ${ORDS_PID}"

log_info "Waiting for ORDS to initialize (checking for 60 seconds)..."

# Monitor ORDS startup
ORDS_RUNNING=false
for i in {1..60}; do
    # Check if ORDS initialized
    if grep -q "Oracle REST Data Services initialized" /tmp/ords.log 2>/dev/null; then
        ORDS_RUNNING=true
        log_success "ORDS initialized successfully!"
        break
    fi
    
    # Check for critical errors
    if grep -qi "could not start\|address already in use\|failed to start" /tmp/ords.log 2>/dev/null; then
        log_error "ORDS failed to start. Check /tmp/ords.log"
        tail -20 /tmp/ords.log
        exit 1
    fi
    
    # Show progress
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "."
    fi
    
    sleep 1
done
echo ""

# Verify port is listening
if [ "$ORDS_RUNNING" = true ]; then
    sleep 3
    if ! netstat -tulnp 2>/dev/null | grep -q :8080; then
        log_warn "ORDS initialized but not listening on port 8080"
        ORDS_RUNNING=false
    fi
fi

################################################################################
# STEP 12: Final Verification
################################################################################
log_info "Step 12: Final verification..."

echo ""
echo "=================================================================="
echo " Database Status:"
echo "=================================================================="

sql -S sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL'
SET HEADING OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER=FREEPDB1;

-- APEX Version
SELECT '  ✓ APEX Version: ' || version || ' (Status: ' || status || ')' 
FROM dba_registry WHERE comp_id='APEX';

-- APEX Schemas
SELECT '  ✓ APEX Schema: ' || username 
FROM dba_users 
WHERE username LIKE 'APEX%' 
ORDER BY username;

-- ORDS Schemas
SELECT '  ✓ ORDS Schema: ' || username 
FROM dba_users 
WHERE username LIKE 'ORDS%' 
ORDER BY username;

EXIT
EOSQL

echo ""
echo "=================================================================="
echo " ADMIN User Status:"
echo "=================================================================="

sql -S sys/${SYS_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba << 'EOSQL'
SET HEADING OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER=FREEPDB1;
BEGIN APEX_UTIL.SET_WORKSPACE('INTERNAL'); END;
/

SELECT '  Username: ' || user_name || ' | Is Admin: ' || is_admin || ' | Account Locked: ' || account_locked 
FROM apex_workspace_apex_users 
WHERE workspace_name = 'INTERNAL' AND user_name = 'ADMIN';

EXIT
EOSQL

echo ""
echo "=================================================================="
echo " ORDS Server Status:"
echo "=================================================================="

if [ "$ORDS_RUNNING" = true ]; then
    echo "  ✓ ORDS Running on port 8080"
    
    # Test HTTP endpoints with retry
    log_info "Testing HTTP endpoints (with retry)..."
    
    # Give ORDS a moment to fully initialize
    sleep 5
    
    # Test APEX endpoint with retries
    APEX_CODE="000"
    for retry in {1..3}; do
        APEX_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ords/f?p=4550:1 2>/dev/null || echo "000")
        if [ "$APEX_CODE" = "302" ] || [ "$APEX_CODE" = "200" ]; then
            break
        fi
        sleep 3
    done
    if [ "$APEX_CODE" = "302" ] || [ "$APEX_CODE" = "200" ]; then
        echo "  ✓ APEX endpoint responding (HTTP $APEX_CODE)"
    else
        echo "  ⚠ APEX endpoint returned HTTP $APEX_CODE (may need more time)"
        echo "  --- Last 50 lines of ORDS log ---"
        tail -50 /tmp/ords.log
    fi
    
    # Test static images (CSS file) with retries
    IMAGE_CODE="000"
    for retry in {1..3}; do
        IMAGE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/i/apex_ui/css/Core.css 2>/dev/null || echo "000")
        if [ "$IMAGE_CODE" = "200" ]; then
            break
        fi
        sleep 2
    done
    if [ "$IMAGE_CODE" = "200" ]; then
        echo "  ✓ APEX images responding (HTTP $IMAGE_CODE)"
    else
        echo "  ⚠ APEX images returned HTTP $IMAGE_CODE"
        echo "  --- Last 50 lines of ORDS log ---"
        tail -50 /tmp/ords.log
        if [ -d "/tmp/i" ]; then
            IMGS=$(find /tmp/i -type f 2>/dev/null | wc -l)
            echo "     Images directory: /tmp/i exists with $IMGS files"
            if [ "$IMGS" -eq 0 ]; then
                echo "     ERROR: Images directory is empty! Copying now..."
                rm -rf /tmp/i
                cp -r /opt/oracle/apex/images /tmp/i
                echo "     Copied $(find /tmp/i -type f | wc -l) files. Restart ORDS: stop-ords && start-ords"
            fi
        else
            echo "     ERROR: Images directory /tmp/i does not exist!"
            echo "     Copying images now..."
            cp -r /opt/oracle/apex/images /tmp/i
            echo "     Copied $(find /tmp/i -type f | wc -l) files. Restart ORDS: stop-ords && start-ords"
        fi
    fi
    
    # Test SQL Developer Web
    SQLDEV_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ords/sql-developer 2>/dev/null || echo "000")
    if [ "$SQLDEV_CODE" = "200" ] || [ "$SQLDEV_CODE" = "302" ]; then
        echo "  ✓ SQL Developer Web responding (HTTP $SQLDEV_CODE)"
    else
        echo "  ⚠ SQL Developer Web returned HTTP $SQLDEV_CODE"
    fi
else
    echo "  ⚠ ORDS not running on port 8080"
    echo "  ℹ Check logs: tail -f /tmp/ords.log"
fi

################################################################################
# INSTALLATION COMPLETE
################################################################################

# Clear terminal and show Demasy Labs banner
print_demasy_banner "APEX Installation Complete ✅"
echo ""
echo ""
echo "🚀 APEX Details:"
echo "  ─────────────────────────────────────────────────────────────"
echo "  Application Builder:  http://localhost:8080/ords/f?p=4550:1"
echo "  SQL Developer Web:    http://localhost:8080/ords/sql-developer/"
echo "  APEX Admin:           http://localhost:8080/ords/apex_admin"
echo ""
echo "🔐 Login Credentials:"
echo "  ─────────────────────────────────────────────────────────────"
echo "  Workspace: INTERNAL"
echo "  Username:  ${APEX_ADMIN_USERNAME}"
echo "  Password:  ${APEX_PASSWORD}"
echo "  Email:     ${APEX_EMAIL}"
echo ""
echo "📋 Management Commands:"
echo "  ─────────────────────────────────────────────────────────────"
echo "  Start ORDS:  start-ords"
echo "  Stop ORDS:   stop-ords"
echo "  View Logs:   tail -f /tmp/ords.log"
echo "  APEX Logs:   tail -f /tmp/apex_install.log"
echo ""
echo "📦 Installed Components:"
echo "  ─────────────────────────────────────────────────────────────"
echo "  APEX:  /opt/oracle/apex/ ($(du -sh /opt/oracle/apex 2>/dev/null | cut -f1 || echo 'N/A'))"
echo "  ORDS:  /opt/oracle/ords/ ($(du -sh /opt/oracle/ords 2>/dev/null | cut -f1 || echo 'N/A'))"
echo "  Images: /tmp/i/ ($(du -sh /tmp/i 2>/dev/null | cut -f1 || echo 'N/A') - $(find /tmp/i -type f 2>/dev/null | wc -l) files)"
echo "  Config: /opt/oracle/ords/config/"
echo ""
echo "🔧 Troubleshooting:"
echo "  ─────────────────────────────────────────────────────────────"
echo "  If APEX images not loading:"
echo "    1. Verify: ls -la /tmp/i | wc -l (should show ~855 files)"
echo "    2. Restart: stop-ords && start-ords"
echo "    3. Check logs: tail -f /tmp/ords.log"
echo ""
echo "  If connection errors:"
echo "    1. Check accounts: SELECT username, account_status FROM dba_users WHERE username LIKE 'APEX%' OR username LIKE 'ORDS%';"
echo "    2. Unlock: ALTER USER ORDS_PUBLIC_USER ACCOUNT UNLOCK;"
echo ""
echo "=================================================================="
echo ""
