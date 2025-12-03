#!/bin/bash

# Set default TERM if not set (prevents tput errors)
export TERM=${TERM:-xterm}

# Source utilities using absolute paths
source /usr/demasy/scripts/backbone/utils/banner.sh
source /usr/demasy/scripts/backbone/utils/logging.sh
source /usr/demasy/scripts/backbone/utils/colors.sh

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

echo "Connection Information:"
echo ""
echo "Host:    $DEMASYLABS_DB_HOST"
echo "Port:    $DEMASYLABS_DB_PORT"
echo "Service: $DEMASYLABS_DB_SERVICE"
echo "User:    $DEMASYLABS_DB_USER"
echo ""

# Check required environment variables
if [[ -z "$DEMASYLABS_DB_HOST" || -z "$DEMASYLABS_DB_PORT" || -z "$DEMASYLABS_DB_SERVICE" || -z "$DEMASYLABS_DB_USER" || -z "$DEMASYLABS_DB_PASS" ]]; then
  echo ""
  log_error "Missing required environment variables"
  echo ""
  log_info "Missing variables (check which ones are empty):"
  [[ -z "$DEMASYLABS_DB_HOST" ]] && echo "  ✗ DEMASYLABS_DB_HOST" || echo "  ✓ DEMASYLABS_DB_HOST = $DEMASYLABS_DB_HOST"
  [[ -z "$DEMASYLABS_DB_PORT" ]] && echo "  ✗ DEMASYLABS_DB_PORT" || echo "  ✓ DEMASYLABS_DB_PORT = $DEMASYLABS_DB_PORT"
  [[ -z "$DEMASYLABS_DB_SERVICE" ]] && echo "  ✗ DEMASYLABS_DB_SERVICE" || echo "  ✓ DEMASYLABS_DB_SERVICE = $DEMASYLABS_DB_SERVICE"
  [[ -z "$DEMASYLABS_DB_USER" ]] && echo "  ✗ DEMASYLABS_DB_USER" || echo "  ✓ DEMASYLABS_DB_USER = $DEMASYLABS_DB_USER"
  [[ -z "$DEMASYLABS_DB_PASS" ]] && echo "  ✗ DEMASYLABS_DB_PASS" || echo "  ✓ DEMASYLABS_DB_PASS = ********"
  echo ""
  log_info "If running standalone container, pass environment variables:"
  echo -e "  ${CYAN}docker run -e DEMASYLABS_DB_PASS=YourPassword ... demasy/oracle-sandbox:base${RESET}"
  echo ""
  log_info "Or use docker-compose which sets all variables automatically"
  echo ""
  exit 1
fi

echo "Connecting to database..."
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