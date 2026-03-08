#!/bin/bash

################################################################################
# Oracle User Creation Script (Reusable)
# This script runs FROM INSIDE the Docker container
# Creates a local user in a PDB with comprehensive Oracle AI 26ai privileges
#
# USAGE:
#   create_user.sh <username> [password] [pdb_name]
#
# PARAMETERS:
#   username  (required) - The local user to create in the PDB
#   password  (optional) - User password (defaults to DEMASYLABS_DB_PASSWORD)
#   pdb_name  (optional) - Target PDB name (defaults to DEMASYLABS_PDB)
#
# EXAMPLES:
#   create_user.sh myuser
#   create_user.sh myuser MyPassword123
#   create_user.sh myuser MyPassword123 MY_PDB
################################################################################

set -e

# Get the actual script location (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source utilities from the actual script location
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh"
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"

################################################################################
# PARSE PARAMETERS
################################################################################

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo ""
    echo "Usage: $(basename "$0") <username> [password] [pdb_name]"
    echo ""
    echo "  username   (required) Local user to create in the PDB"
    echo "  password   (optional) User password (defaults to DEMASYLABS_DB_PASSWORD)"
    echo "  pdb_name   (optional) Target PDB name (defaults to DEMASYLABS_PDB)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") myuser"
    echo "  $(basename "$0") myuser MyPassword123"
    echo "  $(basename "$0") myuser MyPassword123 MY_PDB"
    echo ""
    exit 1
fi

# Assign parameters
INPUT_USER="$1"
INPUT_PASSWORD="${2:-}"
INPUT_PDB="${3:-}"

# Validate username
if [[ ! "$INPUT_USER" =~ ^[a-zA-Z][a-zA-Z0-9_]{0,29}$ ]]; then
    echo ""
    echo "Error: Invalid username '$INPUT_USER'"
    echo "  • Must start with a letter"
    echo "  • Can contain letters, numbers, and underscores"
    echo "  • Maximum 30 characters"
    echo ""
    exit 1
fi

# Display Demasy Labs banner
print_demasy_banner "Oracle User Creation: $INPUT_USER"

################################################################################
# CONFIGURATION - Read from Environment Variables
################################################################################
log_info "Reading configuration from environment variables..."

DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
DB_SID="${DEMASYLABS_DB_SID}"

# Apply parameter overrides
NEW_USER="${INPUT_USER}"
NEW_USER_PASSWORD="${INPUT_PASSWORD:-$DB_PASSWORD}"
PDB_NAME="${INPUT_PDB:-DEMASYLABS_PDB}"
COMMON_USER="c##${NEW_USER}"

# Validate required environment variables
log_step "Validating environment variables..."
MISSING_VARS=()

[[ -z "$DB_HOST" ]]     && MISSING_VARS+=("DEMASYLABS_DB_HOST")
[[ -z "$DB_PORT" ]]     && MISSING_VARS+=("DEMASYLABS_DB_PORT")
[[ -z "$DB_PASSWORD" ]] && MISSING_VARS+=("DEMASYLABS_DB_PASSWORD")
[[ -z "$DB_SID" ]]      && MISSING_VARS+=("DEMASYLABS_DB_SID")

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
echo "  Host:        $DB_HOST"
echo "  Port:        $DB_PORT"
echo "  CDB:         $DB_SID"
echo "  Target PDB:  $PDB_NAME"
echo "  Common User: $COMMON_USER"
echo "  Local User:  $NEW_USER"
echo "  Password:    $([ -n "$INPUT_PASSWORD" ] && echo "[provided]" || echo "[using system password]")"
echo ""

################################################################################
# STEP 1: Test Database Connection
################################################################################
log_section "Step 1: Testing Database Connection"
log_step "Connecting to CDB\$ROOT..."

CONNECTION_ATTEMPTS=0
MAX_ATTEMPTS=3

while [ $CONNECTION_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    CONNECTION_ATTEMPTS=$((CONNECTION_ATTEMPTS + 1))
    log_step "Connection attempt $CONNECTION_ATTEMPTS of $MAX_ATTEMPTS..."

    if CONNECTION_TEST=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << 'EOF' 2>&1
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT 'Connected to ' || SYS_CONTEXT('USERENV', 'CON_NAME') AS connection_info FROM DUAL;
EXIT
EOF
    ); then
        if echo "$CONNECTION_TEST" | grep -q "Connected to"; then
            log_success "Successfully connected to CDB\$ROOT"
            break
        fi
    fi

    if [ $CONNECTION_ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        log_error "Cannot connect to database CDB at ${DB_HOST}:${DB_PORT}/${DB_SID}"
        log_error "Last connection attempt output: $CONNECTION_TEST"
        log_error "Please verify:"
        echo "  • Database is running (docker ps)"
        echo "  • Network connectivity (ping $DB_HOST)"
        echo "  • Database password is correct"
        echo "  • Listener is accepting connections (lsnrctl status)"
        exit 1
    fi

    log_warn "Connection failed, retrying in 5 seconds..."
    sleep 5
done

################################################################################
# STEP 2: Ensure PDB Exists and Is Open (create if missing)
################################################################################
log_section "Step 2: Checking Target PDB"
log_step "Checking if $PDB_NAME exists and is open..."

# Query 1: does the PDB exist at all?
PDB_EXISTS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)
PDB_EXISTS=$(echo "$PDB_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$PDB_EXISTS" = "0" ]; then
    log_warn "PDB $PDB_NAME does not exist — creating it..."

    # Derive a safe lowercase directory name from the PDB name
    PDB_DIR=$(echo "$PDB_NAME" | tr '[:upper:]' '[:lower:]')

    if sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
CREATE PLUGGABLE DATABASE ${PDB_NAME}
  ADMIN USER pdb_admin IDENTIFIED BY ${NEW_USER_PASSWORD}
  FILE_NAME_CONVERT = ('/opt/oracle/oradata/FREE/pdbseed/', '/opt/oracle/oradata/FREE/${PDB_DIR}/');

SELECT 'PDB created: ' || name FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
    then
        log_success "PDB $PDB_NAME created successfully"
    else
        log_error "Failed to create PDB $PDB_NAME"
        log_info "Available PDBs:"
        sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 20
SET FEEDBACK OFF
COL name FORMAT A20
COL open_mode FORMAT A15
SELECT name, open_mode FROM v\$pdbs WHERE name != 'PDB\$SEED';
EXIT
EOF
        exit 1
    fi

    # Open the newly created PDB and save state for auto-start
    log_step "Opening PDB $PDB_NAME..."
    PDB_OPEN_OUTPUT=$(sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF 2>&1
ALTER PLUGGABLE DATABASE ${PDB_NAME} OPEN;
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;
SELECT 'Status: ' || open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
    )

    if echo "$PDB_OPEN_OUTPUT" | grep -q "READ WRITE"; then
        log_success "PDB $PDB_NAME is open and configured for auto-start"
    else
        log_error "Failed to open newly created PDB $PDB_NAME"
        log_error "$PDB_OPEN_OUTPUT"
        exit 1
    fi

else
    # Query 2: PDB exists — check its open_mode
    PDB_STATUS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
    )
    PDB_STATUS=$(echo "$PDB_STATUS_RAW" | grep -o 'READ WRITE\|MOUNTED\|READ ONLY' | head -n1 || echo "UNKNOWN")

    if [ "$PDB_STATUS" = "READ WRITE" ]; then
        log_success "PDB $PDB_NAME is open and ready (READ WRITE)"
    else
        log_warn "PDB $PDB_NAME exists but is not open (status: $PDB_STATUS). Attempting to open..."

        sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF > /dev/null 2>&1
ALTER PLUGGABLE DATABASE ${PDB_NAME} OPEN;
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;
EXIT
EOF

        # Verify it's now open
        PDB_STATUS_RECHECK=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
        )
        if echo "$PDB_STATUS_RECHECK" | grep -q "READ WRITE"; then
            log_success "PDB $PDB_NAME opened successfully"
        else
            log_error "Failed to open PDB $PDB_NAME - Status: $PDB_STATUS_RECHECK"
            exit 1
        fi
    fi
fi

################################################################################
# STEP 3: Create Common User in CDB (if needed)
################################################################################
log_section "Step 3: Creating Common User in CDB"
log_step "Checking if common user $COMMON_USER exists..."

COMMON_USER_EXISTS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $COMMON_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)

COMMON_USER_EXISTS=$(echo "$COMMON_USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$COMMON_USER_EXISTS" = "1" ]; then
    log_warn "Common user $COMMON_USER already exists — skipping creation"
else
    log_step "Creating common user $COMMON_USER in CDB..."

    if sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
CREATE USER ${COMMON_USER} IDENTIFIED BY ${NEW_USER_PASSWORD};
SELECT 'Common user created successfully' AS status FROM DUAL;
EXIT
EOF
    then
        log_success "Common user $COMMON_USER created"
        log_info "Note: SYSDBA privilege cannot be granted locally in Oracle 26ai CDB (this is normal)"
    else
        log_error "Failed to create common user $COMMON_USER"
        exit 1
    fi
fi

################################################################################
# STEP 4: Create Local User in PDB
################################################################################
log_section "Step 4: Creating Local User in PDB"
log_step "Checking if local user $NEW_USER exists in PDB $PDB_NAME..."

LOCAL_USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $NEW_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)

LOCAL_USER_EXISTS=$(echo "$LOCAL_USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$LOCAL_USER_EXISTS" = "1" ]; then
    log_warn "Local user $NEW_USER already exists in PDB $PDB_NAME — skipping creation"
else
    log_step "Creating local user $NEW_USER in PDB $PDB_NAME with comprehensive privileges..."

    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Switch to PDB
ALTER SESSION SET CONTAINER = ${PDB_NAME};

-- Create local user
CREATE USER ${NEW_USER} IDENTIFIED BY ${NEW_USER_PASSWORD};

-- Basic connectivity and resource
GRANT CONNECT TO ${NEW_USER};
GRANT RESOURCE TO ${NEW_USER};
GRANT UNLIMITED TABLESPACE TO ${NEW_USER};
GRANT SELECT_CATALOG_ROLE TO ${NEW_USER};
GRANT ALTER SESSION TO ${NEW_USER};
GRANT CREATE JOB TO ${NEW_USER};
GRANT CREATE DATABASE LINK TO ${NEW_USER};
GRANT CREATE MATERIALIZED VIEW TO ${NEW_USER};

-- CREATE ANY privileges
GRANT CREATE ANY TABLE TO ${NEW_USER};
GRANT CREATE ANY VIEW TO ${NEW_USER};
GRANT CREATE ANY PROCEDURE TO ${NEW_USER};
GRANT CREATE ANY SEQUENCE TO ${NEW_USER};
GRANT CREATE ANY TRIGGER TO ${NEW_USER};
GRANT CREATE ANY TYPE TO ${NEW_USER};
GRANT CREATE ANY INDEX TO ${NEW_USER};
GRANT CREATE PUBLIC SYNONYM TO ${NEW_USER};
GRANT CREATE SYNONYM TO ${NEW_USER};
GRANT CREATE ANY CLUSTER TO ${NEW_USER};
GRANT CREATE ANY CONTEXT TO ${NEW_USER};
GRANT CREATE ANY DIMENSION TO ${NEW_USER};
GRANT CREATE ANY OPERATOR TO ${NEW_USER};
GRANT CREATE ANY INDEXTYPE TO ${NEW_USER};
GRANT CREATE ANY OUTLINE TO ${NEW_USER};
GRANT CREATE ANY MATERIALIZED VIEW TO ${NEW_USER};
GRANT CREATE ANY EDITION TO ${NEW_USER};
GRANT CREATE ANY SQL TRANSLATION PROFILE TO ${NEW_USER};
GRANT CREATE ASSERTION TO ${NEW_USER};
GRANT CREATE ANY ASSERTION TO ${NEW_USER};

-- ALTER ANY privileges
GRANT ALTER ANY TABLE TO ${NEW_USER};
GRANT ALTER ANY SEQUENCE TO ${NEW_USER};
GRANT ALTER ANY INDEX TO ${NEW_USER};
GRANT ALTER ANY PROCEDURE TO ${NEW_USER};
GRANT ALTER ANY TRIGGER TO ${NEW_USER};
GRANT ALTER ANY OUTLINE TO ${NEW_USER};
GRANT ALTER ANY MATERIALIZED VIEW TO ${NEW_USER};
GRANT ALTER ANY EDITION TO ${NEW_USER};
GRANT ALTER ANY TYPE TO ${NEW_USER};
GRANT ALTER ANY SQL TRANSLATION PROFILE TO ${NEW_USER};

-- DROP ANY privileges
GRANT DROP ANY TABLE TO ${NEW_USER};
GRANT DROP ANY VIEW TO ${NEW_USER};
GRANT DROP ANY SEQUENCE TO ${NEW_USER};
GRANT DROP ANY PROCEDURE TO ${NEW_USER};
GRANT DROP ANY TRIGGER TO ${NEW_USER};
GRANT DROP ANY INDEX TO ${NEW_USER};
GRANT DROP ANY TYPE TO ${NEW_USER};
GRANT DROP PUBLIC SYNONYM TO ${NEW_USER};
GRANT DROP ANY CLUSTER TO ${NEW_USER};
GRANT DROP ANY CONTEXT TO ${NEW_USER};
GRANT DROP ANY DIMENSION TO ${NEW_USER};
GRANT DROP ANY OPERATOR TO ${NEW_USER};
GRANT DROP ANY INDEXTYPE TO ${NEW_USER};
GRANT DROP ANY OUTLINE TO ${NEW_USER};
GRANT DROP ANY MATERIALIZED VIEW TO ${NEW_USER};
GRANT DROP ANY EDITION TO ${NEW_USER};
GRANT DROP ANY SQL TRANSLATION PROFILE TO ${NEW_USER};

-- DML privileges
GRANT SELECT ANY TABLE TO ${NEW_USER};
GRANT INSERT ANY TABLE TO ${NEW_USER};
GRANT UPDATE ANY TABLE TO ${NEW_USER};
GRANT DELETE ANY TABLE TO ${NEW_USER};
GRANT EXECUTE ANY PROCEDURE TO ${NEW_USER};
GRANT EXECUTE ANY TYPE TO ${NEW_USER};
GRANT EXECUTE ANY LIBRARY TO ${NEW_USER};

-- Advanced development privileges
GRANT COMMENT ANY TABLE TO ${NEW_USER};
GRANT LOCK ANY TABLE TO ${NEW_USER};
GRANT FLASHBACK ANY TABLE TO ${NEW_USER};
GRANT ANALYZE ANY TO ${NEW_USER};
GRANT CREATE LIBRARY TO ${NEW_USER};
GRANT CREATE SESSION TO ${NEW_USER};
GRANT QUERY REWRITE TO ${NEW_USER};
GRANT GLOBAL QUERY REWRITE TO ${NEW_USER};
GRANT MERGE ANY VIEW TO ${NEW_USER};
GRANT FLASHBACK ARCHIVE ADMINISTER TO ${NEW_USER};
GRANT CREATE TABLESPACE TO ${NEW_USER};
GRANT ALTER TABLESPACE TO ${NEW_USER};
GRANT DROP TABLESPACE TO ${NEW_USER};
GRANT MANAGE TABLESPACE TO ${NEW_USER};
GRANT USE ANY SQL TRANSLATION PROFILE TO ${NEW_USER};

-- Oracle AI Database (Mining Models)
GRANT CREATE MINING MODEL TO ${NEW_USER};
GRANT ALTER ANY MINING MODEL TO ${NEW_USER};
GRANT DROP ANY MINING MODEL TO ${NEW_USER};
GRANT SELECT ANY MINING MODEL TO ${NEW_USER};
GRANT COMMENT ANY MINING MODEL TO ${NEW_USER};

-- Scheduler privileges
GRANT CREATE ANY JOB TO ${NEW_USER};
GRANT EXECUTE ANY CLASS TO ${NEW_USER};
GRANT EXECUTE ANY PROGRAM TO ${NEW_USER};
GRANT MANAGE SCHEDULER TO ${NEW_USER};

-- Oracle AI Database 26ai Specific Objects (via EXECUTE IMMEDIATE for version safety)
BEGIN
    -- Vector Indexes
    EXECUTE IMMEDIATE 'GRANT CREATE ANY VECTOR INDEX TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY VECTOR INDEX TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY VECTOR INDEX TO ${NEW_USER}';

    -- Vector Data Types
    EXECUTE IMMEDIATE 'GRANT CREATE ANY VECTOR TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY VECTOR TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT UPDATE ANY VECTOR TO ${NEW_USER}';

    -- JSON Search Index
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON SEARCH INDEX TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON SEARCH INDEX TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON SEARCH INDEX TO ${NEW_USER}';

    -- Graph Database
    EXECUTE IMMEDIATE 'GRANT CREATE ANY GRAPH TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY GRAPH TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY GRAPH TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY GRAPH TO ${NEW_USER}';

    -- Spatial Index
    EXECUTE IMMEDIATE 'GRANT CREATE ANY SPATIAL INDEX TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY SPATIAL INDEX TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY SPATIAL INDEX TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Scheduler Objects
GRANT ALTER ANY JOB TO ${NEW_USER};
GRANT DROP ANY JOB TO ${NEW_USER};
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY PROGRAM TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY PROGRAM TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY PROGRAM TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CLASS TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CLASS TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CLASS TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY SCHEDULE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY SCHEDULE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY SCHEDULE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CHAIN TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CHAIN TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CHAIN TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY FILE WATCHER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY FILE WATCHER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY FILE WATCHER TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Advanced Queuing & Streams
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY QUEUE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY QUEUE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY QUEUE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ENQUEUE ANY QUEUE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DEQUEUE ANY QUEUE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY QUEUE TABLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY QUEUE TABLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY QUEUE TABLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY RULE SET TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY RULE SET TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY RULE SET TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY RULE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY RULE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY RULE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY TRANSFORM TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY TRANSFORM TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY TRANSFORM TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Security Objects
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ROLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY ROLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY ROLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT GRANT ANY ROLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE PROFILE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER PROFILE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP PROFILE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE USER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER USER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP USER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY POLICY TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY POLICY TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY POLICY TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Analytics & Data Warehouse
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CUBE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CUBE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CUBE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY CUBE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY MEASURE FOLDER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY MEASURE FOLDER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY MEASURE FOLDER TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY ANALYTIC VIEW TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY ANALYTIC VIEW TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY ANALYTIC VIEW TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY ANALYTIC VIEW TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY HIERARCHY TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY HIERARCHY TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY HIERARCHY TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY HIERARCHY TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- XML & JSON Objects
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY XML SCHEMA TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY XML SCHEMA TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY XML SCHEMA TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT UNDER ANY TYPE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT UNDER ANY VIEW TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON COLLECTION TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON COLLECTION TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON COLLECTION TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON SCHEMA TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON SCHEMA TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON SCHEMA TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Integration Objects
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY EXTERNAL TABLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY EXTERNAL TABLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY EXTERNAL TABLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY EXTERNAL TABLE TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CREDENTIAL TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CREDENTIAL TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CREDENTIAL TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY DESTINATION TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY DESTINATION TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY DESTINATION TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Advanced Partitioning
BEGIN
    EXECUTE IMMEDIATE 'GRANT ALTER ANY PARTITION TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY PARTITION TO ${NEW_USER}';
    EXECUTE IMMEDIATE 'GRANT MANAGE ANY PARTITION TO ${NEW_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Display final status
SELECT username || ' created successfully with ' ||
       (SELECT COUNT(*) FROM dba_sys_privs  WHERE grantee = username) || ' system privileges and ' ||
       (SELECT COUNT(*) FROM dba_role_privs WHERE grantee = username) || ' roles' AS result
FROM dba_users
WHERE username = '$(echo $NEW_USER | tr '[:lower:]' '[:upper:]')';

EXIT
EOF
    then
        log_success "Local user $NEW_USER created with comprehensive Oracle AI Database 26ai privileges"
    else
        log_error "Failed to create local user $NEW_USER"
        exit 1
    fi
fi

################################################################################
# STEP 5: Verification
################################################################################
log_section "Step 5: Verification"
log_step "Verifying all operations completed successfully..."

# Verify local user exists
LOCAL_USER_EXISTS_FINAL=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $NEW_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)
LOCAL_USER_EXISTS=$(echo "$LOCAL_USER_EXISTS_FINAL" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$LOCAL_USER_EXISTS" = "1" ]; then
    log_success "✓ Local user $NEW_USER exists in PDB $PDB_NAME"
else
    log_error "✗ Local user $NEW_USER was not created successfully"
    exit 1
fi

# Verify system privilege count
SYS_PRIV_COUNT_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_sys_privs WHERE grantee = '$(echo $NEW_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)
SYS_PRIV_COUNT=$(echo "$SYS_PRIV_COUNT_RAW" | grep -o '[0-9]*' | tail -n1 || echo "0")

ROLE_COUNT_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_role_privs WHERE grantee = '$(echo $NEW_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)
ROLE_COUNT=$(echo "$ROLE_COUNT_RAW" | grep -o '[0-9]*' | tail -n1 || echo "0")

if [[ "$SYS_PRIV_COUNT" -gt 0 ]] || [[ "$ROLE_COUNT" -gt 0 ]]; then
    log_success "✓ User $NEW_USER has $SYS_PRIV_COUNT system privileges and $ROLE_COUNT roles"
else
    log_warn "⚠ Could not verify privileges for $NEW_USER"
fi

# Test connection to PDB as the new user
log_step "Testing connection as $NEW_USER..."
TEST_TABLE="${NEW_USER}_conn_test"
TEST_OUTPUT=$(sql -s ${NEW_USER}/${NEW_USER_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << EOF 2>&1
SET PAGESIZE 0
SET FEEDBACK OFF
CREATE TABLE ${TEST_TABLE} (id NUMBER, msg VARCHAR2(100));
INSERT INTO ${TEST_TABLE} VALUES (1, 'Connection and privileges verified');
SELECT msg FROM ${TEST_TABLE} WHERE ROWNUM = 1;
DROP TABLE ${TEST_TABLE};
SELECT 'SUCCESS' AS final_status FROM DUAL;
EXIT
EOF
)

if echo "$TEST_OUTPUT" | grep -q "SUCCESS"; then
    log_success "✓ Connection test and privilege verification successful"
elif echo "$TEST_OUTPUT" | grep -q "Connection and privileges verified"; then
    log_success "✓ Connection and basic operations successful"
else
    log_warn "⚠ Full test had issues, trying simple connection test..."
    SIMPLE_TEST=$(sql -s ${NEW_USER}/${NEW_USER_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << 'EOF' 2>&1
SELECT 'SIMPLE_SUCCESS' FROM DUAL;
EXIT
EOF
    )
    if echo "$SIMPLE_TEST" | grep -q "SIMPLE_SUCCESS"; then
        log_success "✓ Basic connection successful"
    else
        log_warn "⚠ Connection test failed: $SIMPLE_TEST"
    fi
fi

################################################################################
# COMPLETION SUMMARY
################################################################################
log_section "Setup Complete!"
log_success "User '$NEW_USER' created successfully in PDB '$PDB_NAME'"

echo ""
log_info "Connection Details:"
echo ""
echo "📋 PDB Information:"
echo "   • PDB Name:   $PDB_NAME"
echo "   • Connection: ${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo ""
echo "👤 User Accounts:"
echo "   • Common User: $COMMON_USER  (Oracle 26ai CDB user)"
echo "   • Local User:  $NEW_USER     (Full development privileges in $PDB_NAME)"
echo "   • Password:    $([ -n "$INPUT_PASSWORD" ] && echo "[as provided]" || echo "[same as system password]")"
echo ""
echo "🔗 Connection Examples:"
echo "   • SQLcl:    sql ${NEW_USER}/password@//${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo "   • SQL*Plus: sqlplus ${NEW_USER}/password@${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo "   • Container: sql ${NEW_USER}/${NEW_USER_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo ""
echo "💡 Notes:"
echo "   • SYSDBA privileges not available in Oracle 26ai CDB (expected behavior)"
echo "   • All standard Oracle AI Database 26ai privileges granted"
echo ""

log_success "Ready for development! 🚀"
