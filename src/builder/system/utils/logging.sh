#!/bin/bash

#########################################################################
#                                                                       #
#                    Shared Logging Functions                          #
#                       Demasy Labs Utils                              #
#                                                                       #
#########################################################################

# Source colors if not already loaded
if [ -z "$RED" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/colors.sh"
fi

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Quiet mode: suppress info/step/section (set SANDBOX_QUIET=1)
# Verbose mode: no effect on logging itself; action scripts check SANDBOX_VERBOSE

log_success() {
    echo -e "${GREEN}✓ $(get_timestamp)${NC} $1" >&2
}

log_error() {
    echo -e "${RED}✗ $(get_timestamp)${NC} $1" >&2
}

log_warning() {
    [[ "${SANDBOX_QUIET:-0}" == "1" ]] && return
    echo -e "${YELLOW}⚠ $(get_timestamp)${NC} $1" >&2
}

log_warn() {
    log_warning "$1"
}

log_info() {
    [[ "${SANDBOX_QUIET:-0}" == "1" ]] && return
    echo -e "${BLUE}ℹ $(get_timestamp)${NC} $1" >&2
}

log_progress() {
    [[ "${SANDBOX_QUIET:-0}" == "1" ]] && return
    echo -e "${CYAN}⏳ $(get_timestamp)${NC} $1" >&2
}

log_step() {
    log_progress "$1"
}

log_section() {
    [[ "${SANDBOX_QUIET:-0}" == "1" ]] && return
    echo "" >&2
    echo -e "${PURPLE}=== $1 ===${NC}" >&2
    echo "" >&2
}

# Elapsed time helper — usage: elapsed_since <start_epoch_seconds>
elapsed_since() {
    local start="$1"
    local now elapsed mins secs
    now=$(date +%s)
    elapsed=$(( now - start ))
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))
    if (( mins > 0 )); then
        printf "%dm %02ds" "$mins" "$secs"
    else
        printf "%ds" "$secs"
    fi
}

# Usage in scripts:
# source "$(dirname "$0")/../utils/logging.sh"
# log_success "Operation completed"
# log_error "Something went wrong"
# log_warning "Check configuration"
# log_info "Processing data"
# log_progress "Connecting to database..."
# log_section "Database Connection"
