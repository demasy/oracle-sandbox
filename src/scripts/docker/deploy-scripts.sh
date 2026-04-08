#!/bin/bash
#==============================================================================
# deploy-scripts.sh
# Deploy updated scripts to running Docker containers
#
# Usage:
#   ./deploy-scripts.sh [options]
#
# Options:
#   --container <name>    Target container (default: demasylabs-oracle-server)
#   --scripts <dir>       Host scripts directory to sync (default: all admin scripts)
#   --file <name>         Deploy a single script file only (e.g. create_user.sh)
#   --symlink             Create symlink for deployed scripts in /usr/local/bin
#   --dry-run             Show what would be done without executing
#   -h, --help            Show this help message
#
# Examples:
#   ./deploy-scripts.sh
#   ./deploy-scripts.sh --file create_user.sh
#   ./deploy-scripts.sh --file create_user.sh --symlink
#   ./deploy-scripts.sh --dry-run
#
# Purpose:
#   Hot-deploys script changes to a running container without requiring a full
#   Docker image rebuild. Mirrors the COPY + chmod + ln pattern in the Dockerfile.
#
# Author: Demasy <founder@demasy.io>
#==============================================================================

set -e

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Logging helpers ──────────────────────────────────────────────────────────
print_banner() {
    echo -e ""
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}   DEMASYLABS 🚀 Docker Script Deployer${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e ""
}

log_info()    { echo -e "  ${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "  ${GREEN}[✓]${NC}     $1"; }
log_error()   { echo -e "  ${RED}[✗]${NC}     $1"; }
log_warn()    { echo -e "  ${YELLOW}[WARN]${NC}  $1"; }
log_step()    { echo -e "\n  ${CYAN}${BOLD}──── $1 ────${NC}"; }
log_dry()     { echo -e "  ${YELLOW}[DRY-RUN]${NC} $1"; }

# ─── Defaults ─────────────────────────────────────────────────────────────────

# Resolve workspace root relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

CONTAINER_NAME="demasylabs-oracle-server"
HOST_ADMIN_DIR="$WORKSPACE_ROOT/src/scripts/oracle/admin"
HOST_APEX_DIR="$WORKSPACE_ROOT/src/scripts/oracle/apex"
HOST_MCP_DIR="$WORKSPACE_ROOT/src/scripts/oracle/mcp"
HOST_CLI_DIR="$WORKSPACE_ROOT/src/scripts/cli"
HOST_UTILS_DIR="$WORKSPACE_ROOT/src/scripts/backbone/utils"
HOST_BUILD_DIR="$WORKSPACE_ROOT/src/scripts/backbone/build"

CONTAINER_ADMIN_DIR="/usr/demasy/scripts/oracle/admin"
CONTAINER_APEX_DIR="/usr/demasy/scripts/oracle/apex"
CONTAINER_MCP_DIR="/usr/demasy/scripts/oracle/mcp"
CONTAINER_CLI_DIR="/usr/demasy/scripts/cli"
CONTAINER_UTILS_DIR="/usr/demasy/scripts/backbone/utils"
CONTAINER_BUILD_DIR="/usr/demasy/scripts/build"

TARGET_FILE=""
CREATE_SYMLINK=false
DRY_RUN=false
ERRORS=0
DEPLOYED=0

# ─── Symlink lookup (bash 3 compatible — no associative arrays) ───────────────
# Returns the /usr/local/bin symlink name for a given script filename, or empty.
get_symlink_name() {
    local filename="$1"
    case "$filename" in
        create_user.sh)             echo "create-user" ;;
        create-pdb.sh)              echo "create-pdb" ;;
        create-demasy-user.sh)      echo "create-demasy-user" ;;
        rollback-demasy-user.sh)    echo "rollback-demasy-user" ;;
        grant-privileges.sh)        echo "grant-privileges" ;;
        create-db-link.sh)          echo "create-db-link" ;;
        healthcheck.sh)             echo "healthcheck" ;;
        download-apex.sh)           echo "download-apex" ;;
        install-all.sh)             echo "install-all" ;;
        install-client.sh)          echo "install-client" ;;
        install-sqlcl.sh)           echo "install-sqlcl" ;;
        install-sqlplus.sh)         echo "install-sqlplus" ;;
        download.sh)                echo "download-oracle-components" ;;
        start-mcp-with-saved-connection.sh) echo "start-mcp" ;;
        *)                          echo "" ;;
    esac
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
show_help() {
    grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \?//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --container)  CONTAINER_NAME="$2"; shift 2 ;;
        --file)       TARGET_FILE="$2";    shift 2 ;;
        --symlink)    CREATE_SYMLINK=true;  shift   ;;
        --dry-run)    DRY_RUN=true;         shift   ;;
        -h|--help)    show_help ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

# ─── Functions ────────────────────────────────────────────────────────────────

check_docker() {
    log_step "Checking Docker"
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running"
        exit 1
    fi
    log_success "Docker is running"
}

check_container() {
    log_step "Checking Container"
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "Container '${CONTAINER_NAME}' is not running"
        echo ""
        echo "  Running containers:"
        docker ps --format '  - {{.Names}} ({{.Status}})' 2>/dev/null || true
        echo ""
        echo "  Start containers with:  docker-compose up -d"
        exit 1
    fi
    log_success "Container '${CONTAINER_NAME}' is running"
}

# Copy a single file to the container and set permissions
deploy_file() {
    local host_file="$1"
    local container_dir="$2"
    local filename
    filename=$(basename "$host_file")

    if [[ ! -f "$host_file" ]]; then
        log_warn "File not found, skipping: $host_file"
        ((ERRORS++)) || true
        return
    fi

    local container_path="${container_dir}/${filename}"

    if $DRY_RUN; then
        log_dry "docker cp $host_file ${CONTAINER_NAME}:${container_path}"
        log_dry "docker exec ${CONTAINER_NAME} chmod +x ${container_path}"
    else
        if docker cp "$host_file" "${CONTAINER_NAME}:${container_path}" 2>&1; then
            docker exec "$CONTAINER_NAME" chmod +x "$container_path"
            log_success "Deployed: ${filename} → ${container_path}"
            ((DEPLOYED++)) || true
        else
            log_error "Failed to deploy: ${filename}"
            ((ERRORS++)) || true
        fi
    fi

    # Create symlink if requested and mapping exists
    if $CREATE_SYMLINK; then
        local link_name
        link_name=$(get_symlink_name "$filename")
        if [[ -n "$link_name" ]]; then
            local link_path="/usr/local/bin/${link_name}"
            if $DRY_RUN; then
                log_dry "docker exec ${CONTAINER_NAME} ln -sf ${container_path} ${link_path}"
                log_dry "docker exec ${CONTAINER_NAME} ln -sf ${container_path} ${link_path}.sh"
            else
                docker exec "$CONTAINER_NAME" bash -c \
                    "ln -sf '${container_path}' '${link_path}'" \
                    && log_success "Symlink:  ${link_name} → ${container_path}" \
                    || log_warn "Symlink failed: ${link_path}"
                # Also create a .sh-suffixed alias so both forms work
                docker exec "$CONTAINER_NAME" bash -c \
                    "ln -sf '${container_path}' '${link_path}.sh'" \
                    && log_success "Symlink:  ${link_name}.sh → ${container_path}" \
                    || log_warn "Symlink (.sh alias) failed: ${link_path}.sh"
            fi
        fi
    fi
}

# Deploy all scripts from a host directory to a container directory
deploy_directory() {
    local host_dir="$1"
    local container_dir="$2"
    local label="$3"

    if [[ ! -d "$host_dir" ]]; then
        log_warn "Directory not found, skipping: $host_dir"
        return
    fi

    local files=("$host_dir"/*.sh)
    if [[ ! -e "${files[0]}" ]]; then
        log_warn "No .sh files found in: $host_dir"
        return
    fi

    log_info "Syncing ${label} → ${container_dir}"
    for f in "${files[@]}"; do
        deploy_file "$f" "$container_dir"
    done
}

print_summary() {
    echo ""
    echo -e "  ${BLUE}${BOLD}─────────────────────────────────────────${NC}"
    if $DRY_RUN; then
        echo -e "  ${YELLOW}${BOLD}  DRY RUN — no changes were made${NC}"
    else
        echo -e "  ${GREEN}${BOLD}  Deployed : ${DEPLOYED} file(s)${NC}"
        if [[ $ERRORS -gt 0 ]]; then
            echo -e "  ${RED}${BOLD}  Errors   : ${ERRORS}${NC}"
        fi
    fi
    echo -e "  ${BLUE}${BOLD}─────────────────────────────────────────${NC}"
    echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────

print_banner

log_info "Container  : ${CONTAINER_NAME}"
log_info "Workspace  : ${WORKSPACE_ROOT}"
$DRY_RUN && log_warn "DRY-RUN mode — no changes will be applied"

check_docker
check_container

if [[ -n "$TARGET_FILE" ]]; then
    # ── Single-file mode ──────────────────────────────────────────────────────
    log_step "Deploying: ${TARGET_FILE}"

    # Search for the file in known directories
    FOUND=false
    for pair in \
        "${HOST_ADMIN_DIR}:${CONTAINER_ADMIN_DIR}" \
        "${HOST_APEX_DIR}:${CONTAINER_APEX_DIR}" \
        "${HOST_MCP_DIR}:${CONTAINER_MCP_DIR}" \
        "${HOST_CLI_DIR}:${CONTAINER_CLI_DIR}" \
        "${HOST_UTILS_DIR}:${CONTAINER_UTILS_DIR}" \
        "${HOST_BUILD_DIR}:${CONTAINER_BUILD_DIR}"
    do
        host_dir="${pair%%:*}"
        container_dir="${pair##*:}"
        candidate="${host_dir}/${TARGET_FILE}"
        if [[ -f "$candidate" ]]; then
            deploy_file "$candidate" "$container_dir"
            FOUND=true
            break
        fi
    done

    if ! $FOUND; then
        log_error "File '${TARGET_FILE}' not found in any known script directory"
        log_info  "Searched:"
        log_info  "  ${HOST_ADMIN_DIR}"
        log_info  "  ${HOST_APEX_DIR}"
        log_info  "  ${HOST_CLI_DIR}"
        log_info  "  ${HOST_UTILS_DIR}"
        log_info  "  ${HOST_BUILD_DIR}"
        exit 1
    fi

else
    # ── Full sync mode ────────────────────────────────────────────────────────
    log_step "Deploying All Scripts"

    deploy_directory "$HOST_UTILS_DIR"  "$CONTAINER_UTILS_DIR"  "backbone/utils"
    deploy_directory "$HOST_BUILD_DIR"  "$CONTAINER_BUILD_DIR"  "backbone/build"
    deploy_directory "$HOST_CLI_DIR"    "$CONTAINER_CLI_DIR"    "cli"
    deploy_directory "$HOST_ADMIN_DIR"  "$CONTAINER_ADMIN_DIR"  "oracle/admin"
    deploy_directory "$HOST_MCP_DIR"    "$CONTAINER_MCP_DIR"    "oracle/mcp"
    deploy_directory "$HOST_APEX_DIR"   "$CONTAINER_APEX_DIR"   "oracle/apex"
fi

print_summary

[[ $ERRORS -eq 0 ]] && exit 0 || exit 1
