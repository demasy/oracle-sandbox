#!/bin/bash

################################################################################
# Oracle Create Database Link Script (Reusable)
# This script runs FROM INSIDE the Docker container
# Creates a private database link for an existing local user in a PDB
#
# USAGE:
#   create-db-link.sh <link_name> <owner_user> <owner_password> <remote_user> <remote_password> \
#                     <remote_host> <remote_port> <remote_service> [pdb_name]
#
# PARAMETERS:
#   link_name        (required) - Name for the database link
#   owner_user       (required) - Local PDB user who will own the link
#   owner_password   (required) - Password for the local PDB owner user
#   remote_user      (required) - Username on the remote database
#   remote_password  (required) - Password on the remote database
#   remote_host      (required) - Remote database hostname or IP
#   remote_port      (required) - Remote database listener port
#   remote_service   (required) - Remote database service name
#   pdb_name         (optional) - Local PDB name (defaults to DEMASYLABS_PDB)
#
# EXAMPLES:
#   create-db-link.sh ebs_link roketto Roketto1986 apps apps ORACLE.ROKETTO.MOBI 1521 EBSDB ROKETTO_PDB
#   create-db-link.sh prod_link myuser MyPass01 sys SysPass01 192.168.1.10 1521 PRODDB
#   create-db-link.sh hr_link demasy Demasy1986 hr hrpass 10.0.0.5 1521 HRPDB DEMASYLABS_PDB
#
# NOTES:
#   - Creates a PRIVATE database link (owned by owner_user, not PUBLIC)
#   - If a link with the same name already exists for the owner it is dropped
#     and recreated (safe update of credentials or target)
#   - Verifies connectivity with: SELECT 'LINK_OK' FROM DUAL@<link_name>
#   - Requires CREATE DATABASE LINK privilege on owner_user
################################################################################

set -e

# Get the actual script location (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source utilities
source "$SCRIPT_DIR/../../backbone/utils/banner.sh"
source "$SCRIPT_DIR/../../backbone/utils/logging.sh"
source "$SCRIPT_DIR/../../backbone/utils/colors.sh"

################################################################################
# PARSE PARAMETERS
################################################################################

if [ $# -lt 8 ]; then
    echo ""
    echo "Usage: $(basename "$0") <link_name> <owner_user> <owner_password> <remote_user> <remote_password> \\"
    echo "                        <remote_host> <remote_port> <remote_service> [pdb_name]"
    echo ""
    echo "  link_name        (required) Name for the database link"
    echo "  owner_user       (required) Local PDB user who will own the link"
    echo "  owner_password   (required) Password for the local PDB owner user"
    echo "  remote_user      (required) Username on the remote database"
    echo "  remote_password  (required) Password on the remote database"
    echo "  remote_host      (required) Remote database hostname or IP"
    echo "  remote_port      (required) Remote database listener port (e.g. 1521)"
    echo "  remote_service   (required) Remote database service name"
    echo "  pdb_name         (optional) Local PDB name (default: DEMASYLABS_PDB)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") ebs_link roketto Roketto1986 apps apps ORACLE.ROKETTO.MOBI 1521 EBSDB ROKETTO_PDB"
    echo "  $(basename "$0") prod_link myuser MyPass01 sys SysPass01 192.168.1.10 1521 PRODDB"
    echo ""
    exit 1
fi

LINK_NAME="$1"
OWNER_USER="$2"
OWNER_PASSWORD="$3"
REMOTE_USER="$4"
REMOTE_PASSWORD="$5"
REMOTE_HOST="$6"
REMOTE_PORT="$7"
REMOTE_SERVICE="$8"
INPUT_PDB="${9:-}"

# Validate link name (Oracle identifier rules, max 128 chars)
if [[ ! "$LINK_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_$.]{0,127}$ ]]; then
    echo ""
    echo "Error: Invalid link name '$LINK_NAME'"
    echo "  • Must start with a letter"
    echo "  • Can contain letters, numbers, underscores, \$ and dots"
    echo "  • Maximum 128 characters"
    echo ""
    exit 1
fi

# Validate owner username
if [[ ! "$OWNER_USER" =~ ^[a-zA-Z][a-zA-Z0-9_]{0,29}$ ]]; then
    echo ""
    echo "Error: Invalid owner username '$OWNER_USER'"
    echo "  • Must start with a letter"
    echo "  • Can contain letters, numbers, and underscores"
    echo "  • Maximum 30 characters"
    echo ""
    exit 1
fi

# Validate port
if [[ ! "$REMOTE_PORT" =~ ^[0-9]+$ ]] || [ "$REMOTE_PORT" -lt 1 ] || [ "$REMOTE_PORT" -gt 65535 ]; then
    echo ""
    echo "Error: Invalid port '$REMOTE_PORT' — must be a number between 1 and 65535"
    echo ""
    exit 1
fi

# Normalize to uppercase for Oracle comparisons
LINK_NAME_UPPER=$(echo "$LINK_NAME"   | tr '[:lower:]' '[:upper:]')
OWNER_USER_UPPER=$(echo "$OWNER_USER" | tr '[:lower:]' '[:upper:]')
PDB_NAME="${INPUT_PDB:-DEMASYLABS_PDB}"

# Display banner
print_demasy_banner "Oracle Create DB Link: $LINK_NAME"

################################################################################
# CONFIGURATION - Read from Environment Variables
################################################################################
log_info "Reading configuration from environment variables..."

DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
DB_SID="${DEMASYLABS_DB_SID}"

log_step "Validating environment variables..."
MISSING_VARS=()
[[ -z "$DB_HOST" ]]     && MISSING_VARS+=("DEMASYLABS_DB_HOST")
[[ -z "$DB_PORT" ]]     && MISSING_VARS+=("DEMASYLABS_DB_PORT")
[[ -z "$DB_PASSWORD" ]] && MISSING_VARS+=("DEMASYLABS_DB_PASSWORD")
[[ -z "$DB_SID" ]]      && MISSING_VARS+=("DEMASYLABS_DB_SID")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    log_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do echo "  ✗ $var"; done
    echo ""
    log_info "Please ensure all required environment variables are set in docker-compose.yml"
    exit 1
fi

log_success "All required environment variables are present"

log_info "Configuration:"
echo "  Local DB Host:    $DB_HOST"
echo "  Local DB Port:    $DB_PORT"
echo "  Local CDB:        $DB_SID"
echo "  Local PDB:        $PDB_NAME"
echo "  Link Owner:       $OWNER_USER_UPPER"
echo "  Link Name:        $LINK_NAME_UPPER"
echo "  Remote Host:      $REMOTE_HOST"
echo "  Remote Port:      $REMOTE_PORT"
echo "  Remote Service:   $REMOTE_SERVICE"
echo "  Remote User:      $REMOTE_USER"
echo "  Owner Password:   [provided]"
echo "  Remote Password:  [provided]"
echo ""

################################################################################
# STEP 1: Test Local Database Connection
################################################################################
log_section "Step 1: Testing Local Database Connection"
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
        log_error "Last output: $CONNECTION_TEST"
        exit 1
    fi

    log_warn "Connection failed, retrying in 5 seconds..."
    sleep 5
done

################################################################################
# STEP 2: Verify PDB Is Open
################################################################################
log_section "Step 2: Verifying Local PDB"
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
# STEP 3: Verify Owner User Exists in PDB
################################################################################
log_section "Step 3: Verifying Link Owner"
log_step "Checking if user $OWNER_USER_UPPER exists in PDB $PDB_NAME..."

USER_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_users WHERE username = '${OWNER_USER_UPPER}';
EXIT
EOF
)
USER_EXISTS=$(echo "$USER_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$USER_EXISTS" = "0" ]; then
    log_error "User $OWNER_USER_UPPER does not exist in PDB $PDB_NAME"
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

log_success "User $OWNER_USER_UPPER found in PDB $PDB_NAME"

################################################################################
# STEP 4: Check If Link Already Exists (Drop If So)
################################################################################
log_section "Step 4: Checking Existing Links"
log_step "Checking if link $LINK_NAME_UPPER already exists for $OWNER_USER_UPPER..."

LINK_EXISTS_RAW=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM dba_db_links
WHERE db_link = '${LINK_NAME_UPPER}'
  AND owner   = '${OWNER_USER_UPPER}';
EXIT
EOF
)
LINK_EXISTS=$(echo "$LINK_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$LINK_EXISTS" = "1" ]; then
    log_warn "Link $LINK_NAME_UPPER already exists for $OWNER_USER_UPPER — dropping and recreating..."
    DROP_OUTPUT=$(sql ${OWNER_USER}/${OWNER_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << EOF 2>&1
DROP DATABASE LINK ${LINK_NAME};
EXIT
EOF
    )
    if echo "$DROP_OUTPUT" | grep -qi "ORA-[0-9]"; then
        log_warn "Drop warning: $(echo "$DROP_OUTPUT" | grep -i 'ORA-' | head -1 | xargs)"
    else
        log_success "Existing link $LINK_NAME_UPPER dropped"
    fi
else
    log_success "No existing link named $LINK_NAME_UPPER — proceeding with creation"
fi

################################################################################
# STEP 5: Create the Database Link
################################################################################
log_section "Step 5: Creating Database Link"
log_step "Creating private database link $LINK_NAME for $OWNER_USER_UPPER..."

CREATE_OUTPUT=$(sql ${OWNER_USER}/${OWNER_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << EOF 2>&1
CREATE DATABASE LINK ${LINK_NAME}
  CONNECT TO ${REMOTE_USER} IDENTIFIED BY "${REMOTE_PASSWORD}"
  USING '//${REMOTE_HOST}:${REMOTE_PORT}/${REMOTE_SERVICE}';

SELECT 'LINK_CREATED' AS status FROM DUAL;
EXIT
EOF
)

if echo "$CREATE_OUTPUT" | grep -q "LINK_CREATED\|Database link created"; then
    log_success "Database link $LINK_NAME created successfully"
else
    log_error "Failed to create database link $LINK_NAME"
    log_error "Output: $CREATE_OUTPUT"
    exit 1
fi

################################################################################
# STEP 6: Verify the Link Works
################################################################################
log_section "Step 6: Verifying Database Link"
log_step "Testing link connectivity: SELECT FROM DUAL@${LINK_NAME}..."

VERIFY_OUTPUT=$(sql -s ${OWNER_USER}/${OWNER_PASSWORD}@//${DB_HOST}:${DB_PORT}/${PDB_NAME} << EOF 2>&1
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT 'LINK_OK' AS result FROM DUAL@${LINK_NAME};
EXIT
EOF
)

if echo "$VERIFY_OUTPUT" | grep -q "LINK_OK"; then
    log_success "✓ Link $LINK_NAME is active — remote database responded"
    LINK_STATUS="VERIFIED ✓"
elif echo "$VERIFY_OUTPUT" | grep -qi "ORA-[0-9]"; then
    ORA_ERR=$(echo "$VERIFY_OUTPUT" | grep -i "ORA-" | head -1 | xargs)
    log_warn "⚠ Link created but remote test failed: $ORA_ERR"
    log_warn "  The link definition is saved. Remote may be unreachable or credentials invalid."
    LINK_STATUS="CREATED (unverified)"
else
    log_warn "⚠ Unexpected test output: $VERIFY_OUTPUT"
    LINK_STATUS="CREATED (unverified)"
fi

################################################################################
# COMPLETION SUMMARY
################################################################################
log_section "Done!"
log_success "Database link '$LINK_NAME_UPPER' ready for user '$OWNER_USER_UPPER' in PDB '$PDB_NAME'"

echo ""
log_info "Link Details:"
echo ""
echo "🔗 Link Name:      $LINK_NAME_UPPER"
echo "👤 Owner:          $OWNER_USER_UPPER"
echo "📦 Local PDB:      $PDB_NAME"
echo "🌐 Remote Target:  //${REMOTE_HOST}:${REMOTE_PORT}/${REMOTE_SERVICE}"
echo "👁  Remote User:    $REMOTE_USER"
echo "✅ Status:         $LINK_STATUS"
echo ""
echo "💡 Usage examples (as $OWNER_USER):"
echo "   SELECT * FROM some_table@${LINK_NAME};"
echo "   SELECT * FROM some_table@${LINK_NAME} WHERE rownum <= 10;"
echo "   INSERT INTO local_table SELECT * FROM remote_table@${LINK_NAME};"
echo ""

log_step "All database links owned by $OWNER_USER_UPPER in $PDB_NAME:"
sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << EOF
ALTER SESSION SET CONTAINER = ${PDB_NAME};
SET PAGESIZE 20
SET FEEDBACK OFF
COL db_link  FORMAT A30
COL username FORMAT A20
COL host     FORMAT A55
SELECT db_link, username, host FROM dba_db_links WHERE owner = '${OWNER_USER_UPPER}' ORDER BY db_link;
EXIT
EOF

echo ""
log_success "Database link setup complete! 🚀"
