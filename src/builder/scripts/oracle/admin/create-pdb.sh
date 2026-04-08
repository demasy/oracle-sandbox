#!/bin/bash

################################################################################
# Oracle PDB Creation Script
# This script runs FROM INSIDE the Docker container
# Creates a Pluggable Database (PDB) in the CDB if it does not already exist
#
# USAGE:
#   create-pdb.sh <pdb_name>
#
# PARAMETERS:
#   pdb_name  (required) - Name of the PDB to create
#
# EXAMPLES:
#   create-pdb.sh DEMASYLABS_PDB
#   create-pdb.sh ROKETTO_PDB
#   create-pdb.sh MY_APP_PDB
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
    echo "Usage: $(basename "$0") <pdb_name>"
    echo ""
    echo "  pdb_name  (required) Name of the PDB to create"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") DEMASYLABS_PDB"
    echo "  $(basename "$0") ROKETTO_PDB"
    echo ""
    exit 1
fi

INPUT_PDB="$1"

# Validate PDB name
if [[ ! "$INPUT_PDB" =~ ^[a-zA-Z][a-zA-Z0-9_]{0,29}$ ]]; then
    echo ""
    echo "Error: Invalid PDB name '$INPUT_PDB'"
    echo "  • Must start with a letter"
    echo "  • Can contain letters, numbers, and underscores"
    echo "  • Maximum 30 characters"
    echo ""
    exit 1
fi

PDB_NAME="${INPUT_PDB^^}"   # Uppercase — Oracle stores PDB names in uppercase

# Display Demasy Labs banner
print_demasy_banner "Oracle PDB Setup: $PDB_NAME"

################################################################################
# CONFIGURATION - Read from Environment Variables
################################################################################
log_info "Reading configuration from environment variables..."

DB_HOST="${DEMASYLABS_DB_HOST}"
DB_PORT="${DEMASYLABS_DB_PORT}"
DB_PASSWORD="${DEMASYLABS_DB_PASSWORD}"
DB_SID="${DEMASYLABS_DB_SID}"

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
echo "  Host:       $DB_HOST"
echo "  Port:       $DB_PORT"
echo "  CDB:        $DB_SID"
echo "  Target PDB: $PDB_NAME"
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

    CONNECTION_TEST=$(sql -s system/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} << 'EOF' 2>&1
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT 'Connected to ' || SYS_CONTEXT('USERENV', 'CON_NAME') AS connection_info FROM DUAL;
EXIT
EOF
    )

    if echo "$CONNECTION_TEST" | grep -q "Connected to"; then
        log_success "Successfully connected to CDB\$ROOT"
        break
    fi

    if [ $CONNECTION_ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        log_error "Cannot connect to database at ${DB_HOST}:${DB_PORT}/${DB_SID}"
        echo ""
        log_info "Please verify:"
        echo "  • Database is running: docker ps"
        echo "  • Database password is correct (DEMASYLABS_DB_PASSWORD)"
        echo "  • Listener is ready: docker logs demasylabs-oracle-database"
        exit 1
    fi

    log_warn "Connection failed, retrying in 5 seconds..."
    sleep 5
done

################################################################################
# STEP 2: Check if PDB Already Exists
################################################################################
log_section "Step 2: Checking PDB Status"
log_step "Checking if $PDB_NAME exists..."

PDB_EXISTS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT COUNT(*) FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)
PDB_EXISTS=$(echo "$PDB_EXISTS_RAW" | grep -o '[0-9]' | tail -n1 || echo "0")

if [ "$PDB_EXISTS" != "0" ]; then
    # PDB already exists — check its open_mode
    PDB_STATUS_RAW=$(sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SELECT open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
    )
    PDB_STATUS=$(echo "$PDB_STATUS_RAW" | grep -o 'READ WRITE\|MOUNTED\|READ ONLY' | head -n1 || echo "UNKNOWN")

    echo ""
    log_success "PDB $PDB_NAME already exists (status: $PDB_STATUS)"

    if [ "$PDB_STATUS" != "READ WRITE" ]; then
        log_warn "PDB is not open — attempting to open..."
        sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF > /dev/null 2>&1
ALTER PLUGGABLE DATABASE ${PDB_NAME} OPEN;
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;
EXIT
EOF
        log_success "PDB $PDB_NAME opened and state saved"
    fi

    echo ""
    log_info "Nothing to do — $PDB_NAME is ready"
    echo ""
    exit 0
fi

################################################################################
# STEP 3: Create the PDB
################################################################################
log_section "Step 3: Creating PDB"
log_step "Creating PDB $PDB_NAME..."

PDB_DIR=$(echo "$PDB_NAME" | tr '[:upper:]' '[:lower:]')

if sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
CREATE PLUGGABLE DATABASE ${PDB_NAME}
  ADMIN USER pdb_admin IDENTIFIED BY ${DB_PASSWORD}
  FILE_NAME_CONVERT = ('/opt/oracle/oradata/FREE/pdbseed/', '/opt/oracle/oradata/FREE/${PDB_DIR}/');

SELECT 'PDB created: ' || name FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
then
    log_success "PDB $PDB_NAME created successfully"
else
    log_error "Failed to create PDB $PDB_NAME"
    echo ""
    log_info "Existing PDBs:"
    sql -s sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF
SET PAGESIZE 20
SET FEEDBACK OFF
COL name FORMAT A30
COL open_mode FORMAT A15
SELECT name, open_mode FROM v\$pdbs WHERE name != 'PDB\$SEED';
EXIT
EOF
    exit 1
fi

################################################################################
# STEP 4: Open PDB and Save State
################################################################################
log_section "Step 4: Opening PDB"
log_step "Opening $PDB_NAME and saving state for auto-start..."

PDB_OPEN_OUTPUT=$(sql sys/${DB_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SID} as sysdba << EOF 2>&1
ALTER PLUGGABLE DATABASE ${PDB_NAME} OPEN;
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;
SELECT 'Status: ' || open_mode FROM v\$pdbs WHERE name = '${PDB_NAME}';
EXIT
EOF
)

if echo "$PDB_OPEN_OUTPUT" | grep -q "READ WRITE"; then
    log_success "PDB $PDB_NAME is open (READ WRITE) and configured for auto-start"
else
    log_error "Failed to open PDB $PDB_NAME"
    echo "$PDB_OPEN_OUTPUT"
    exit 1
fi

################################################################################
# DONE
################################################################################
echo ""
log_success "PDB $PDB_NAME is ready!"
echo ""
log_info "Connect with:"
echo "  sqlcl <user>/<password>@//${DB_HOST}:${DB_PORT}/${PDB_NAME}"
echo ""
