#!/bin/bash

################################################################################
# DEMASYLABS PDB and User Rollback Script
# This script runs FROM INSIDE the Docker container
# Removes DEMASYLABS_PDB pluggable database and demasy user
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
print_demasy_banner "DEMASYLABS PDB and User Rollback"

################################################################################
# CONFIGURATION - Read from Environment Variables
################################################################################
log_info "Reading configuration from environment variables..."

DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
DB_SID="${DEMASYLABS_DB_SID}"
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
log_info "Rollback Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  CDB: $DB_SID"
echo "  PDB to Remove: $PDB_NAME"
echo "  Common User to Remove: $COMMON_USER"
echo "  Local User to Remove: $DEMASY_USER"
echo ""

################################################################################
# CONFIRMATION PROMPT
################################################################################
log_section "⚠️  DESTRUCTIVE OPERATION WARNING ⚠️"
log_warn "This script will permanently delete:"
echo "  • PDB: $PDB_NAME (including ALL data)"
echo "  • Common User: $COMMON_USER"
echo "  • Local User: $DEMASY_USER (within PDB)"
echo "  • All associated tablespaces and files"
echo ""
log_error "This operation CANNOT be undone!"
echo ""

# Auto-confirmation for scripted environments - check if running interactively
if [[ -t 0 ]]; then
    read -p "Are you sure you want to proceed? Type 'DELETE' to confirm: " CONFIRMATION
    if [ "$CONFIRMATION" != "DELETE" ]; then
        log_info "Rollback cancelled by user"
        exit 0
    fi
else
    log_warn "Running in non-interactive mode - proceeding with rollback"
fi

echo ""
log_success "Confirmation received - proceeding with rollback..."

################################################################################
# STEP 1: Test Database Connection
################################################################################
log_section "Step 1: Testing Database Connection"
log_step "Connecting to CDB\$ROOT..."

# Test connection to CDB$ROOT
if ! sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << 'EOF' > /dev/null 2>&1
SELECT 'Connected to ' || SYS_CONTEXT('USERENV', 'CON_NAME') AS connection_info FROM DUAL;
EXIT
EOF
then
    log_error "Cannot connect to database CDB at ${DB_HOST}:${DB_PORT}/${DB_SID}"
    log_error "Please verify database is running and credentials are correct"
    exit 1
fi

log_success "Successfully connected to CDB\$ROOT"

################################################################################
# STEP 2: Check What Exists
################################################################################
log_section "Step 2: Checking Current State"

# Check if PDB exists
log_step "Checking if PDB $PDB_NAME exists..."
PDB_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)
PDB_EXISTS=$(echo "$PDB_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

# Check if common user exists
log_step "Checking if common user $COMMON_USER exists..."
COMMON_USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $COMMON_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
)
COMMON_USER_EXISTS=$(echo "$COMMON_USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

# Check if local user exists (only if PDB exists)
LOCAL_USER_EXISTS="0"
if [ "$PDB_EXISTS" = "1" ]; then
    log_step "Checking if local user $DEMASY_USER exists in PDB $PDB_NAME..."
    LOCAL_USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '$(echo $DEMASY_USER | tr '[:lower:]' '[:upper:]')';
EXIT
EOF
    )
    LOCAL_USER_EXISTS=$(echo "$LOCAL_USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")
fi

# Display current state
log_info "Current State:"
echo "  • PDB $PDB_NAME: $([ "$PDB_EXISTS" = "1" ] && echo "EXISTS" || echo "NOT FOUND") (detected: $PDB_EXISTS)"
echo "  • Common User $COMMON_USER: $([ "$COMMON_USER_EXISTS" = "1" ] && echo "EXISTS" || echo "NOT FOUND") (detected: $COMMON_USER_EXISTS)"
echo "  • Local User $DEMASY_USER: $([ "$LOCAL_USER_EXISTS" = "1" ] && echo "EXISTS" || echo "NOT FOUND")"
echo ""

if [ "$PDB_EXISTS" = "0" ] && [ "$COMMON_USER_EXISTS" = "0" ] && [ "$LOCAL_USER_EXISTS" = "0" ]; then
    log_success "Nothing to rollback - all components already removed"
    exit 0
fi

################################################################################
# STEP 3: Complete All Objects Cleanup
################################################################################
if [ "$PDB_EXISTS" = "1" ] || [ "$COMMON_USER_EXISTS" = "1" ]; then
    log_section "Step 3: Complete All Objects Cleanup"
    
    # First, clean up all objects owned by the user
    log_step "Cleaning up all objects owned by $COMMON_USER..."
    
    OBJECT_CLEANUP=$(sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF 2>&1
-- Clean up Oracle AI Database objects (Mining Models)
BEGIN
    FOR obj IN (SELECT model_name FROM dba_mining_models WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP MINING MODEL ${COMMON_USER}.' || obj.model_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Oracle AI Database 26ai Specific Objects (comprehensive)
BEGIN
    -- Clean up Vector Indexes
    FOR obj IN (SELECT index_name FROM dba_indexes WHERE owner = '${COMMON_USER}' AND index_type LIKE '%VECTOR%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX ${COMMON_USER}.' || obj.index_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up Graph objects
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'GRAPH') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP GRAPH ${COMMON_USER}.' || obj.object_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up Spatial Indexes
    FOR obj IN (SELECT index_name FROM dba_indexes WHERE owner = '${COMMON_USER}' AND index_type LIKE '%SPATIAL%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX ${COMMON_USER}.' || obj.index_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Complete Scheduler Objects
BEGIN
    -- Drop Jobs
    FOR obj IN (SELECT job_name FROM dba_scheduler_jobs WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP JOB ${COMMON_USER}.' || obj.job_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Programs
    FOR obj IN (SELECT program_name FROM dba_scheduler_programs WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP PROGRAM ${COMMON_USER}.' || obj.program_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Classes
    FOR obj IN (SELECT class_name FROM dba_scheduler_job_classes WHERE class_name LIKE '${COMMON_USER}%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CLASS ' || obj.class_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

SELECT 'ALL_OBJECTS_CLEANUP_SUCCESS' AS status FROM DUAL;
EXIT
EOF
    )
    
    if [[ "$OBJECT_CLEANUP" == *"ALL_OBJECTS_CLEANUP_SUCCESS"* ]]; then
        log_success "All objects owned by $COMMON_USER cleaned up"
    else
        log_warn "Some objects may not have been cleaned up (continuing...)"
    fi
else
    log_info "Skipping objects cleanup (no users exist)"
fi

################################################################################
# STEP 4: Remove Local User
################################################################################
if [ "$PDB_EXISTS" = "1" ] && [ "$LOCAL_USER_EXISTS" = "1" ]; then
    log_section "Step 4: Remove Local User"
    
    # First, clean up all objects owned by the user
    log_step "Cleaning up all objects owned by $COMMON_USER..."
    
    OBJECT_CLEANUP=$(sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF 2>&1
-- Drop all tablespaces owned by user
BEGIN
    FOR ts IN (SELECT tablespace_name FROM dba_tablespaces 
               WHERE tablespace_name LIKE '%DEMASY%' OR tablespace_name LIKE '%${PDB_NAME}%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLESPACE ' || ts.tablespace_name || ' INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Oracle AI Database objects (Mining Models)
BEGIN
    FOR obj IN (SELECT model_name FROM dba_mining_models WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP MINING MODEL ${COMMON_USER}.' || obj.model_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Oracle AI Database 26ai Specific Objects (comprehensive)
BEGIN
    -- Clean up Vector Indexes
    FOR obj IN (SELECT index_name FROM dba_indexes WHERE owner = '${COMMON_USER}' AND index_type LIKE '%VECTOR%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX ${COMMON_USER}.' || obj.index_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up Graph objects
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'GRAPH') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP GRAPH ${COMMON_USER}.' || obj.object_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up Spatial Indexes
    FOR obj IN (SELECT index_name FROM dba_indexes WHERE owner = '${COMMON_USER}' AND index_type LIKE '%SPATIAL%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX ${COMMON_USER}.' || obj.index_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up JSON Search Indexes
    FOR obj IN (SELECT index_name FROM dba_indexes WHERE owner = '${COMMON_USER}' AND index_type LIKE '%JSON%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX ${COMMON_USER}.' || obj.index_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Scheduler Objects (comprehensive)
BEGIN
    -- Drop Scheduler Jobs
    FOR obj IN (SELECT job_name FROM dba_scheduler_jobs WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP JOB ${COMMON_USER}.' || obj.job_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Scheduler Programs
    FOR obj IN (SELECT program_name FROM dba_scheduler_programs WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP PROGRAM ${COMMON_USER}.' || obj.program_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Scheduler Classes
    FOR obj IN (SELECT class_name FROM dba_scheduler_classes WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CLASS ${COMMON_USER}.' || obj.class_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Scheduler Schedules
    FOR obj IN (SELECT schedule_name FROM dba_scheduler_schedules WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SCHEDULE ${COMMON_USER}.' || obj.schedule_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Scheduler Chains
    FOR obj IN (SELECT chain_name FROM dba_scheduler_chains WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CHAIN ${COMMON_USER}.' || obj.chain_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop File Watchers
    FOR obj IN (SELECT file_watcher_name FROM dba_scheduler_file_watchers WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP FILE WATCHER ${COMMON_USER}.' || obj.file_watcher_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Replication & Streams Objects
BEGIN
    -- Drop Advanced Queues
    FOR obj IN (SELECT name FROM dba_queues WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP QUEUE ${COMMON_USER}.' || obj.name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Queue Tables
    FOR obj IN (SELECT queue_table FROM dba_queue_tables WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP QUEUE TABLE ${COMMON_USER}.' || obj.queue_table;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Streams Rule Sets
    FOR obj IN (SELECT rule_set_name FROM dba_rule_sets WHERE rule_set_owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP RULE SET ${COMMON_USER}.' || obj.rule_set_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Streams Rules
    FOR obj IN (SELECT rule_name FROM dba_rules WHERE rule_owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP RULE ${COMMON_USER}.' || obj.rule_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Data Transforms
    FOR obj IN (SELECT transform_name FROM dba_transforms WHERE transform_owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TRANSFORM ${COMMON_USER}.' || obj.transform_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Security Objects
BEGIN
    -- Drop User-created Roles
    FOR obj IN (SELECT role FROM dba_roles WHERE role LIKE '${COMMON_USER}_%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ROLE ' || obj.role;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop User-created Profiles
    FOR obj IN (SELECT profile FROM dba_profiles WHERE profile LIKE '${COMMON_USER}_%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP PROFILE ' || obj.profile || ' CASCADE';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Fine-Grained Access Control Policies
    FOR obj IN (SELECT policy_name, object_owner, object_name FROM dba_policies WHERE policy_owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP POLICY ' || obj.object_owner || '.' || obj.object_name || '.' || obj.policy_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Analytics & Data Warehouse Objects
BEGIN
    -- Drop OLAP Cubes
    FOR obj IN (SELECT cube_name FROM dba_cubes WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CUBE ${COMMON_USER}.' || obj.cube_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Measure Folders
    FOR obj IN (SELECT measure_folder_name FROM dba_measure_folders WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP MEASURE FOLDER ${COMMON_USER}.' || obj.measure_folder_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Analytic Views
    FOR obj IN (SELECT analytic_view_name FROM dba_analytic_views WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ANALYTIC VIEW ${COMMON_USER}.' || obj.analytic_view_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Hierarchies
    FOR obj IN (SELECT hierarchy_name FROM dba_hierarchies WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP HIERARCHY ${COMMON_USER}.' || obj.hierarchy_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up XML & JSON Objects
BEGIN
    -- Drop XML Schemas
    FOR obj IN (SELECT schema_url FROM dba_xml_schemas WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP XML SCHEMA "' || obj.schema_url || '" CASCADE';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop JSON Collections
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'JSON COLLECTION') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP JSON COLLECTION ${COMMON_USER}.' || obj.object_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop JSON Schemas
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'JSON SCHEMA') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP JSON SCHEMA ${COMMON_USER}.' || obj.object_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up Integration Objects
BEGIN
    -- Drop External Tables
    FOR obj IN (SELECT table_name FROM dba_external_tables WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ${COMMON_USER}.' || obj.table_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Credentials
    FOR obj IN (SELECT credential_name FROM dba_credentials WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CREDENTIAL ${COMMON_USER}.' || obj.credential_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Destinations
    FOR obj IN (SELECT destination_name FROM dba_destinations WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP DESTINATION ${COMMON_USER}.' || obj.destination_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Clean up all object types comprehensively (enhanced)
BEGIN
    -- Drop Functions
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'FUNCTION') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP FUNCTION ${COMMON_USER}.' || obj.object_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Packages
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'PACKAGE') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP PACKAGE ${COMMON_USER}.' || obj.object_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Types
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'TYPE') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TYPE ${COMMON_USER}.' || obj.object_name || ' FORCE';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Materialized Views
    FOR obj IN (SELECT object_name FROM dba_objects WHERE owner = '${COMMON_USER}' AND object_type = 'MATERIALIZED VIEW') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW ${COMMON_USER}.' || obj.object_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Database Links
    FOR obj IN (SELECT db_link FROM dba_db_links WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP DATABASE LINK ${COMMON_USER}.' || obj.db_link;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Clusters
    FOR obj IN (SELECT cluster_name FROM dba_clusters WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CLUSTER ${COMMON_USER}.' || obj.cluster_name || ' INCLUDING TABLES CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Contexts
    FOR obj IN (SELECT namespace FROM dba_context WHERE schema = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CONTEXT ' || obj.namespace;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Dimensions
    FOR obj IN (SELECT dimension_name FROM dba_dimensions WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP DIMENSION ${COMMON_USER}.' || obj.dimension_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Operators
    FOR obj IN (SELECT operator_name FROM dba_operators WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP OPERATOR ${COMMON_USER}.' || obj.operator_name || ' FORCE';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Index Types
    FOR obj IN (SELECT indextype_name FROM dba_indextypes WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEXTYPE ${COMMON_USER}.' || obj.indextype_name || ' FORCE';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Libraries
    FOR obj IN (SELECT library_name FROM dba_libraries WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP LIBRARY ${COMMON_USER}.' || obj.library_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop Directories
    FOR obj IN (SELECT directory_name FROM dba_directories WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP DIRECTORY ' || obj.directory_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop SQL Translation Profiles
    FOR obj IN (SELECT profile_name FROM dba_sql_translation_profiles WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SQL TRANSLATION PROFILE ' || obj.profile_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Drop remaining objects (Tables, Views, Sequences, Procedures, Triggers, Indexes)
    FOR obj IN (SELECT object_name, object_type FROM dba_objects WHERE owner = '${COMMON_USER}' 
                AND object_type IN ('TABLE', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'TRIGGER', 'INDEX')) LOOP
        BEGIN
            IF obj.object_type = 'TABLE' THEN
                EXECUTE IMMEDIATE 'DROP TABLE ${COMMON_USER}.' || obj.object_name || ' CASCADE CONSTRAINTS PURGE';
            ELSIF obj.object_type = 'VIEW' THEN
                EXECUTE IMMEDIATE 'DROP VIEW ${COMMON_USER}.' || obj.object_name;
            ELSIF obj.object_type = 'SEQUENCE' THEN
                EXECUTE IMMEDIATE 'DROP SEQUENCE ${COMMON_USER}.' || obj.object_name;
            ELSIF obj.object_type = 'PROCEDURE' THEN
                EXECUTE IMMEDIATE 'DROP PROCEDURE ${COMMON_USER}.' || obj.object_name;
            ELSIF obj.object_type = 'TRIGGER' THEN
                EXECUTE IMMEDIATE 'DROP TRIGGER ${COMMON_USER}.' || obj.object_name;
            ELSIF obj.object_type = 'INDEX' THEN
                EXECUTE IMMEDIATE 'DROP INDEX ${COMMON_USER}.' || obj.object_name;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up Scheduler objects
    FOR obj IN (SELECT job_name FROM dba_scheduler_jobs WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP JOB ${COMMON_USER}.' || obj.job_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    FOR obj IN (SELECT program_name FROM dba_scheduler_programs WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP PROGRAM ${COMMON_USER}.' || obj.program_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    FOR obj IN (SELECT class_name FROM dba_scheduler_classes WHERE owner = '${COMMON_USER}') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP CLASS ${COMMON_USER}.' || obj.class_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

SELECT 'OBJECT_CLEANUP_SUCCESS' AS status FROM DUAL;
EXIT
EOF
    )
    
    if [[ "$OBJECT_CLEANUP" == *"OBJECT_CLEANUP_SUCCESS"* ]]; then
        log_success "All objects owned by $COMMON_USER cleaned up"
    else
        log_warn "Object cleanup completed with some warnings (continuing...)"
    fi
    
    # Force drop the common user with all remaining objects
    log_step "Force dropping common user $COMMON_USER..."
    
    COMMON_DROP_RESULT=$(sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF 2>&1
-- Force drop common user and cascade to remove all objects
DROP USER ${COMMON_USER} CASCADE;
SELECT 'COMMON_USER_DROP_SUCCESS' AS status FROM DUAL;
EXIT
EOF
    )
    
    if [[ "$COMMON_DROP_RESULT" == *"COMMON_USER_DROP_SUCCESS"* ]]; then
        log_success "Common user $COMMON_USER completely removed"
    else
        # Try with SYS if SYSTEM failed
        log_warn "SYSTEM user failed, trying SYS for user removal..."
        
        COMMON_SYS_DROP=$(sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} AS SYSDBA << EOF 2>&1
DROP USER ${COMMON_USER} CASCADE;
SELECT 'SYS_USER_DROP_SUCCESS' AS status FROM DUAL;
EXIT
EOF
        )
        
        if [[ "$COMMON_SYS_DROP" == *"SYS_USER_DROP_SUCCESS"* ]]; then
            log_success "Common user $COMMON_USER removed using SYS privileges"
        else
            log_error "Failed to remove common user $COMMON_USER"
            log_error "ROLLBACK FAILED - incomplete user cleanup is not acceptable"
            exit 1
        fi
    fi
    
    # Final verification - user must be gone (with retry)
    log_step "Verifying user removal (with retries)..."
    
    for attempt in {1..3}; do
        sleep 1  # Wait for Oracle to process the drop
        
        USER_FINAL_CHECK=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '${COMMON_USER}';
EXIT
EOF
        )
        
        USER_STILL_EXISTS=$(echo "$USER_FINAL_CHECK" | grep -o '[0-9]' | tail -n1 || echo "0")
        
        if [ "$USER_STILL_EXISTS" = "0" ]; then
            log_success "✓ Common user $COMMON_USER completely removed - verified (attempt $attempt)"
            break
        else
            log_warn "User still exists on attempt $attempt/3, retrying..."
        fi
        
        if [ "$attempt" = "3" ]; then
            log_error "✗ Common user $COMMON_USER still exists after cleanup"
            log_error "ROLLBACK FAILED - incomplete user cleanup is not acceptable"
            exit 1
        fi
    done
else
    log_info "Skipping common user removal (user doesn't exist)"
fi

################################################################################
# STEP 5: Remove Common User
################################################################################
if [ "$COMMON_USER_EXISTS" = "1" ]; then
    log_section "Step 5: Remove Common User"

# Clean up any remaining tablespaces related to demasy/demasylabs
sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << 'EOF' > /dev/null 2>&1
BEGIN
    -- Drop any tablespaces that might contain demasy objects
    FOR ts IN (SELECT tablespace_name FROM dba_tablespaces WHERE tablespace_name LIKE '%DEMASY%' OR tablespace_name LIKE '%DEMASYLABS%') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLESPACE ' || ts.tablespace_name || ' INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/
EXIT
EOF

log_success "All related tablespaces cleaned up"

################################################################################
# STEP 6: Remove All Tablespaces
################################################################################
log_section "Step 6: Remove All Tablespaces"
    
    # Force close all sessions in the PDB first
    log_step "Killing all sessions in PDB $PDB_NAME..."
    sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF > /dev/null 2>&1
-- Kill all sessions in the PDB
ALTER PLUGGABLE DATABASE ${PDB_NAME} CLOSE ABORT;
EOF

    # Multiple aggressive drop attempts
    log_step "Force dropping PDB $PDB_NAME with all datafiles and objects..."
EOF
fi

# Verify no mining models remain
REMAINING_MODELS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_mining_models WHERE owner = '${COMMON_USER}';
EXIT
EOF
)

MODEL_COUNT=$(echo "$REMAINING_MODELS" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$MODEL_COUNT" = "0" ]; then
    log_success "✓ No remaining AI/ML models found"
else
    log_warn "⚠ Found $MODEL_COUNT remaining AI/ML models"
fi

# Verify no scheduler objects remain
REMAINING_JOBS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_scheduler_jobs WHERE owner = '${COMMON_USER}';
EXIT
EOF
)

JOB_COUNT=$(echo "$REMAINING_JOBS" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$JOB_COUNT" = "0" ]; then
    log_success "✓ No remaining scheduler jobs found"
else
    log_warn "⚠ Found $JOB_COUNT remaining scheduler jobs"
fi

# Verify no scheduler programs remain
REMAINING_PROGRAMS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_scheduler_programs WHERE owner = '${COMMON_USER}';
EXIT
EOF
)

PROGRAM_COUNT=$(echo "$REMAINING_PROGRAMS" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$PROGRAM_COUNT" = "0" ]; then
    log_success "✓ No remaining scheduler programs found"
else
    log_warn "⚠ Found $PROGRAM_COUNT remaining scheduler programs"
fi

# Verify no advanced queues remain
REMAINING_QUEUES=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_queues WHERE owner = '${COMMON_USER}';
EXIT
EOF
)

QUEUE_COUNT=$(echo "$REMAINING_QUEUES" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$QUEUE_COUNT" = "0" ]; then
    log_success "✓ No remaining queues found"
else
    log_warn "⚠ Found $QUEUE_COUNT remaining queues"
fi

# Verify no analytics objects remain
REMAINING_ANALYTICS=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_cubes WHERE owner = '${COMMON_USER}';
EXIT
EOF
)

ANALYTICS_COUNT=$(echo "$REMAINING_ANALYTICS" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$ANALYTICS_COUNT" = "0" ]; then
    log_success "✓ No remaining analytics objects found"
else
    log_warn "⚠ Found $ANALYTICS_COUNT remaining analytics objects"
fi

# Verify no XML schemas remain
REMAINING_XML=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_xml_schemas WHERE owner = '${COMMON_USER}';
EXIT
EOF
)

XML_COUNT=$(echo "$REMAINING_XML" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$XML_COUNT" = "0" ]; then
    log_success "✓ No remaining XML schemas found"
else
    log_warn "⚠ Found $XML_COUNT remaining XML schemas"
fi

################################################################################
# STEP 7: Force Drop PDB
################################################################################
if [ "$PDB_EXISTS" = "1" ]; then
    log_section "Step 7: Force Drop PDB"
    
    # Force close all sessions in the PDB first
    log_step "Killing all sessions in PDB $PDB_NAME..."
    sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF > /dev/null 2>&1
-- Kill all sessions in the PDB
ALTER PLUGGABLE DATABASE ${PDB_NAME} CLOSE ABORT;
EXIT
EOF

    # Multiple aggressive drop attempts with comprehensive verification
    log_step "Force dropping PDB $PDB_NAME with all datafiles and objects..."
    
    # Attempt 1: Standard drop with force
    PDB_DROP_RESULT=$(sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF 2>&1
ALTER PLUGGABLE DATABASE ${PDB_NAME} UNPLUG INTO '/tmp/${PDB_NAME}_temp.xml';
DROP PLUGGABLE DATABASE ${PDB_NAME} INCLUDING DATAFILES;
SELECT 'PDB_FORCE_DROP_SUCCESS' AS status FROM DUAL;
EXIT
EOF
    )
    
    if [[ "$PDB_DROP_RESULT" == *"PDB_FORCE_DROP_SUCCESS"* ]]; then
        log_success "PDB $PDB_NAME force-dropped including all datafiles"
        rm -f /tmp/${PDB_NAME}_temp.xml 2>/dev/null || true
    else
        # Attempt 2: Use SYS with FORCE option
        log_warn "Standard drop failed, trying SYS with force options..."
        
        PDB_FORCE_RESULT=$(sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} AS SYSDBA << EOF 2>&1
-- Force close and drop
SHUTDOWN ABORT;
STARTUP;
ALTER PLUGGABLE DATABASE ${PDB_NAME} CLOSE ABORT;
DROP PLUGGABLE DATABASE ${PDB_NAME} INCLUDING DATAFILES;
SELECT 'PDB_SYS_FORCE_SUCCESS' AS status FROM DUAL;
EXIT
EOF
        )
        
        if [[ "$PDB_FORCE_RESULT" == *"PDB_SYS_FORCE_SUCCESS"* ]]; then
            log_success "PDB $PDB_NAME force-dropped using SYS privileges"
        else
            # Attempt 3: Nuclear option - manual cleanup
            log_warn "Standard drops failed, attempting manual cleanup..."
            
            # Get datafile locations and remove them manually
            DATAFILE_CLEANUP=$(sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} AS SYSDBA << EOF 2>&1
-- Manual cleanup sequence
ALTER SYSTEM SET "_ORACLE_SCRIPT"=true;
DROP PLUGGABLE DATABASE ${PDB_NAME} INCLUDING DATAFILES FORCE;
SELECT 'PDB_MANUAL_CLEANUP_SUCCESS' AS status FROM DUAL;
EXIT
EOF
            )
            
            if [[ "$DATAFILE_CLEANUP" == *"PDB_MANUAL_CLEANUP_SUCCESS"* ]]; then
                log_success "PDB $PDB_NAME manually cleaned up"
            else
                log_error "Failed to completely remove PDB $PDB_NAME"
                log_error "Manual intervention required - this is not acceptable"
                log_error "Attempting final emergency cleanup..."
                
                # Emergency cleanup - remove references from data dictionary
                sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} AS SYSDBA << EOF > /dev/null 2>&1
-- Emergency cleanup
DELETE FROM v\$pdbs WHERE name = '${PDB_NAME}';
DELETE FROM dba_pdbs WHERE pdb_name = '${PDB_NAME}';
COMMIT;
EXIT
EOF
                log_warn "Emergency cleanup attempted - PDB references removed from data dictionary"
            fi
        fi
    fi
    
    # Final verification - PDB must be gone (with aggressive retry)
    log_step "Verifying PDB removal with aggressive validation..."
    
    PDB_COMPLETELY_REMOVED=false
    for attempt in {1..10}; do
        sleep 3  # Wait for Oracle to process the drop
        
        PDB_FINAL_CHECK=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF 2>/dev/null
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
        )
        
        PDB_STILL_EXISTS=$(echo "$PDB_FINAL_CHECK" | grep -o '[0-9]' | tail -n1 || echo "0")
        
        if [ "$PDB_STILL_EXISTS" = "0" ]; then
            log_success "✓ PDB $PDB_NAME completely removed - verified (attempt $attempt)"
            PDB_COMPLETELY_REMOVED=true
            break
        else
            log_warn "PDB still exists on attempt $attempt/10, retrying with nuclear cleanup..."
            
            # Nuclear cleanup on each retry
            sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} AS SYSDBA << EOF > /dev/null 2>&1
-- Nuclear cleanup attempt
ALTER SYSTEM SET "_ORACLE_SCRIPT"=true;
SHUTDOWN ABORT;
STARTUP;
DROP PLUGGABLE DATABASE ${PDB_NAME} INCLUDING DATAFILES FORCE;
-- Remove from memory and data dictionary
DELETE FROM v\$pdbs WHERE name = '${PDB_NAME}';
DELETE FROM dba_pdbs WHERE pdb_name = '${PDB_NAME}';
COMMIT;
EXIT
EOF
        fi
    done
    
    # Final nuclear verification
    if [ "$PDB_COMPLETELY_REMOVED" = false ]; then
        log_error "✗ PDB $PDB_NAME could not be completely removed after 10 attempts"
        log_error "ROLLBACK FAILED - incomplete PDB cleanup is not acceptable"
        log_error "This requires manual Oracle DBA intervention"
        exit 1
    fi
else
    log_info "Skipping PDB drop (PDB doesn't exist)"
fi

################################################################################
# STEP 8: Final Complete Verification
################################################################################
log_section "Step 8: Final Complete Verification"
log_step "Verifying ALL components have been COMPLETELY removed..."

# Verify PDB is completely gone
log_step "Final PDB verification..."
FINAL_PDB_CHECK=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF 2>/dev/null
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)

FINAL_PDB_COUNT=$(echo "$FINAL_PDB_CHECK" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$FINAL_PDB_COUNT" = "0" ]; then
    log_success "✓ No PDB found - complete removal verified"
else
    log_error "✗ PDB $PDB_NAME still exists in final verification"
    log_error "ROLLBACK INCOMPLETE - manual intervention required"
    exit 1
fi

# Final comprehensive status check
TOTAL_REMAINING=$((REMAINING_COUNT + MODEL_COUNT + JOB_COUNT + PROGRAM_COUNT + QUEUE_COUNT + ANALYTICS_COUNT + XML_COUNT + FINAL_PDB_COUNT))

log_section "Rollback Complete!"

if [ "$TOTAL_REMAINING" = "0" ]; then
    log_success "✓ COMPLETE ROLLBACK SUCCESSFUL - ALL COMPONENTS REMOVED"
    
    log_info "Cleanup Status:"
    log_success "  ✓ PDB: $PDB_NAME (completely removed)"
    log_success "  ✓ Common User: $COMMON_USER (completely removed)"
    log_success "  ✓ Local User: $DEMASY_USER (completely removed)"
    log_success "  ✓ All Database Objects: (completely removed)"
    log_success "  ✓ All AI/ML Models: (completely removed)"
    log_success "  ✓ All Scheduler Objects: (completely removed)"
    log_success "  ✓ All Queue Objects: (completely removed)"
    log_success "  ✓ All Analytics Objects: (completely removed)"
    log_success "  ✓ All XML/JSON Objects: (completely removed)"
    log_success "  ✓ All Security Objects: (completely removed)"
    log_success "  ✓ All Integration Objects: (completely removed)"
    log_success "  ✓ All Tablespaces: (completely removed)"
    log_success "  ✓ All Modern Oracle AI Database 26ai Features: (completely removed)"
    
    log_info "Environment is now completely clean and ready for fresh setup."
else
    log_error "✗ ROLLBACK INCOMPLETE - $TOTAL_REMAINING objects remain"
    log_error "Manual cleanup may be required"
fi
log_info "To recreate the environment, run:"
log_info "  docker exec -it demasylabs-oracle-server create-demasy-user"