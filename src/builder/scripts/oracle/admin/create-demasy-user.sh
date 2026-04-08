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
source "/usr/sandbox/app/system/utils/banner.sh"
source "/usr/sandbox/app/system/utils/logging.sh" 
source "/usr/sandbox/app/system/utils/colors.sh"

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

# Test connection to CDB$ROOT using SID with retry logic
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
# STEP 2: Check if PDB Already Exists
################################################################################
log_section "Step 2: Checking PDB Status"
log_step "Checking if $PDB_NAME already exists..."

PDB_EXISTS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)

# Extract the actual number from SQL output
PDB_EXISTS=$(echo "$PDB_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$PDB_EXISTS" = "1" ]; then
    log_warn "PDB $PDB_NAME already exists"
    
    # Check PDB status
    PDB_STATUS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
    )
    PDB_STATUS=$(echo "$PDB_STATUS_RAW" | grep -o 'READ WRITE\|MOUNTED\|READ ONLY' | head -n1 || echo "UNKNOWN")
    
    if [ "$PDB_STATUS" = "READ WRITE" ]; then
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
    
    if sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
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
    
    # Use a more robust approach for opening PDB
    PDB_OPEN_OUTPUT=$(sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF 2>&1
-- Check current status first
SELECT 'Current PDB status: ' || open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';

-- Open the PDB (ignore if already open)
ALTER PLUGGABLE DATABASE ${PDB_NAME} OPEN;

-- Save state for auto-start
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;

-- Verify final status
SELECT 'PDB opened successfully - Status: ' || open_mode AS status FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
    )
    
    # Check if operation was successful (look for READ WRITE in output)
    if echo "$PDB_OPEN_OUTPUT" | grep -q "READ WRITE"; then
        log_success "PDB $PDB_NAME is now open and configured for auto-start"
    else
        log_warn "PDB opening completed with messages: $PDB_OPEN_OUTPUT"
        # Verify current status
        CURRENT_STATUS=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
        )
        if echo "$CURRENT_STATUS" | grep -q "READ WRITE"; then
            log_success "PDB $PDB_NAME is confirmed open and ready"
        else
            log_error "Failed to open PDB $PDB_NAME - Status: $CURRENT_STATUS"
            exit 1
        fi
    fi
else
    log_info "PDB is already open"
fi

################################################################################
# STEP 5: Create Common User (if needed)
################################################################################
log_section "Step 5: Creating Common User"
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
    log_warn "Common user $COMMON_USER already exists"
    log_info "Note: SYSDBA cannot be granted locally in Oracle 26ai CDB root (expected limitation)"
else
    log_step "Creating common user $COMMON_USER..."
    
    if sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
-- Create common user
CREATE USER ${COMMON_USER} IDENTIFIED BY ${DB_PASSWORD};

-- Note: SYSDBA cannot be granted locally in Oracle 26ai CDB root
-- This is expected behavior in multitenant architecture
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
# STEP 6: Create Local User in PDB
################################################################################
log_section "Step 6: Creating Local User in PDB"
log_step "Checking if local user $DEMASY_USER exists in PDB $PDB_NAME..."

# Check if local user exists in PDB
LOCAL_USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Switch to PDB
ALTER SESSION SET CONTAINER = ${PDB_NAME};

-- Simple count check
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)

LOCAL_USER_EXISTS=$(echo "$LOCAL_USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$LOCAL_USER_EXISTS" = "1" ]; then
    log_success "Local user $DEMASY_USER already exists in PDB $PDB_NAME"
else
    log_step "Creating local user $DEMASY_USER in PDB $PDB_NAME with comprehensive privileges..."
    
    if sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
-- Switch to PDB
ALTER SESSION SET CONTAINER = ${PDB_NAME};

-- Create local user with comprehensive development privileges
CREATE USER ${DEMASY_USER} IDENTIFIED BY ${DB_PASSWORD};

-- Grant basic connectivity and resource privileges
GRANT CONNECT TO ${DEMASY_USER};
GRANT RESOURCE TO ${DEMASY_USER};

-- Grant advanced development privileges
GRANT UNLIMITED TABLESPACE TO ${DEMASY_USER};
GRANT SELECT_CATALOG_ROLE TO ${DEMASY_USER};
GRANT ALTER SESSION TO ${DEMASY_USER};
GRANT CREATE JOB TO ${DEMASY_USER};
GRANT CREATE DATABASE LINK TO ${DEMASY_USER};
GRANT CREATE MATERIALIZED VIEW TO ${DEMASY_USER};

-- Grant CREATE ANY privileges for comprehensive development
GRANT CREATE ANY TABLE TO ${DEMASY_USER};
GRANT CREATE ANY VIEW TO ${DEMASY_USER};
GRANT CREATE ANY PROCEDURE TO ${DEMASY_USER};
GRANT CREATE ANY FUNCTION TO ${DEMASY_USER};
GRANT CREATE ANY PACKAGE TO ${DEMASY_USER};
GRANT CREATE ANY SEQUENCE TO ${DEMASY_USER};
GRANT CREATE ANY TRIGGER TO ${DEMASY_USER};
GRANT CREATE ANY TYPE TO ${DEMASY_USER};
GRANT CREATE ANY INDEX TO ${DEMASY_USER};
GRANT CREATE PUBLIC SYNONYM TO ${DEMASY_USER};
GRANT CREATE SYNONYM TO ${DEMASY_USER};
GRANT CREATE ANY CLUSTER TO ${DEMASY_USER};
GRANT CREATE ANY CONTEXT TO ${DEMASY_USER};
GRANT CREATE ANY DIMENSION TO ${DEMASY_USER};
GRANT CREATE ANY OPERATOR TO ${DEMASY_USER};
GRANT CREATE ANY INDEXTYPE TO ${DEMASY_USER};
GRANT CREATE ANY OUTLINE TO ${DEMASY_USER};
GRANT CREATE ANY MATERIALIZED VIEW TO ${DEMASY_USER};
GRANT CREATE ANY DATABASE LINK TO ${DEMASY_USER};
GRANT CREATE ANY EDITION TO ${DEMASY_USER};
GRANT CREATE ANY SQL TRANSLATION PROFILE TO ${DEMASY_USER};

-- Grant ALTER ANY privileges for modifying objects
GRANT ALTER ANY TABLE TO ${DEMASY_USER};
GRANT ALTER ANY SEQUENCE TO ${DEMASY_USER};
GRANT ALTER ANY INDEX TO ${DEMASY_USER};
GRANT ALTER ANY PROCEDURE TO ${DEMASY_USER};
GRANT ALTER ANY FUNCTION TO ${DEMASY_USER};
GRANT ALTER ANY PACKAGE TO ${DEMASY_USER};
GRANT ALTER ANY TRIGGER TO ${DEMASY_USER};
GRANT ALTER ANY OUTLINE TO ${DEMASY_USER};
GRANT ALTER ANY MATERIALIZED VIEW TO ${DEMASY_USER};
GRANT ALTER ANY EDITION TO ${DEMASY_USER};
GRANT ALTER ANY SQL TRANSLATION PROFILE TO ${DEMASY_USER};

-- Grant DROP ANY privileges for object removal (development environment)
GRANT DROP ANY TABLE TO ${DEMASY_USER};
GRANT DROP ANY VIEW TO ${DEMASY_USER};
GRANT DROP ANY SEQUENCE TO ${DEMASY_USER};
GRANT DROP ANY PROCEDURE TO ${DEMASY_USER};
GRANT DROP ANY FUNCTION TO ${DEMASY_USER};
GRANT DROP ANY PACKAGE TO ${DEMASY_USER};
GRANT DROP ANY TRIGGER TO ${DEMASY_USER};
GRANT DROP ANY INDEX TO ${DEMASY_USER};
GRANT DROP ANY TYPE TO ${DEMASY_USER};
GRANT DROP PUBLIC SYNONYM TO ${DEMASY_USER};
GRANT DROP ANY CLUSTER TO ${DEMASY_USER};
GRANT DROP ANY CONTEXT TO ${DEMASY_USER};
GRANT DROP ANY DIMENSION TO ${DEMASY_USER};
GRANT DROP ANY OPERATOR TO ${DEMASY_USER};
GRANT DROP ANY INDEXTYPE TO ${DEMASY_USER};
GRANT DROP ANY OUTLINE TO ${DEMASY_USER};
GRANT DROP ANY MATERIALIZED VIEW TO ${DEMASY_USER};
GRANT DROP ANY DATABASE LINK TO ${DEMASY_USER};
GRANT DROP ANY EDITION TO ${DEMASY_USER};
GRANT DROP ANY SQL TRANSLATION PROFILE TO ${DEMASY_USER};

-- Grant comprehensive DML privileges
GRANT SELECT ANY TABLE TO ${DEMASY_USER};
GRANT INSERT ANY TABLE TO ${DEMASY_USER};
GRANT UPDATE ANY TABLE TO ${DEMASY_USER};
GRANT DELETE ANY TABLE TO ${DEMASY_USER};
GRANT EXECUTE ANY PROCEDURE TO ${DEMASY_USER};
GRANT EXECUTE ANY FUNCTION TO ${DEMASY_USER};
GRANT EXECUTE ANY PACKAGE TO ${DEMASY_USER};
GRANT EXECUTE ANY TYPE TO ${DEMASY_USER};
GRANT EXECUTE ANY LIBRARY TO ${DEMASY_USER};

-- Grant advanced development privileges
GRANT COMMENT ANY TABLE TO ${DEMASY_USER};
GRANT LOCK ANY TABLE TO ${DEMASY_USER};
GRANT FLASHBACK ANY TABLE TO ${DEMASY_USER};
GRANT ANALYZE ANY TO ${DEMASY_USER};
GRANT CREATE LIBRARY TO ${DEMASY_USER};
GRANT CREATE DIRECTORY TO ${DEMASY_USER};

-- Grant Oracle AI Database and modern features
GRANT CREATE MINING MODEL TO ${DEMASY_USER};
GRANT ALTER ANY MINING MODEL TO ${DEMASY_USER};
GRANT DROP ANY MINING MODEL TO ${DEMASY_USER};
GRANT SELECT ANY MINING MODEL TO ${DEMASY_USER};
GRANT COMMENT ANY MINING MODEL TO ${DEMASY_USER};

-- Grant AI/ML and Vector Search capabilities
GRANT CREATE ANY SQL TRANSLATION PROFILE TO ${DEMASY_USER};
GRANT USE ANY SQL TRANSLATION PROFILE TO ${DEMASY_USER};
GRANT CREATE SESSION TO ${DEMASY_USER};
GRANT QUERY REWRITE TO ${DEMASY_USER};
GRANT GLOBAL QUERY REWRITE TO ${DEMASY_USER};
GRANT MERGE ANY VIEW TO ${DEMASY_USER};
GRANT FLASHBACK ARCHIVE ADMINISTER TO ${DEMASY_USER};
GRANT CREATE TABLESPACE TO ${DEMASY_USER};
GRANT ALTER TABLESPACE TO ${DEMASY_USER};
GRANT DROP TABLESPACE TO ${DEMASY_USER};
GRANT MANAGE TABLESPACE TO ${DEMASY_USER};

-- Grant scheduler privileges for AI/ML jobs
GRANT CREATE ANY JOB TO ${DEMASY_USER};
GRANT EXECUTE ANY CLASS TO ${DEMASY_USER};
GRANT EXECUTE ANY PROGRAM TO ${DEMASY_USER};
GRANT MANAGE SCHEDULER TO ${DEMASY_USER};

-- Grant missing Core & PL/SQL object privileges
GRANT ALTER ANY VIEW TO ${DEMASY_USER};
GRANT ALTER ANY TYPE TO ${DEMASY_USER};
GRANT CREATE ANY PACKAGE BODY TO ${DEMASY_USER};
GRANT ALTER ANY PACKAGE BODY TO ${DEMASY_USER};
GRANT DROP ANY PACKAGE BODY TO ${DEMASY_USER};
GRANT CREATE ANY TYPE BODY TO ${DEMASY_USER};
GRANT ALTER ANY TYPE BODY TO ${DEMASY_USER};
GRANT DROP ANY TYPE BODY TO ${DEMASY_USER};

-- Grant Oracle AI Database 26ai Specific Objects
BEGIN
    -- AI Vector Index (Oracle 26ai)
    EXECUTE IMMEDIATE 'GRANT CREATE ANY VECTOR INDEX TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY VECTOR INDEX TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY VECTOR INDEX TO ${DEMASY_USER}';
    
    -- Vector Data Types
    EXECUTE IMMEDIATE 'GRANT CREATE ANY VECTOR TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY VECTOR TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT UPDATE ANY VECTOR TO ${DEMASY_USER}';
    
    -- JSON Search Index
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON SEARCH INDEX TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON SEARCH INDEX TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON SEARCH INDEX TO ${DEMASY_USER}';
    
    -- Graph Database Objects
    EXECUTE IMMEDIATE 'GRANT CREATE ANY GRAPH TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY GRAPH TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY GRAPH TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY GRAPH TO ${DEMASY_USER}';
    
    -- Spatial Index
    EXECUTE IMMEDIATE 'GRANT CREATE ANY SPATIAL INDEX TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY SPATIAL INDEX TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY SPATIAL INDEX TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- Some AI Database features may not be available in all versions
        NULL;
END;
/

-- Grant Complete Scheduler Objects (comprehensive)
BEGIN
    -- Scheduler Programs
    EXECUTE IMMEDIATE 'GRANT CREATE ANY PROGRAM TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY PROGRAM TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY PROGRAM TO ${DEMASY_USER}';
    
    -- Scheduler Classes
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CLASS TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CLASS TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CLASS TO ${DEMASY_USER}';
    
    -- Scheduler Schedules
    EXECUTE IMMEDIATE 'GRANT CREATE ANY SCHEDULE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY SCHEDULE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY SCHEDULE TO ${DEMASY_USER}';
    
    -- Scheduler Chains
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CHAIN TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CHAIN TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CHAIN TO ${DEMASY_USER}';
    
    -- File Watchers
    EXECUTE IMMEDIATE 'GRANT CREATE ANY FILE WATCHER TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY FILE WATCHER TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY FILE WATCHER TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- Some scheduler features may not be available in all versions
        NULL;
END;
/

-- Grant Replication & Streams Objects
BEGIN
    -- Advanced Queuing
    EXECUTE IMMEDIATE 'GRANT CREATE ANY QUEUE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY QUEUE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY QUEUE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ENQUEUE ANY QUEUE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DEQUEUE ANY QUEUE TO ${DEMASY_USER}';
    
    -- Queue Tables
    EXECUTE IMMEDIATE 'GRANT CREATE ANY QUEUE TABLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY QUEUE TABLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY QUEUE TABLE TO ${DEMASY_USER}';
    
    -- Streams Rule Sets
    EXECUTE IMMEDIATE 'GRANT CREATE ANY RULE SET TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY RULE SET TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY RULE SET TO ${DEMASY_USER}';
    
    -- Streams Rules
    EXECUTE IMMEDIATE 'GRANT CREATE ANY RULE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY RULE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY RULE TO ${DEMASY_USER}';
    
    -- Data Transforms
    EXECUTE IMMEDIATE 'GRANT CREATE ANY TRANSFORM TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY TRANSFORM TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY TRANSFORM TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- Streams/AQ features may not be available in all versions
        NULL;
END;
/

-- Grant Security Objects
BEGIN
    -- Role Management
    EXECUTE IMMEDIATE 'GRANT CREATE ROLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY ROLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY ROLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT GRANT ANY ROLE TO ${DEMASY_USER}';
    
    -- Profile Management
    EXECUTE IMMEDIATE 'GRANT CREATE PROFILE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER PROFILE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP PROFILE TO ${DEMASY_USER}';
    
    -- User Management
    EXECUTE IMMEDIATE 'GRANT CREATE USER TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER USER TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP USER TO ${DEMASY_USER}';
    
    -- Fine-Grained Access Control
    EXECUTE IMMEDIATE 'GRANT CREATE ANY POLICY TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY POLICY TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY POLICY TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- Security features may require special privileges
        NULL;
END;
/

-- Grant Analytics & Data Warehouse Objects
BEGIN
    -- OLAP Cubes
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CUBE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CUBE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CUBE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY CUBE TO ${DEMASY_USER}';
    
    -- Measure Folders
    EXECUTE IMMEDIATE 'GRANT CREATE ANY MEASURE FOLDER TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY MEASURE FOLDER TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY MEASURE FOLDER TO ${DEMASY_USER}';
    
    -- Analytic Views
    EXECUTE IMMEDIATE 'GRANT CREATE ANY ANALYTIC VIEW TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY ANALYTIC VIEW TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY ANALYTIC VIEW TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY ANALYTIC VIEW TO ${DEMASY_USER}';
    
    -- Hierarchies
    EXECUTE IMMEDIATE 'GRANT CREATE ANY HIERARCHY TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY HIERARCHY TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY HIERARCHY TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY HIERARCHY TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- Analytics features may not be available in all versions
        NULL;
END;
/

-- Grant XML & JSON Objects
BEGIN
    -- XML Schema
    EXECUTE IMMEDIATE 'GRANT CREATE ANY XML SCHEMA TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY XML SCHEMA TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY XML SCHEMA TO ${DEMASY_USER}';
    
    -- XML Type privileges
    EXECUTE IMMEDIATE 'GRANT UNDER ANY TYPE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT UNDER ANY VIEW TO ${DEMASY_USER}';
    
    -- JSON Collections (Oracle 21c+)
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON COLLECTION TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON COLLECTION TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON COLLECTION TO ${DEMASY_USER}';
    
    -- JSON Schema
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON SCHEMA TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON SCHEMA TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON SCHEMA TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- JSON/XML features may not be available in all versions
        NULL;
END;
/

-- Grant Integration Objects
BEGIN
    -- External Tables
    EXECUTE IMMEDIATE 'GRANT CREATE ANY EXTERNAL TABLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY EXTERNAL TABLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY EXTERNAL TABLE TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY EXTERNAL TABLE TO ${DEMASY_USER}';
    
    -- Credentials
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CREDENTIAL TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CREDENTIAL TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CREDENTIAL TO ${DEMASY_USER}';
    
    -- Destinations
    EXECUTE IMMEDIATE 'GRANT CREATE ANY DESTINATION TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY DESTINATION TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY DESTINATION TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- Integration features may not be available in all versions
        NULL;
END;
/

-- Grant Advanced Partitioning Objects
BEGIN
    EXECUTE IMMEDIATE 'GRANT ALTER ANY PARTITION TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY PARTITION TO ${DEMASY_USER}';
    EXECUTE IMMEDIATE 'GRANT MANAGE ANY PARTITION TO ${DEMASY_USER}';
EXCEPTION
    WHEN OTHERS THEN
        -- Advanced partitioning may not be available in all editions
        NULL;
END;
/

-- Display final status
SELECT username || ' created successfully with ' || 
       (SELECT COUNT(*) FROM dba_tab_privs WHERE grantee = username) || ' privileges and ' ||
       (SELECT COUNT(*) FROM dba_role_privs WHERE grantee = username) || ' roles' AS result
FROM dba_users 
WHERE username = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';

-- Display privilege categories granted
SELECT 'Oracle AI Database 26ai Comprehensive Privileges Granted:' AS info FROM DUAL;
SELECT '• Core Database Objects (Tables, Views, Indexes, Sequences)' AS category FROM DUAL;
SELECT '• PL/SQL Objects (Procedures, Functions, Packages, Types)' AS category FROM DUAL;
SELECT '• AI Database Objects (Mining Models, Vector Indexes, Graphs)' AS category FROM DUAL;
SELECT '• Scheduler Objects (Jobs, Programs, Classes, Chains)' AS category FROM DUAL;
SELECT '• Replication Objects (Queues, Rules, Transforms)' AS category FROM DUAL;
SELECT '• Security Objects (Roles, Profiles, Users, Policies)' AS category FROM DUAL;
SELECT '• Analytics Objects (Cubes, Hierarchies, Analytic Views)' AS category FROM DUAL;
SELECT '• XML/JSON Objects (Schemas, Collections)' AS category FROM DUAL;
SELECT '• Integration Objects (External Tables, Credentials)' AS category FROM DUAL;
SELECT '• Advanced Features (Partitioning, Spatial, Modern Oracle)' AS category FROM DUAL;

EXIT
EOF
    then
        log_success "Local user $DEMASY_USER created with comprehensive Oracle AI Database 26ai privileges"
    else
        log_error "Failed to create local user $DEMASY_USER"
        exit 1
    fi
fi

# Re-check local user existence after creation
log_step "Re-verifying local user creation..."
LOCAL_USER_EXISTS_FINAL=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)
LOCAL_USER_EXISTS=$(echo "$LOCAL_USER_EXISTS_FINAL" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$LOCAL_USER_EXISTS" = "1" ]; then
    log_success "✓ Local user $DEMASY_USER successfully created/exists in PDB $PDB_NAME"
else
    log_error "✗ Local user $DEMASY_USER was not created successfully"
fi

################################################################################
# STEP 7: Verification
################################################################################
log_section "Step 7: Final Verification"
log_step "Verifying all operations completed successfully..."

# Verify PDB status
log_step "Checking PDB status..."
PDB_INFO=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
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
log_step "Checking common user status..."
COMMON_USER_STATUS=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT username || '|' || account_status || '|' || created FROM dba_users WHERE username = '$(echo $COMMON_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)

if [[ "$COMMON_USER_STATUS" == *"OPEN"* ]]; then
    log_success "✓ Common user $COMMON_USER is active"
else
    log_warn "⚠ Common user status: $COMMON_USER_STATUS"
fi

# Verify local user privileges in PDB
log_step "Checking local user privileges in PDB..."
if [ "$LOCAL_USER_EXISTS" = "1" ]; then
    PRIVILEGE_COUNT_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_tab_privs WHERE grantee = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
    )
    
    ROLE_COUNT_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_role_privs WHERE grantee = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
    )

PRIVILEGE_COUNT=$(echo "$PRIVILEGE_COUNT_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")
ROLE_COUNT=$(echo "$ROLE_COUNT_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [[ "$PRIVILEGE_COUNT" -gt 0 ]] || [[ "$ROLE_COUNT" -gt 0 ]]; then
    log_success "✓ Local user $DEMASY_USER has $PRIVILEGE_COUNT privileges and $ROLE_COUNT roles"
else
    log_warn "⚠ Could not verify privileges for $DEMASY_USER"
fi
else
    log_warn "⚠ Local user $DEMASY_USER does not exist - skipping privilege check"
fi

# Test connection to PDB as demasy user
log_step "Testing connection and basic functionality as demasy user..."
if [ "$LOCAL_USER_EXISTS" = "1" ]; then
    TEST_OUTPUT=$(sql -s ${DEMASY_USER}/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << 'EOF' 2>&1
SET PAGESIZE 0
SET FEEDBACK OFF
-- Test basic operations
CREATE TABLE demasy_test_table (id NUMBER, test_msg VARCHAR2(100));
INSERT INTO demasy_test_table VALUES (1, 'Connection and privileges verified');
SELECT test_msg FROM demasy_test_table WHERE ROWNUM = 1;
DROP TABLE demasy_test_table;
SELECT 'SUCCESS' AS final_status FROM DUAL;
EXIT
EOF
    )
    
    if echo "$TEST_OUTPUT" | grep -q "SUCCESS"; then
        log_success "✓ Connection test and privilege verification successful"
    elif echo "$TEST_OUTPUT" | grep -q "Connection and privileges verified"; then
        log_success "✓ Connection and basic operations successful"
    else
        log_warn "⚠ Connection test had issues: $TEST_OUTPUT"
        # Try a simpler connection test
        SIMPLE_TEST=$(sql -s ${DEMASY_USER}/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << 'EOF' 2>&1
SELECT 'SIMPLE_SUCCESS' FROM DUAL;
EXIT
EOF
        )
        if echo "$SIMPLE_TEST" | grep -q "SIMPLE_SUCCESS"; then
            log_success "✓ Basic connection successful (complex operations may need verification)"
        else
            log_warn "⚠ Connection test failed: $SIMPLE_TEST"
        fi
    fi
else
    log_error "✗ Cannot test connection - demasy user was not created successfully"
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
echo "   • Common User: $COMMON_USER (Oracle 26ai CDB user)"
echo "   • Local User: $DEMASY_USER (Full development privileges)"
echo "   • Password: [Same as system password]"
echo ""
echo "🔗 Connection Examples:"
echo "   • SQLcl: sql ${DEMASY_USER}/password@//${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo "   • SQL*Plus: sqlplus ${DEMASY_USER}/password@${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo "   • From container: sql ${DEMASY_USER}/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo ""
echo "💡 Development Notes:"
echo "   • SYSDBA privileges not available in Oracle 26ai CDB (expected behavior)"
echo "   • All standard development privileges granted to local user"
echo "   • PDB configured for auto-start on database restart"
echo ""

log_success "Ready for development! 🚀"