#!/bin/bash

# Set default TERM if not set (prevents tput errors)
export TERM=${TERM:-xterm}

# Colors for output
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[1;36m'      # Bright Cyan for labels
WHITE='\033[1;97m'     # Bright White for values
NC='\033[0m' # No Color

# Function to print banner
print_banner() {
    clear
    echo ""
    echo -e "\e[0;33m ____  _____ __  __    _    ______   __\e[0m"
    echo -e "\e[0;33m|  _ \| ____|  \/  |  / \  / ___\ \ / /\e[0m"
    echo -e "\e[0;33m| | | |  _| | |\/| | / _ \ \___ \\\\ V /\e[0m" 
    echo -e "\e[0;33m| |_| | |___| |  | |/ ___ \ ___) || |\e[0m"
    echo -e "\e[0;33m|____/|_____|_|  |_/_/   \_\____/ |_|\e[0m"
    echo ""
    echo -e "                             \e[0;33m\e[5mL A B S\e[0m"
    echo ""
    echo -e "\e[0;33mDeveloped by: \e[1m\e[0;33mDemasy Labs\e[0m\e[0;33m 🚀\e[0m"
    echo -e "\e[0;33m-----------------------------------------------------\e[0m"    
    echo -e "\e[0;33m        Code with love ❤️  in Egypt \e[0m"
    echo ""
    echo ""
    echo -e "\e[1m************* Database Connection ************* \e[0m"
    echo ""
}

# Print the banner
print_banner

echo -e "\e[1mConnection Information:\e[0m"
echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} Preparing to connect to Oracle Database"
echo ""
echo -e " \033[1;33mHost:\033[0m    \033[0;30m$DEMASYLABS_DB_HOST${NC}"
echo -e " \033[1;33mPort:\033[0m    \033[0;30m$DEMASYLABS_DB_PORT${NC}"
echo -e " \033[1;33mService:\033[0m \033[0;30m$DEMASYLABS_DB_SERVICE${NC}"
echo -e " \033[1;33mUser:\033[0m    \033[0;30m$DEMASYLABS_DB_USER${NC}"
echo ""

# Check required environment variables
if [[ -z "$DEMASYLABS_DB_HOST" || -z "$DEMASYLABS_DB_PORT" || -z "$DEMASYLABS_DB_SERVICE" || -z "$DEMASYLABS_DB_USER" || -z "$DEMASYLABS_DB_PASS" ]]; then
  echo -e "${RED}✗ Error: Missing required environment variables${NC}"
  echo ""
  echo "Please ensure the following are set:"
  echo "  - DEMASYLABS_DB_HOST"
  echo "  - DEMASYLABS_DB_PORT"
  echo "  - DEMASYLABS_DB_SERVICE"
  echo "  - DEMASYLABS_DB_USER"
  echo "  - DEMASYLABS_DB_PASS"
  echo ""
  exit 1
fi

echo -e "${YELLOW}⏳ Connecting to database...${NC}"
echo ""

# Connect to Oracle
sql "$DEMASYLABS_DB_USER/$DEMASYLABS_DB_PASS@$DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT/$DEMASYLABS_DB_SERVICE" || {
  echo ""
  echo -e "${RED}✗ Connection Failed${NC}"
  echo ""
  echo "Troubleshooting steps:"
  echo "  1. Check if database container is running: docker ps"
  echo "  2. Check database logs: docker logs demasy-oracle"
  echo "  3. Verify database is accessible: docker exec demasy-server ping $DEMASYLABS_DB_HOST"
  echo "  4. Verify credentials and service name"
  echo ""
  exit 2
}