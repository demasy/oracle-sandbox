#!/bin/bash

# Set default TERM if not set (prevents tput errors)
export TERM=${TERM:-xterm}

# Get the actual script location (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source utilities from the actual script location
source "$SCRIPT_DIR/../utils/banner.sh"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/colors.sh"

# Print the banner
print_demasy_banner "Database Connection"

# Check if Oracle Instant Client is installed
if [ ! -d "/opt/oracle/instantclient" ] || [ -z "$(ls -A /opt/oracle/instantclient 2>/dev/null)" ]; then
  echo ""
  log_error "Oracle Instant Client not installed"
  echo -e "  • Please install Oracle Instant Client first: install-client"
  echo -e "  • Or install all Oracle components: install-all"
  echo ""
  exit 1
fi

# Check if SQLcl is installed
if [ ! -d "/opt/oracle/sqlcl" ] || [ ! -d "/opt/oracle/sqlcl/bin" ] || [ ! -f "/opt/oracle/sqlcl/bin/sql" ]; then
  echo ""
  log_error "SQLcl not installed"
  echo -e "  • Please install SQLcl: install-sqlcl"
  echo -e "  • Or install all Oracle components: install-all"
  echo ""
  exit 1
fi

echo -e "\e[1mConnection Information:\e[0m"
log_info "$(date '+%Y-%m-%d %H:%M:%S') - Preparing to connect to Oracle Database"
echo ""
echo -e " ${BOLD}${YELLOW}Host:${RESET}    $DEMASYLABS_DB_HOST"
echo -e " ${BOLD}${YELLOW}Port:${RESET}    $DEMASYLABS_DB_PORT"
echo -e " ${BOLD}${YELLOW}Service:${RESET} $DEMASYLABS_DB_SERVICE"
echo -e " ${BOLD}${YELLOW}User:${RESET}    $DEMASYLABS_DB_USER"
echo ""

# Check required environment variables
if [[ -z "$DEMASYLABS_DB_HOST" || -z "$DEMASYLABS_DB_PORT" || -z "$DEMASYLABS_DB_SERVICE" || -z "$DEMASYLABS_DB_USER" || -z "$DEMASYLABS_DB_PASS" ]]; then
  echo ""
  log_error "Missing required environment variables"
  echo ""
  log_info "Please ensure the following are set:"
  echo "  - DEMASYLABS_DB_HOST"
  echo "  - DEMASYLABS_DB_PORT"
  echo "  - DEMASYLABS_DB_SERVICE"
  echo "  - DEMASYLABS_DB_USER"
  echo "  - DEMASYLABS_DB_PASS"
  echo ""
  exit 1
fi

log_step "Connecting to database..."
echo ""

# Connect to Oracle
sql "$DEMASYLABS_DB_USER/$DEMASYLABS_DB_PASS@$DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT/$DEMASYLABS_DB_SERVICE" || {
  echo ""
  log_error "Connection Failed"
  echo ""
  log_info "Troubleshooting steps:"
  echo -e "  1. Check if database container is running: ${BOLD}${CYAN}docker ps${RESET}"
  echo -e "  2. Check database logs: ${BOLD}${CYAN}docker logs demasylabs-oracle-database${RESET}"
  echo -e "  3. Verify database is accessible: ${BOLD}${CYAN}docker exec demasylabs-oracle-server ping $DEMASYLABS_DB_HOST${RESET}"
  echo "  4. Verify credentials and service name"
  echo ""
  exit 2
}