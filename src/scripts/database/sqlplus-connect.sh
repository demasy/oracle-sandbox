#!/bin/bash

#########################################################################
#                                                                       #
#            Oracle Database SQL*Plus Connection Script                #
#                    Demasy Labs Database V1.0                         #
#                   Developed by Demasy Labs                           #
#                                                                       #
#                   Updated by demasy on November 11, 2025             #
#           Enhanced SQL*Plus connection with ARM64 support            #
#                                                                       #
#########################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print banner
print_banner() {
    clear
    echo ""
    echo -e "${CYAN}  |----------------------------------------------------------|${NC}"
    echo -e "${CYAN}  |          ${RED}     Demasy Labs - SQL*Plus V1.0  ${NC}              ${CYAN}|${NC}"
    echo -e "${CYAN}  |             ${YELLOW}Developed by Demasy Labs${NC}              ${CYAN}|${NC}"
    echo -e "${CYAN}  |                email: founder@demasy.io                  ${CYAN}|${NC}"
    echo -e "${CYAN}  |                website: www.demasy.io                    ${CYAN}|${NC}"
    echo -e "${CYAN}  |             github: www.github.com/demasy                ${CYAN}|${NC}"
    echo -e "${CYAN}  |        Ahmed El-Demasy - Founder of Demasy Labs          ${CYAN}|${NC}"
    echo -e "${CYAN}  |----------------------------------------------------------|${NC}"
    echo ""
}

# Check architecture and SQL*Plus availability
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    CLIENT_TYPE="${GREEN}SQL*Plus (Native)${NC}"
    if command -v sqlplus &> /dev/null; then
        SQLPLUS_AVAILABLE=true
    else
        SQLPLUS_AVAILABLE=false
    fi
else
    CLIENT_TYPE="${YELLOW}SQLcl (SQL*Plus Fallback - ARM64)${NC}"
    SQLPLUS_AVAILABLE=true  # Available through fallback
fi

# Function to display connection info
display_connection_info() {
    echo -e "${BLUE}      Welcome! ${YELLOW}$USER${NC} ${BLUE}- $(date)${NC}"
    echo ""
    echo -e "${GREEN}       - Architecture: ${CYAN}$ARCH${NC}"
    echo -e "${GREEN}       - Client Type: $CLIENT_TYPE"
    echo -e "${GREEN}       - Host: ${CYAN}$DEMASYLABS_DB_HOST${NC}"
    echo -e "${GREEN}       - Port: ${CYAN}$DEMASYLABS_DB_PORT${NC}"
    echo -e "${GREEN}       - Service: ${CYAN}$DEMASYLABS_DB_SERVICE${NC}"
    echo -e "${GREEN}       - User: ${CYAN}$DEMASYLABS_DB_USER${NC}"
    echo ""
}

# Print banner and connection info
print_banner
display_connection_info

# Check required environment variables
if [[ -z "$DEMASYLABS_DB_HOST" || -z "$DEMASYLABS_DB_PORT" || -z "$DEMASYLABS_DB_SERVICE" || -z "$DEMASYLABS_DB_USER" || -z "$DEMASYLABS_DB_PASS" ]]; then
  echo -e "${RED}Error: One or more required environment variables are not set.${NC}"
  echo -e "${YELLOW}Required variables: DEMASYLABS_DB_HOST, DEMASYLABS_DB_PORT, DEMASYLABS_DB_SERVICE, DEMASYLABS_DB_USER, DEMASYLABS_DB_PASS${NC}"
  exit 1
fi

# Check if SQL*Plus (or fallback) is available
if [[ "$SQLPLUS_AVAILABLE" != true ]]; then
    echo -e "${RED}Error: SQL*Plus is not available on this system.${NC}"
    echo -e "${YELLOW}Please ensure Oracle Client is properly installed.${NC}"
    exit 1
fi

# Connect to Oracle using SQL*Plus or SQLcl fallback
echo -e "${BLUE}Connecting to Oracle Database using SQL*Plus...${NC}"
echo ""

if [[ "$ARCH" = "x86_64" ]] && [[ -f "/opt/oracle/instantclient/sqlplus" ]]; then
    # Use native SQL*Plus on x86_64
    /opt/oracle/instantclient/sqlplus "$DEMASYLABS_DB_USER/$DEMASYLABS_DB_PASS@$DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT/$DEMASYLABS_DB_SERVICE" || {
        echo ""
        echo -e "${RED}Failed to connect to Oracle Database using SQL*Plus.${NC}"
        exit 2
    }
else
    # Use SQLcl as fallback on ARM64 or when SQL*Plus is not available
    echo -e "${YELLOW}Using SQLcl as fallback...${NC}"
    sql "$DEMASYLABS_DB_USER/$DEMASYLABS_DB_PASS@$DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT/$DEMASYLABS_DB_SERVICE" || {
        echo ""
        echo -e "${RED}Failed to connect to Oracle Database using SQLcl fallback.${NC}"
        exit 2
    }
fi