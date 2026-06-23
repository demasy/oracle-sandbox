#!/bin/bash
# ============================================
# Oracle Sandbox - Create Tablespace Script
# ============================================
# Creates a tablespace in a specified PDB
# Fully parameterized and reusable component
# 
# Usage: create-tablespace.sh PDB_NAME TABLESPACE_NAME SIZE [OPTIONS]
#
# Positional Parameters:
#   PDB_NAME          - Name of the Pluggable Database (e.g., SANDBOX_PDB)
#   TABLESPACE_NAME   - Name of the tablespace to create (e.g., SANDBOX_TS)
#   SIZE              - Size of the tablespace (e.g., 1G, 500M)
#
# Options (all configurable via environment variables):
#   --datafile-path PATH          Path to datafile (default: $ORACLE_BASE/oradata/{PDB_NAME})
#   --autoextend ON|OFF           Enable autoextend (default: ON)
#   --next-size SIZE              Next extent size (default: 100M)
#   --maxsize SIZE|UNLIMITED      Max size (default: UNLIMITED)
#   --logging ON|OFF              Enable logging (default: ON)
#   --extent-type LOCAL|DICTIONARY Extent management (default: LOCAL)
#   --segment-space MANUAL|AUTO   Segment space mgmt (default: AUTO)
#   --dry-run                     Preview SQL without execution
#
# Environment Variables:
#   ORACLE_BASE                   Oracle installation root (default: /opt/oracle)
#   ORACLE_SID                    Container Database SID (default: orcl)
#   ORACLE_HOME                   Oracle home (auto-detected if not set)
#   TS_AUTOEXTEND                 Override --autoextend
#   TS_NEXT_SIZE                  Override --next-size
#   TS_MAXSIZE                    Override --maxsize
#   TS_LOGGING                    Override --logging
#   TS_EXTENT_TYPE                Override --extent-type
#   TS_SEGMENT_SPACE              Override --segment-space
#
# Examples:
#   # Basic usage
#   create-tablespace.sh SANDBOX_PDB SANDBOX_TS 1G
#
#   # Custom autoextend
#   create-tablespace.sh DEMASY_PDB DEMASY_TS 500M --autoextend OFF --maxsize 5G
#
#   # Custom path with logging disabled
#   create-tablespace.sh DEMASYLABS_PDB DEMASYLABS_TS 12G --datafile-path /custom/path --logging OFF
#
#   # Dry-run to preview SQL
#   create-tablespace.sh SANDBOX_PDB TEST_TS 100M --dry-run
#
#   # Using environment variables
#   export TS_AUTOEXTEND=OFF
#   export TS_NEXT_SIZE=200M
#   create-tablespace.sh SANDBOX_PDB SANDBOX_TS 1G
#
# ============================================

set -euo pipefail

# ============================================
# Configuration - All Parameterized
# ============================================
ORACLE_BASE="${ORACLE_BASE:-/opt/oracle}"
ORACLE_SID="${ORACLE_SID:-orcl}"
ORACLE_HOME="${ORACLE_HOME:-$ORACLE_BASE/product/26c}"

# Tablespace Configuration - All via Environment or Parameters
TS_AUTOEXTEND="${TS_AUTOEXTEND:-ON}"
TS_NEXT_SIZE="${TS_NEXT_SIZE:-100M}"
TS_MAXSIZE="${TS_MAXSIZE:-UNLIMITED}"
TS_LOGGING="${TS_LOGGING:-ON}"
TS_EXTENT_TYPE="${TS_EXTENT_TYPE:-LOCAL}"
TS_SEGMENT_SPACE="${TS_SEGMENT_SPACE:-AUTO}"
TS_DATAFILE_PATH=""

# Execution flags
DRY_RUN=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility scripts if available
if [ -f "/usr/sandbox/app/system/utils/logging.sh" ]; then
    source /usr/sandbox/app/system/utils/logging.sh
else
    # Fallback simple logging functions
    log_info() { echo "[INFO] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*"; }
    log_success() { echo "[OK] $*"; }
fi

# ============================================
# Function: Display Usage
# ============================================
usage() {
    cat << EOF
Oracle Sandbox - Create Tablespace Script (Reusable Component)

Usage: $(basename "$0") PDB_NAME TABLESPACE_NAME SIZE [OPTIONS]

Positional Parameters:
  PDB_NAME              - Name of the Pluggable Database (e.g., SANDBOX_PDB)
  TABLESPACE_NAME       - Name of the tablespace to create (e.g., SANDBOX_TS)
  SIZE                  - Size of the tablespace (e.g., 1G, 500M, 100M)

Options (all configurable):
  --datafile-path PATH          Path to datafile (default: \$ORACLE_BASE/oradata/{PDB})
  --autoextend ON|OFF           Enable autoextend (default: $TS_AUTOEXTEND)
  --next-size SIZE              Next extent size (default: $TS_NEXT_SIZE)
  --maxsize SIZE|UNLIMITED      Max size (default: $TS_MAXSIZE)
  --logging ON|OFF              Enable logging (default: $TS_LOGGING)
  --extent-type LOCAL|DICTIONARY Extent management (default: $TS_EXTENT_TYPE)
  --segment-space MANUAL|AUTO   Segment space mgmt (default: $TS_SEGMENT_SPACE)
  --dry-run                     Preview SQL without execution
  -h, --help                    Show this help message

Environment Variables (override defaults):
  ORACLE_BASE                   Oracle installation root (default: /opt/oracle)
  ORACLE_SID                    Container Database SID (default: orcl)
  ORACLE_HOME                   Oracle home (auto-detected if not set)
  TS_AUTOEXTEND                 Override default autoextend
  TS_NEXT_SIZE                  Override default next size
  TS_MAXSIZE                    Override default maxsize
  TS_LOGGING                    Override default logging
  TS_EXTENT_TYPE                Override default extent type
  TS_SEGMENT_SPACE              Override default segment space

Examples:
  # Basic usage (all defaults)
  $(basename "$0") SANDBOX_PDB SANDBOX_TS 1G

  # Custom with no autoextend
  $(basename "$0") DEMASY_PDB DEMASY_TS 500M --autoextend OFF

  # Custom path and max size
  $(basename "$0") DEMASYLABS_PDB DEMASYLABS_TS 12G \\
    --datafile-path /custom/path --maxsize 20G

  # No logging with manual extent management
  $(basename "$0") SANDBOX_PDB TEST_TS 100M \\
    --logging OFF --extent-type LOCAL --segment-space MANUAL

  # Dry-run to preview SQL
  $(basename "$0") SANDBOX_PDB TEST_TS 100M --dry-run

  # Using environment variables
  export TS_AUTOEXTEND=OFF
  export TS_NEXT_SIZE=200M
  export TS_MAXSIZE=10G
  $(basename "$0") SANDBOX_PDB SANDBOX_TS 1G

EOF
    exit 1
}


# ============================================
# Function: Parse Command-Line Arguments
# ============================================
parse_arguments() {
    if [ $# -lt 3 ]; then
        usage
    fi
    
    PDB_NAME="$1"
    TABLESPACE_NAME="$2"
    TABLESPACE_SIZE="$3"
    
    # Parse optional arguments
    shift 3
    while [ $# -gt 0 ]; do
        case "$1" in
            --datafile-path)
                TS_DATAFILE_PATH="$2"
                shift 2
                ;;
            --autoextend)
                TS_AUTOEXTEND="$2"
                shift 2
                ;;
            --next-size)
                TS_NEXT_SIZE="$2"
                shift 2
                ;;
            --maxsize)
                TS_MAXSIZE="$2"
                shift 2
                ;;
            --logging)
                TS_LOGGING="$2"
                shift 2
                ;;
            --extent-type)
                TS_EXTENT_TYPE="$2"
                shift 2
                ;;
            --segment-space)
                TS_SEGMENT_SPACE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}


# ============================================
# Function: Validate Parameters
# ============================================
validate_parameters() {
    # Validate PDB name
    if [ -z "$PDB_NAME" ]; then
        log_error "PDB name is required"
        usage
    fi
    
    # Validate tablespace name
    if [ -z "$TABLESPACE_NAME" ]; then
        log_error "Tablespace name is required"
        usage
    fi
    
    # Validate size
    if [ -z "$TABLESPACE_SIZE" ]; then
        log_error "Tablespace size is required"
        usage
    fi
    
    # Check size format (should end with M, G, T)
    if ! [[ "$TABLESPACE_SIZE" =~ ^[0-9]+(M|G|T)$ ]]; then
        log_error "Invalid size format: $TABLESPACE_SIZE (use format like 1G, 500M, etc.)"
        exit 1
    fi
    
    # Validate option values
    case "${TS_AUTOEXTEND}" in ON|OFF) ;; *) log_error "Invalid autoextend: $TS_AUTOEXTEND"; exit 1;; esac
    case "${TS_LOGGING}" in ON|OFF) ;; *) log_error "Invalid logging: $TS_LOGGING"; exit 1;; esac
    case "${TS_EXTENT_TYPE}" in LOCAL|DICTIONARY) ;; *) log_error "Invalid extent type: $TS_EXTENT_TYPE"; exit 1;; esac
    case "${TS_SEGMENT_SPACE}" in AUTO|MANUAL) ;; *) log_error "Invalid segment space: $TS_SEGMENT_SPACE"; exit 1;; esac
    
    # Validate size format for NEXT and MAXSIZE
    if [ -n "$TS_NEXT_SIZE" ] && [ "$TS_NEXT_SIZE" != "UNLIMITED" ] && ! [[ "$TS_NEXT_SIZE" =~ ^[0-9]+(M|G|T)$ ]]; then
        log_error "Invalid next size format: $TS_NEXT_SIZE"
        exit 1
    fi
    
    if [ -n "$TS_MAXSIZE" ] && [ "$TS_MAXSIZE" != "UNLIMITED" ] && ! [[ "$TS_MAXSIZE" =~ ^[0-9]+(M|G|T)$ ]]; then
        log_error "Invalid maxsize format: $TS_MAXSIZE"
        exit 1
    fi
}
check_tablespace_exists() {
    local pdb_name="$1"
    local ts_name="$2"
    
    # Use sqlplus to check if tablespace exists
    sqlplus -S /nolog > /dev/null 2>&1 << EOF
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER=$pdb_name;

SELECT 1 FROM dba_tablespaces WHERE tablespace_name = '${ts_name}';

EXIT;
EOF
    
    return $?
}

# ============================================
# Function: Create Tablespace
# ============================================
create_tablespace() {
    # Set default datafile path if not provided
    local df_path="$TS_DATAFILE_PATH"
    if [ -z "$df_path" ]; then
        df_path="${ORACLE_BASE}/oradata/${PDB_NAME}"
    fi
    
    # Ensure datafile directory exists
    mkdir -p "$df_path" || {
        log_error "Failed to create datafile directory: $df_path"
        return 1
    }
    
    local datafile="${df_path}/${TABLESPACE_NAME}.dbf"
    
    log_info "Creating tablespace: $TABLESPACE_NAME in PDB: $PDB_NAME"
    log_info "Size: $TABLESPACE_SIZE"
    log_info "Datafile: $datafile"
    log_info "Autoextend: $TS_AUTOEXTEND | Next: $TS_NEXT_SIZE | Max: $TS_MAXSIZE"
    log_info "Logging: $TS_LOGGING | Extent Type: $TS_EXTENT_TYPE | Segment Space: $TS_SEGMENT_SPACE"
    echo ""
    
    # Build autoextend clause
    local autoextend_clause=""
    if [ "$TS_AUTOEXTEND" = "ON" ]; then
        autoextend_clause="AUTOEXTEND ON NEXT $TS_NEXT_SIZE MAXSIZE $TS_MAXSIZE"
    fi
    
    # Build logging clause
    local logging_clause="$TS_LOGGING"
    
    # Build extent management clause
    local extent_clause=""
    if [ "$TS_EXTENT_TYPE" = "LOCAL" ]; then
        extent_clause="EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT $TS_SEGMENT_SPACE"
    fi
    
    # Build CREATE TABLESPACE SQL
    local sql_cmd="CREATE TABLESPACE ${TABLESPACE_NAME}
  DATAFILE '${datafile}' SIZE ${TABLESPACE_SIZE}
  ${autoextend_clause}
  ${extent_clause}
  ${logging_clause};"
    
    log_info "Generated SQL:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$sql_cmd"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # If dry-run, exit here
    if [ "$DRY_RUN" = true ]; then
        log_success "DRY-RUN: SQL preview complete (no changes made)"
        return 0
    fi
    
    # Execute SQL
    sqlplus -S /nolog << EOF
SET HEADING OFF
SET FEEDBACK OFF
SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER=$PDB_NAME;

$sql_cmd

-- Verify creation
SELECT tablespace_name, status, extent_management, allocation_type
FROM dba_tablespaces
WHERE tablespace_name = '${TABLESPACE_NAME}';

EXIT;
EOF
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "Tablespace created successfully"
        return 0
    else
        log_error "Failed to create tablespace (exit code: $exit_code)"
        return 1
    fi
}

# ============================================
# Function: Verify Tablespace
# ============================================
verify_tablespace() {
    log_info "Verifying tablespace creation..."
    echo ""
    
    sqlplus -S /nolog << EOF
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER=$PDB_NAME;

-- Show tablespace details
COLUMN tablespace_name FORMAT A30
COLUMN status FORMAT A10
COLUMN extent_mgmt FORMAT A15
COLUMN size_mb FORMAT 9999999

SELECT 
  tablespace_name,
  status,
  extent_management extent_mgmt,
  ROUND(SUM(bytes)/1024/1024) size_mb
FROM dba_tablespaces t
LEFT JOIN dba_data_files d ON t.tablespace_name = d.tablespace_name
WHERE tablespace_name = '${TABLESPACE_NAME}'
GROUP BY tablespace_name, status, extent_management;

-- Show datafiles
COLUMN file_name FORMAT A60
COLUMN file_size FORMAT 9999999

SELECT 
  file_name,
  ROUND(bytes/1024/1024) file_size,
  autoextensible
FROM dba_data_files
WHERE tablespace_name = '${TABLESPACE_NAME}';

EXIT;
EOF
}

# ============================================
# Main Script
# ============================================

# Check if help requested
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

# Parse all arguments
parse_arguments "$@"

# Validate parameters
validate_parameters

# Set environment
export ORACLE_BASE
export ORACLE_SID
export ORACLE_HOME
export PATH="$ORACLE_HOME/bin:$PATH"

# Check if PDB exists by attempting connection
log_info "Verifying PDB: $PDB_NAME"

if ! sqlplus -S /nolog > /dev/null 2>&1 << EOF
CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER=$PDB_NAME;
EXIT;
EOF
then
    log_error "Failed to connect to PDB: $PDB_NAME"
    log_info "Verify the PDB exists and is open"
    exit 1
fi

log_success "PDB is accessible"
echo ""

# Check if tablespace already exists
log_info "Checking if tablespace already exists..."
if check_tablespace_exists > /dev/null 2>&1; then
    log_warn "Tablespace $TABLESPACE_NAME already exists in $PDB_NAME"
    log_info "Skipping creation (idempotent behavior)"
    echo ""
    verify_tablespace
    log_success "Tablespace is ready"
    exit 0
fi

log_info "Tablespace does not exist - creating..."
echo ""

# Create the tablespace
if create_tablespace; then
    echo ""
    verify_tablespace
    echo ""
    log_success "Tablespace creation complete!"
    exit 0
else
    log_error "Tablespace creation failed"
    exit 1
fi
