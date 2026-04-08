#!/bin/bash

################################################################################
# Oracle Grant Privileges Script (Reusable)
# This script runs FROM INSIDE the Docker container
# Grants privileges to an existing local user in a PDB at a specified level
#
# USAGE:
#   grant-privileges.sh <username> [level] [pdb_name]
#
# PARAMETERS:
#   username  (required) - The target user to grant privileges to
#   level     (optional) - Privilege level: minimal | normal | all (default: normal)
#   pdb_name  (optional) - Target PDB name (defaults to DEMASYLABS_PDB)
#
# PRIVILEGE LEVELS:
#   minimal   Basic connectivity + own-schema DDL/DML only
#             CONNECT, RESOURCE, CREATE SESSION, ALTER SESSION, UNLIMITED TABLESPACE
#             CREATE TABLE/VIEW/PROCEDURE/SEQUENCE/TRIGGER/TYPE/SYNONYM/
#                    DATABASE LINK/MATERIALIZED VIEW/JOB
#
#   normal    Everything in minimal, plus:
#             SELECT_CATALOG_ROLE, CREATE ANY/ALTER ANY/DROP ANY for all objects
#             SELECT/INSERT/UPDATE/DELETE/EXECUTE ANY on all tables/procedures
#             Advanced: ANALYZE ANY, LOCK/COMMENT/FLASHBACK ANY TABLE, QUERY REWRITE
#             Mining Models, Scheduler (MANAGE SCHEDULER, EXECUTE ANY CLASS/PROGRAM)
#             CREATE ASSERTION/CREATE ANY ASSERTION
#             Oracle 26ai-specific: Vector, Graph, JSON Search Index, Spatial Index
#
#   all       Everything in normal, plus:
#             DBA role, Tablespace administration
#             Security: CREATE/ALTER/DROP ROLE, PROFILE, USER, POLICY
#             GRANT ANY PRIVILEGE, GRANT ANY OBJECT PRIVILEGE
#             Advanced Queuing (QUEUE, QUEUE TABLE, RULE SET, RULE, TRANSFORM)
#             Analytics & Data Warehouse (CUBE, ANALYTIC VIEW, HIERARCHY)
#             XML & JSON Objects, Integration Objects, Advanced Partitioning
#             Full Scheduler object management (PROGRAM, CLASS, SCHEDULE, CHAIN)
#
# EXAMPLES:
#   grant-privileges.sh myuser
#   grant-privileges.sh myuser minimal
#   grant-privileges.sh myuser normal MY_PDB
#   grant-privileges.sh myuser all MY_PDB
################################################################################

set -e

# Get the actual script location (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source utilities from the actual script location
source "/usr/sandbox/app/system/utils/banner.sh"
source "/usr/sandbox/app/system/utils/logging.sh"
source "/usr/sandbox/app/system/utils/colors.sh"

################################################################################
# PARSE PARAMETERS
################################################################################

if [ $# -eq 0 ]; then
    echo ""
    echo "Usage: $(basename "$0") <username> [level] [pdb_name]"
    echo ""
    echo "  username   (required) Target user to grant privileges to"
    echo "  level      (optional) minimal | normal | all  (default: normal)"
    echo "  pdb_name   (optional) Target PDB name        (default: DEMASYLABS_PDB)"
    echo ""
    echo "Levels:"
    echo "  minimal    Basic connectivity + own-schema DDL/DML"
    echo "  normal     All CREATE/ALTER/DROP/DML ANY + Oracle 26ai objects"
    echo "  all        Everything: DBA role + admin + full Oracle 26ai object suite"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") myuser"
    echo "  $(basename "$0") myuser minimal"
    echo "  $(basename "$0") myuser normal MY_PDB"
    echo "  $(basename "$0") myuser all MY_PDB"
    echo ""
    exit 1
fi

# Assign parameters
INPUT_USER="$1"
INPUT_LEVEL="${2:-normal}"
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

# Normalize and validate level
PRIV_LEVEL=$(echo "$INPUT_LEVEL" | tr '[:upper:]' '[:lower:]')
if [[ "$PRIV_LEVEL" != "minimal" && "$PRIV_LEVEL" != "normal" && "$PRIV_LEVEL" != "all" ]]; then
    echo ""
    echo "Error: Invalid privilege level '$INPUT_LEVEL'"
    echo "  Valid levels: minimal | normal | all"
    echo ""
    exit 1
fi

# Display Demasy Labs banner
print_demasy_banner "Oracle Grant Privileges: $INPUT_USER ($PRIV_LEVEL)"

################################################################################
# CONFIGURATION - Read from Environment Variables
################################################################################
log_info "Reading configuration from environment variables..."

DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
DB_SID="${DEMASYLABS_DB_SID}"

# Apply parameter overrides
TARGET_USER=$(echo "$INPUT_USER" | tr '[:lower:]' '[:upper:]')
PDB_NAME="${INPUT_PDB:-DEMASYLABS_PDB}"

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

log_info "Configuration:"
echo "  Host:        $DB_HOST"
echo "  Port:        $DB_PORT"
echo "  CDB:         $DB_SID"
echo "  Target PDB:  $PDB_NAME"
echo "  Target User: $TARGET_USER"
echo "  Level:       $PRIV_LEVEL"
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
        log_error "Cannot connect to database at ${DB_HOST}:${DB_PORT}/${DB_SID}"
        exit 1
    fi

    log_warn "Connection failed, retrying in 5 seconds..."
    sleep 5
done

################################################################################
# STEP 2: Verify PDB Is Open
################################################################################
log_section "Step 2: Verifying Target PDB"
log_step "Checking if $PDB_NAME exists and is open..."

PDB_STATUS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)
PDB_STATUS=$(echo "$PDB_STATUS_RAW" | grep -o 'READ WRITE\|MOUNTED\|READ ONLY' | head -n1 || echo "UNKNOWN")

if [ "$PDB_STATUS" = "READ WRITE" ]; then
    log_success "PDB $PDB_NAME is open (READ WRITE)"
elif [ "$PDB_STATUS" = "MOUNTED" ] || [ "$PDB_STATUS" = "READ ONLY" ]; then
    log_warn "PDB $PDB_NAME is not fully open (status: $PDB_STATUS). Attempting to open..."
    sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF > /dev/null 2>&1
ALTER PLUGGABLE DATABASE ${PDB_NAME} OPEN;
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;
EXIT
EOF
    log_success "PDB $PDB_NAME opened"
else
    log_error "PDB $PDB_NAME not found or unavailable (status: $PDB_STATUS)"
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

################################################################################
# STEP 3: Verify User Exists in PDB
################################################################################
log_section "Step 3: Verifying Target User"
log_step "Checking if user $TARGET_USER exists in PDB $PDB_NAME..."

USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '${TARGET_USER}';
EXIT
EOF
)
USER_EXISTS=$(echo "$USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$USER_EXISTS" = "0" ]; then
    log_error "User $TARGET_USER does not exist in PDB $PDB_NAME"
    log_info "Use create_user.sh to create the user first."
    log_info "Available users:"
    sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 20
SET FEEDBACK OFF
COL username FORMAT A30
SELECT username FROM dba_users WHERE oracle_maintained = 'N' ORDER BY username;
EXIT
EOF
    exit 1
fi

log_success "User $TARGET_USER found in PDB $PDB_NAME"

################################################################################
# STEP 4: Build Grant SQL
################################################################################
log_section "Step 4: Building Privilege Grant SQL"
log_step "Preparing $PRIV_LEVEL privilege grants for $TARGET_USER..."

GRANT_SQL="/tmp/grant_privileges_${TARGET_USER}_$$.sql"
trap "rm -f ${GRANT_SQL}" EXIT

# ── MINIMAL LEVEL ─────────────────────────────────────────────────────────────
cat >> "$GRANT_SQL" << EOF
-- ============================================================
-- MINIMAL: Basic connectivity and own-schema privileges
-- ============================================================
ALTER SESSION SET CONTAINER = ${PDB_NAME};

-- Roles
GRANT CONNECT TO ${TARGET_USER};
GRANT RESOURCE TO ${TARGET_USER};
GRANT UNLIMITED TABLESPACE TO ${TARGET_USER};

-- Session privileges
GRANT CREATE SESSION TO ${TARGET_USER};
GRANT ALTER SESSION TO ${TARGET_USER};

-- Own-schema DDL
GRANT CREATE TABLE TO ${TARGET_USER};
GRANT CREATE VIEW TO ${TARGET_USER};
GRANT CREATE PROCEDURE TO ${TARGET_USER};
GRANT CREATE SEQUENCE TO ${TARGET_USER};
GRANT CREATE TRIGGER TO ${TARGET_USER};
GRANT CREATE TYPE TO ${TARGET_USER};
GRANT CREATE SYNONYM TO ${TARGET_USER};
GRANT CREATE DATABASE LINK TO ${TARGET_USER};
GRANT CREATE MATERIALIZED VIEW TO ${TARGET_USER};
GRANT CREATE JOB TO ${TARGET_USER};

EOF

if [[ "$PRIV_LEVEL" == "normal" || "$PRIV_LEVEL" == "all" ]]; then
# ── NORMAL LEVEL ──────────────────────────────────────────────────────────────
cat >> "$GRANT_SQL" << EOF
-- ============================================================
-- NORMAL: CREATE ANY / ALTER ANY / DROP ANY + DML on all objects
-- ============================================================

-- Catalog role
GRANT SELECT_CATALOG_ROLE TO ${TARGET_USER};

-- CREATE ANY privileges
GRANT CREATE ANY TABLE TO ${TARGET_USER};
GRANT CREATE ANY VIEW TO ${TARGET_USER};
GRANT CREATE ANY PROCEDURE TO ${TARGET_USER};
GRANT CREATE ANY SEQUENCE TO ${TARGET_USER};
GRANT CREATE ANY TRIGGER TO ${TARGET_USER};
GRANT CREATE ANY TYPE TO ${TARGET_USER};
GRANT CREATE ANY INDEX TO ${TARGET_USER};
GRANT CREATE PUBLIC SYNONYM TO ${TARGET_USER};
GRANT CREATE ANY CLUSTER TO ${TARGET_USER};
GRANT CREATE ANY CONTEXT TO ${TARGET_USER};
GRANT CREATE ANY DIMENSION TO ${TARGET_USER};
GRANT CREATE ANY OPERATOR TO ${TARGET_USER};
GRANT CREATE ANY INDEXTYPE TO ${TARGET_USER};
GRANT CREATE ANY OUTLINE TO ${TARGET_USER};
GRANT CREATE ANY MATERIALIZED VIEW TO ${TARGET_USER};
GRANT CREATE ANY EDITION TO ${TARGET_USER};
GRANT CREATE ANY SQL TRANSLATION PROFILE TO ${TARGET_USER};
GRANT CREATE ASSERTION TO ${TARGET_USER};
GRANT CREATE ANY ASSERTION TO ${TARGET_USER};
GRANT CREATE LIBRARY TO ${TARGET_USER};

-- ALTER ANY privileges
GRANT ALTER ANY TABLE TO ${TARGET_USER};
GRANT ALTER ANY SEQUENCE TO ${TARGET_USER};
GRANT ALTER ANY INDEX TO ${TARGET_USER};
GRANT ALTER ANY PROCEDURE TO ${TARGET_USER};
GRANT ALTER ANY TRIGGER TO ${TARGET_USER};
GRANT ALTER ANY OUTLINE TO ${TARGET_USER};
GRANT ALTER ANY MATERIALIZED VIEW TO ${TARGET_USER};
GRANT ALTER ANY EDITION TO ${TARGET_USER};
GRANT ALTER ANY TYPE TO ${TARGET_USER};
GRANT ALTER ANY SQL TRANSLATION PROFILE TO ${TARGET_USER};

-- DROP ANY privileges
GRANT DROP ANY TABLE TO ${TARGET_USER};
GRANT DROP ANY VIEW TO ${TARGET_USER};
GRANT DROP ANY SEQUENCE TO ${TARGET_USER};
GRANT DROP ANY PROCEDURE TO ${TARGET_USER};
GRANT DROP ANY TRIGGER TO ${TARGET_USER};
GRANT DROP ANY INDEX TO ${TARGET_USER};
GRANT DROP ANY TYPE TO ${TARGET_USER};
GRANT DROP PUBLIC SYNONYM TO ${TARGET_USER};
GRANT DROP ANY CLUSTER TO ${TARGET_USER};
GRANT DROP ANY CONTEXT TO ${TARGET_USER};
GRANT DROP ANY DIMENSION TO ${TARGET_USER};
GRANT DROP ANY OPERATOR TO ${TARGET_USER};
GRANT DROP ANY INDEXTYPE TO ${TARGET_USER};
GRANT DROP ANY OUTLINE TO ${TARGET_USER};
GRANT DROP ANY MATERIALIZED VIEW TO ${TARGET_USER};
GRANT DROP ANY EDITION TO ${TARGET_USER};
GRANT DROP ANY SQL TRANSLATION PROFILE TO ${TARGET_USER};

-- DML on all objects
GRANT SELECT ANY TABLE TO ${TARGET_USER};
GRANT INSERT ANY TABLE TO ${TARGET_USER};
GRANT UPDATE ANY TABLE TO ${TARGET_USER};
GRANT DELETE ANY TABLE TO ${TARGET_USER};
GRANT EXECUTE ANY PROCEDURE TO ${TARGET_USER};
GRANT EXECUTE ANY TYPE TO ${TARGET_USER};
GRANT EXECUTE ANY LIBRARY TO ${TARGET_USER};

-- Advanced development
GRANT COMMENT ANY TABLE TO ${TARGET_USER};
GRANT LOCK ANY TABLE TO ${TARGET_USER};
GRANT FLASHBACK ANY TABLE TO ${TARGET_USER};
GRANT ANALYZE ANY TO ${TARGET_USER};
GRANT QUERY REWRITE TO ${TARGET_USER};
GRANT GLOBAL QUERY REWRITE TO ${TARGET_USER};
GRANT MERGE ANY VIEW TO ${TARGET_USER};
GRANT USE ANY SQL TRANSLATION PROFILE TO ${TARGET_USER};

-- Oracle AI Database Mining Models
GRANT CREATE MINING MODEL TO ${TARGET_USER};
GRANT ALTER ANY MINING MODEL TO ${TARGET_USER};
GRANT DROP ANY MINING MODEL TO ${TARGET_USER};
GRANT SELECT ANY MINING MODEL TO ${TARGET_USER};
GRANT COMMENT ANY MINING MODEL TO ${TARGET_USER};

-- Scheduler
GRANT CREATE ANY JOB TO ${TARGET_USER};
GRANT EXECUTE ANY CLASS TO ${TARGET_USER};
GRANT EXECUTE ANY PROGRAM TO ${TARGET_USER};
GRANT MANAGE SCHEDULER TO ${TARGET_USER};

-- Oracle AI Database 26ai-specific objects (version-safe)
BEGIN
    -- Vector
    EXECUTE IMMEDIATE 'GRANT CREATE ANY VECTOR INDEX TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY VECTOR INDEX TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY VECTOR INDEX TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY VECTOR TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY VECTOR TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT UPDATE ANY VECTOR TO ${TARGET_USER}';
    -- JSON Search Index
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON SEARCH INDEX TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON SEARCH INDEX TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON SEARCH INDEX TO ${TARGET_USER}';
    -- Graph
    EXECUTE IMMEDIATE 'GRANT CREATE ANY GRAPH TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY GRAPH TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY GRAPH TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY GRAPH TO ${TARGET_USER}';
    -- Spatial
    EXECUTE IMMEDIATE 'GRANT CREATE ANY SPATIAL INDEX TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY SPATIAL INDEX TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY SPATIAL INDEX TO ${TARGET_USER}';
    -- Scheduler objects
    EXECUTE IMMEDIATE 'GRANT CREATE ANY PROGRAM TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY PROGRAM TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY PROGRAM TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CLASS TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CLASS TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CLASS TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY SCHEDULE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY SCHEDULE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY SCHEDULE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CHAIN TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CHAIN TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CHAIN TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY FILE WATCHER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY FILE WATCHER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY FILE WATCHER TO ${TARGET_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

EOF
fi  # end normal

if [[ "$PRIV_LEVEL" == "all" ]]; then
# ── ALL LEVEL ─────────────────────────────────────────────────────────────────
cat >> "$GRANT_SQL" << EOF
-- ============================================================
-- ALL: DBA role + full administrative + extended object suite
-- ============================================================

-- DBA role
GRANT DBA TO ${TARGET_USER};

-- Tablespace administration
GRANT FLASHBACK ARCHIVE ADMINISTER TO ${TARGET_USER};
GRANT CREATE TABLESPACE TO ${TARGET_USER};
GRANT ALTER TABLESPACE TO ${TARGET_USER};
GRANT DROP TABLESPACE TO ${TARGET_USER};
GRANT MANAGE TABLESPACE TO ${TARGET_USER};

-- Security Objects
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ROLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY ROLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY ROLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT GRANT ANY ROLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE PROFILE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER PROFILE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP PROFILE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE USER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER USER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP USER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY POLICY TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY POLICY TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY POLICY TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT GRANT ANY PRIVILEGE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT GRANT ANY OBJECT PRIVILEGE TO ${TARGET_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Advanced Queuing & Streams
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY QUEUE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY QUEUE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY QUEUE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ENQUEUE ANY QUEUE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DEQUEUE ANY QUEUE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY QUEUE TABLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY QUEUE TABLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY QUEUE TABLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY RULE SET TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY RULE SET TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY RULE SET TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY RULE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY RULE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY RULE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY TRANSFORM TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY TRANSFORM TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY TRANSFORM TO ${TARGET_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Analytics & Data Warehouse
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CUBE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CUBE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CUBE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY CUBE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY MEASURE FOLDER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY MEASURE FOLDER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY MEASURE FOLDER TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY ANALYTIC VIEW TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY ANALYTIC VIEW TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY ANALYTIC VIEW TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY ANALYTIC VIEW TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY HIERARCHY TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY HIERARCHY TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY HIERARCHY TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY HIERARCHY TO ${TARGET_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- XML & JSON Objects
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY XML SCHEMA TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY XML SCHEMA TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY XML SCHEMA TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT UNDER ANY TYPE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT UNDER ANY VIEW TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON COLLECTION TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON COLLECTION TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON COLLECTION TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY JSON SCHEMA TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY JSON SCHEMA TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY JSON SCHEMA TO ${TARGET_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Integration Objects
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE ANY EXTERNAL TABLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY EXTERNAL TABLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY EXTERNAL TABLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY EXTERNAL TABLE TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY CREDENTIAL TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY CREDENTIAL TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY CREDENTIAL TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY DESTINATION TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT ALTER ANY DESTINATION TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY DESTINATION TO ${TARGET_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Advanced Partitioning
BEGIN
    EXECUTE IMMEDIATE 'GRANT ALTER ANY PARTITION TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT DROP ANY PARTITION TO ${TARGET_USER}';
    EXECUTE IMMEDIATE 'GRANT MANAGE ANY PARTITION TO ${TARGET_USER}';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

EOF
fi  # end all

# Append summary query
cat >> "$GRANT_SQL" << EOF
-- Summary
SELECT '${TARGET_USER} now has ' ||
       (SELECT COUNT(*) FROM dba_sys_privs  WHERE grantee = '${TARGET_USER}') || ' system privileges and ' ||
       (SELECT COUNT(*) FROM dba_role_privs WHERE grantee = '${TARGET_USER}') || ' roles' AS result
FROM DUAL;

EXIT
EOF

log_success "Grant SQL prepared for level: $PRIV_LEVEL"

################################################################################
# STEP 5: Execute Grant SQL
################################################################################
log_section "Step 5: Executing Privilege Grants"
log_step "Granting $PRIV_LEVEL privileges to $TARGET_USER in PDB $PDB_NAME..."

if GRANT_OUTPUT=$(sql system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} @"$GRANT_SQL" 2>&1); then
    if echo "$GRANT_OUTPUT" | grep -qi "ORA-[0-9]"; then
        # Some grants may fail (e.g. privilege not available in this edition) — warn but don't fail
        WARN_LINES=$(echo "$GRANT_OUTPUT" | grep -i "ORA-[0-9]" | head -5)
        log_warn "Some grants produced warnings (version-specific or already granted):"
        echo "$WARN_LINES" | while IFS= read -r line; do echo "    $line"; done
    fi

    if echo "$GRANT_OUTPUT" | grep -qi "system privileges"; then
        RESULT_LINE=$(echo "$GRANT_OUTPUT" | grep -i "system privileges" | head -1 | xargs)
        log_success "Grants applied: $RESULT_LINE"
    else
        log_success "Grants executed successfully"
    fi
else
    log_error "Failed to execute privilege grants"
    log_error "$GRANT_OUTPUT"
    exit 1
fi

################################################################################
# STEP 6: Verification
################################################################################
log_section "Step 6: Verification"
log_step "Verifying privilege counts for $TARGET_USER..."

SYS_PRIV_COUNT_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_sys_privs WHERE grantee = '${TARGET_USER}';
EXIT
EOF
)
SYS_PRIV_COUNT=$(echo "$SYS_PRIV_COUNT_RAW" | grep -o '[0-9]*' | tail -n1 || echo "0")

ROLE_COUNT_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_role_privs WHERE grantee = '${TARGET_USER}';
EXIT
EOF
)
ROLE_COUNT=$(echo "$ROLE_COUNT_RAW" | grep -o '[0-9]*' | tail -n1 || echo "0")

if [[ "$SYS_PRIV_COUNT" -gt 0 ]] || [[ "$ROLE_COUNT" -gt 0 ]]; then
    log_success "✓ $TARGET_USER now has $SYS_PRIV_COUNT system privileges and $ROLE_COUNT roles"
else
    log_warn "⚠ Could not verify privileges for $TARGET_USER (may already have been granted)"
fi

################################################################################
# COMPLETION SUMMARY
################################################################################
log_section "Done!"
log_success "$PRIV_LEVEL privileges granted to '$TARGET_USER' in PDB '$PDB_NAME'"

echo ""
log_info "Grant Summary:"
echo ""
echo "👤 Target User:  $TARGET_USER"
echo "📦 PDB:          $PDB_NAME"
echo "🔐 Level:        $PRIV_LEVEL"
echo "📊 Privileges:   $SYS_PRIV_COUNT system + $ROLE_COUNT roles"
echo ""

case "$PRIV_LEVEL" in
    minimal)
        echo "💡 Minimal level grants:"
        echo "   • CONNECT, RESOURCE, UNLIMITED TABLESPACE"
        echo "   • CREATE TABLE/VIEW/PROCEDURE/SEQUENCE/TRIGGER/TYPE"
        echo "   • CREATE SYNONYM/DATABASE LINK/MATERIALIZED VIEW/JOB"
        ;;
    normal)
        echo "💡 Normal level grants (cumulative):"
        echo "   • All MINIMAL grants"
        echo "   • CREATE ANY / ALTER ANY / DROP ANY for all schema objects"
        echo "   • SELECT/INSERT/UPDATE/DELETE/EXECUTE ANY"
        echo "   • CREATE ASSERTION / CREATE ANY ASSERTION"
        echo "   • Oracle AI 26ai: Vector, Graph, JSON Search, Spatial Index"
        echo "   • Mining Models + full Scheduler management"
        ;;
    all)
        echo "💡 All level grants (cumulative):"
        echo "   • All MINIMAL + NORMAL grants"
        echo "   • DBA role"
        echo "   • Tablespace administration"
        echo "   • Security: CREATE/ALTER/DROP ROLE/PROFILE/USER/POLICY"
        echo "   • GRANT ANY PRIVILEGE / GRANT ANY OBJECT PRIVILEGE"
        echo "   • Advanced Queuing, Analytics/DW, XML/JSON, Integration"
        echo "   • Advanced Partitioning"
        ;;
esac

echo ""
log_success "Privilege grant complete! 🚀"
