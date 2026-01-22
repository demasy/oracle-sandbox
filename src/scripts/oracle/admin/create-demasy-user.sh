#!/bin/bash

################################################################################
# DEMASYLABS PDB and User Creation Script
# This script runs FROM INSIDE the Docker container
# Creates DEMASYLABS_PDB pluggable database and demasy user
################################################################################

set -e

# Get the actual script location (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source utilities from the actual script location
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh" 
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"

# Display Demasy Labs banner
print_demasy_banner "DEMASYLABS PDB and User Creation"

################################################################################
# CONFIGURATION - Read from Environment Variables
################################################################################
log_info "Reading configuration from environment variables..."

DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
DB_SID="${DEMASYLABS_DB_SID}"
DB_SERVICE="${DEMASYLABS_DB_SERVICE}"
PDB_NAME="DEMASYLABS_PDB"
DEMASY_USER="demasy"
COMMON_USER="c##demasy"

# Validate required environment variables
log_step "Validating environment variables..."
MISSING_VARS=()

[[ -z "$DB_HOST" ]] && MISSING_VARS+=("DEMASYLABS_DB_HOST")
[[ -z "$DB_PORT" ]] && MISSING_VARS+=("DEMASYLABS_DB_PORT")
[[ -z "$DB_PASSWORD" ]] && MISSING_VARS+=("DEMASYLABS_DB_PASSWORD")
[[ -z "$DB_SID" ]] && MISSING_VARS+=("DEMASYLABS_DB_SID")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    log_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  ✗ $var"
    done
    echo ""
    log_info "Please ensure all required environment variables are set in docker-compose.yml"
    exit 1
fi

log_success "All required environment variables are present"

# Display configuration
log_info "Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  CDB: $DB_SID"
echo "  PDB: $PDB_NAME"
echo "  Common User: $COMMON_USER"
echo "  Local User: $DEMASY_USER"
echo ""

################################################################################
# STEP 1: Test Database Connection (CDB)
################################################################################
log_section "Step 1: Testing Database Connection"
log_step "Connecting to CDB\$ROOT..."

# Test connection to CDB$ROOT using SID
if ! sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << 'EOF' > /dev/null 2>&1
SELECT 'Connected to ' || SYS_CONTEXT('USERENV', 'CON_NAME') AS connection_info FROM DUAL;
EXIT
EOF
then
    log_error "Cannot connect to database CDB at ${DB_HOST}:${DB_PORT}/${DB_SID}"
    log_error "Please verify:"
    echo "  • Database is running"
    echo "  • Network connectivity"
    echo "  • SYS/SYSTEM password is correct"
    echo "  • Listener is accepting connections"
    exit 1
fi

log_success "Successfully connected to CDB\$ROOT"

################################################################################
# STEP 2: Check if PDB Already Exists
################################################################################
log_section "Step 2: Checking PDB Status"
log_step "Checking if $PDB_NAME already exists..."

PDB_EXISTS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)

# Remove any whitespace/newlines
PDB_EXISTS=$(echo "$PDB_EXISTS" | tr -d '[:space:]')

if [ "$PDB_EXISTS" = "1" ]; then
    log_warn "PDB $PDB_NAME already exists"
    
    # Check PDB status
    PDB_STATUS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
    )
    PDB_STATUS=$(echo "$PDB_STATUS" | tr -d '[:space:]')
    
    if [ "$PDB_STATUS" = "READWRITE" ]; then
        log_success "PDB $PDB_NAME is already open and ready"
        SKIP_PDB_CREATION=true
    else
        log_warn "PDB $PDB_NAME exists but status is: $PDB_STATUS"
        log_step "Will attempt to open the PDB..."
        SKIP_PDB_CREATION=true
        NEED_TO_OPEN_PDB=true
    fi
else
    log_info "PDB $PDB_NAME does not exist, will create it"
    SKIP_PDB_CREATION=false
fi

################################################################################
# STEP 3: Create PDB (if needed)
################################################################################
if [ "$SKIP_PDB_CREATION" = false ]; then
    log_section "Step 3: Creating Pluggable Database"
    log_step "Creating PDB $PDB_NAME..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Create the pluggable database
CREATE PLUGGABLE DATABASE ${PDB_NAME}
ADMIN USER pdb_admin IDENTIFIED BY ${DB_PASSWORD}
FILE_NAME_CONVERT = ('/opt/oracle/oradata/FREE/pdbseed/', '/opt/oracle/oradata/FREE/demasylabs_pdb/');

-- Verify creation
SELECT 'PDB created successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "PDB $PDB_NAME created successfully"
        NEED_TO_OPEN_PDB=true
    else
        log_error "Failed to create PDB $PDB_NAME"
        exit 1
    fi
else
    log_info "Skipping PDB creation (already exists)"
fi

################################################################################
# STEP 4: Open PDB and Set Auto-Start
################################################################################
if [ "$NEED_TO_OPEN_PDB" = true ]; then
    log_section "Step 4: Opening and Configuring PDB"
    log_step "Opening PDB $PDB_NAME..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Open the PDB
ALTER PLUGGABLE DATABASE ${PDB_NAME} OPEN;

-- Save state for auto-start
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;

-- Verify PDB is open
SELECT 'PDB opened successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "PDB $PDB_NAME is now open and configured for auto-start"
    else
        log_error "Failed to open PDB $PDB_NAME"
        exit 1
    fi
else
    log_info "PDB is already open"
fi

################################################################################
# STEP 5: Create Common User (if needed)
################################################################################
log_section "Step 5: Creating Common User"
log_step "Checking if common user $COMMON_USER exists..."

COMMON_USER_EXISTS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $COMMON_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)

COMMON_USER_EXISTS=$(echo "$COMMON_USER_EXISTS" | tr -d '[:space:]')

if [ "$COMMON_USER_EXISTS" = "1" ]; then
    log_warn "Common user $COMMON_USER already exists"
else
    log_step "Creating common user $COMMON_USER..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Create common user
CREATE USER ${COMMON_USER} IDENTIFIED BY ${DB_PASSWORD};

-- Grant SYSDBA to common user across all containers  
GRANT SYSDBA TO ${COMMON_USER} CONTAINER = ALL;

-- Verify user creation
SELECT 'Common user created successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "Common user $COMMON_USER created with SYSDBA privileges"
    else
        log_error "Failed to create common user $COMMON_USER"
        exit 1
    fi
fi

################################################################################
# STEP 6: Connect to PDB and Create Local User
################################################################################
log_section "Step 6: Creating Local User in PDB"
log_step "Switching to PDB $PDB_NAME..."

# Check if local user exists in PDB
LOCAL_USER_EXISTS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Switch to PDB
ALTER SESSION SET CONTAINER = ${PDB_NAME};

-- Check if user exists
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)

LOCAL_USER_EXISTS=$(echo "$LOCAL_USER_EXISTS" | tr -d '[:space:]')

if [ "$LOCAL_USER_EXISTS" = "1" ]; then
    log_warn "Local user $DEMASY_USER already exists in PDB $PDB_NAME"
else
    log_step "Creating local user $DEMASY_USER in PDB $PDB_NAME..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Switch to PDB
ALTER SESSION SET CONTAINER = ${PDB_NAME};

-- Create local user
CREATE USER ${DEMASY_USER} IDENTIFIED BY ${DB_PASSWORD};

-- Grant comprehensive development privileges
GRANT CONNECT TO ${DEMASY_USER};
GRANT RESOURCE TO ${DEMASY_USER};
GRANT UNLIMITED TABLESPACE TO ${DEMASY_USER};
GRANT SELECT_CATALOG_ROLE TO ${DEMASY_USER};
GRANT ALTER SESSION TO ${DEMASY_USER};
GRANT CREATE JOB TO ${DEMASY_USER};
GRANT CREATE DATABASE LINK TO ${DEMASY_USER};
GRANT CREATE MATERIALIZED VIEW TO ${DEMASY_USER};
GRANT CREATE ANY TABLE TO ${DEMASY_USER};
GRANT CREATE ANY VIEW TO ${DEMASY_USER};
GRANT CREATE ANY PROCEDURE TO ${DEMASY_USER};
GRANT CREATE ANY SEQUENCE TO ${DEMASY_USER};
GRANT CREATE ANY TRIGGER TO ${DEMASY_USER};
GRANT CREATE ANY TYPE TO ${DEMASY_USER};
GRANT CREATE ANY INDEX TO ${DEMASY_USER};

-- Verify user creation
SELECT 'Local user created successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "Local user $DEMASY_USER created with comprehensive privileges"
    else
        log_error "Failed to create local user $DEMASY_USER"
        exit 1
    fi
fi

################################################################################
# STEP 7: Verification
################################################################################
log_section "Step 7: Final Verification"
log_step "Verifying all operations completed successfully..."

# Verify PDB status
log_step "Checking PDB status..."
PDB_INFO=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT name || '|' || open_mode || '|' || restricted FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)

if [[ "$PDB_INFO" == *"${PDB_NAME}|READ WRITE|NO"* ]]; then
    log_success "✓ PDB $PDB_NAME is open and unrestricted"
else
    log_warn "⚠ PDB status: $PDB_INFO"
fi

# Verify common user
log_step "Checking common user privileges..."
COMMON_PRIVS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_role_privs WHERE grantee = '$(echo $COMMON_USER | tr '[:lower:]' '[:upper:]')' AND granted_role = 'SYSDBA';
EXIT
EOF
)

COMMON_PRIVS=$(echo "$COMMON_PRIVS" | tr -d '[:space:]')
if [ "$COMMON_PRIVS" = "1" ]; then
    log_success "✓ Common user $COMMON_USER has SYSDBA privileges"
else
    log_warn "⚠ Common user $COMMON_USER may not have SYSDBA privileges"
fi

# Verify local user in PDB
log_step "Checking local user in PDB..."
LOCAL_USER_INFO=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT username || '|' || account_status FROM dba_users WHERE username = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)

if [[ "$LOCAL_USER_INFO" == *"$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')|OPEN"* ]]; then
    log_success "✓ Local user $DEMASY_USER is active in PDB $PDB_NAME"
else
    log_warn "⚠ Local user status: $LOCAL_USER_INFO"
fi

# Test connection to PDB as demasy user
log_step "Testing connection as demasy user..."
if sql -s ${DEMASY_USER}/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << 'EOF' > /dev/null 2>&1
SELECT 'Connection test successful' FROM DUAL;
EXIT
EOF
then
    log_success "✓ Connection test as $DEMASY_USER user successful"
else
    log_warn "⚠ Connection test as $DEMASY_USER user failed"
fi

################################################################################
# COMPLETION SUMMARY
################################################################################
log_section "Setup Complete!"
log_success "DEMASYLABS PDB and user setup completed successfully"

echo ""
log_info "Connection Details:"
echo ""
echo "📋 PDB Information:"
echo "   • PDB Name: $PDB_NAME"
echo "   • Connection: ${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo ""
echo "👤 User Accounts:"
echo "   • Common User: $COMMON_USER (SYSDBA privileges)"
echo "   • Local User: $DEMASY_USER (Development privileges)"
echo "   • Password: [Same as system password]"
echo ""
echo "🔗 Connection Examples:"
echo "   • SQLcl: sql ${DEMASY_USER}/password@//${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo "   • SQL*Plus: sqlplus ${DEMASY_USER}/password@${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo ""

log_success "Ready for development! 🚀"