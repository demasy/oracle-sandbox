#!/bin/bash
#==============================================================================
# reset-container.sh
# Full reset: remove containers + volumes, rebuild, and start fresh
#
# Usage:
#   ./reset-container.sh [options]
#
# Options:
#   --no-build    Skip docker-compose build (only remove + up)
#   --dry-run     Show what would be done without executing
#   -h, --help    Show this help message
#
# Examples:
#   ./reset-container.sh
#   ./reset-container.sh --no-build
#   ./reset-container.sh --dry-run
#
# Purpose:
#   Tears down all containers and volumes defined in docker-compose.yml,
#   performs a clean no-cache build, then brings everything back up.
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
    echo -e "${BLUE}${BOLD}   DEMASYLABS 🔄 Container Reset Tool${NC}"
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

SKIP_BUILD=false
DRY_RUN=false

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build)   SKIP_BUILD=true; shift ;;
    --dry-run)    DRY_RUN=true;    shift ;;
    -h|--help)
      sed -n '/^# Usage:/,/^#==/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Run with -h for usage."
      exit 1
      ;;
  esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────
run_cmd() {
  local description="$1"; shift
  if [[ "$DRY_RUN" == true ]]; then
    log_dry "$description: $*"
  else
    log_info "$description"
    "$@"
  fi
}

# ─── Pre-flight checks ────────────────────────────────────────────────────────
print_banner

if ! docker info > /dev/null 2>&1; then
  log_error "Docker is not running. Please start Docker and try again."
  exit 1
fi

if [[ ! -f "$WORKSPACE_ROOT/docker-compose.yml" ]]; then
  log_error "docker-compose.yml not found in: $WORKSPACE_ROOT"
  exit 1
fi

log_info "Workspace : $WORKSPACE_ROOT"
log_info "Skip build: $SKIP_BUILD"
log_info "Dry run   : $DRY_RUN"

# ─── Step 1: Stop and remove containers + volumes ────────────────────────────
log_step "Step 1/3 — Removing containers and volumes"

run_cmd "Stopping and removing containers + volumes" \
  docker-compose -f "$WORKSPACE_ROOT/docker-compose.yml" down --volumes --remove-orphans

log_success "Containers and volumes removed"

# ─── Step 2: Build images (no cache) ─────────────────────────────────────────
if [[ "$SKIP_BUILD" == false ]]; then
  log_step "Step 2/3 — Building images (no cache)"

  run_cmd "Building Docker images without cache" \
    docker-compose -f "$WORKSPACE_ROOT/docker-compose.yml" build --no-cache

  log_success "Images built successfully"
else
  log_step "Step 2/3 — Skipping build (--no-build)"
  log_warn "Using existing images"
fi

# ─── Step 3: Start containers ────────────────────────────────────────────────
log_step "Step 3/3 — Starting containers"

run_cmd "Starting all containers in detached mode" \
  docker-compose -f "$WORKSPACE_ROOT/docker-compose.yml" up -d

log_success "Containers started"

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}Reset complete.${NC}"
echo ""
if [[ "$DRY_RUN" == false ]]; then
  log_info "Running containers:"
  docker-compose -f "$WORKSPACE_ROOT/docker-compose.yml" ps
fi
echo ""
