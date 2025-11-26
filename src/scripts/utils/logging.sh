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

# Log success message
log_success() {
    echo -e "${GREEN}✓ $(get_timestamp)${NC} $1"
}

# Log error message
log_error() {
    echo -e "${RED}✗ $(get_timestamp)${NC} $1" >&2
}

# Log warning message
log_warning() {
    echo -e "${YELLOW}⚠ $(get_timestamp)${NC} $1"
}

# Log info message
log_info() {
    echo -e "${BLUE}ℹ $(get_timestamp)${NC} $1"
}

# Log progress message
log_progress() {
    echo -e "${CYAN}⏳ $(get_timestamp)${NC} $1"
}

# Print section header
log_section() {
    echo ""
    echo -e "${PURPLE}=== $1 ===${NC}"
    echo ""
}

# Usage in scripts:
# source "$(dirname "$0")/../utils/logging.sh"
# log_success "Operation completed"
# log_error "Something went wrong"
# log_warning "Check configuration"
# log_info "Processing data"
# log_progress "Connecting to database..."
# log_section "Database Connection"
