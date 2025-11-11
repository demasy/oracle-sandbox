#!/bin/bash

#########################################################################
#                                                                       #
#            Oracle Database SQLPlus Connection Script                  #
#                    Demasy Labs Database V1.0                         #
#                   Developed by Demasy Labs                           #
#                                                                       #
#                   Updated by demasy on November 11, 2025             #
#           Enhanced with dual SQL*Plus and SQLcl support              #
#                                                                       #
#########################################################################

clear

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}  |--------------------------------------------------------|${NC}"
echo -e "${BLUE}  |          ${RED}     Demasy Labs Database V1.0  ${NC}${BLUE}              |${NC}"
echo -e "${BLUE}  |             ${YELLOW} SQLPlus Connection Script${NC}${BLUE}                  |${NC}"
echo -e "${BLUE}  |                email: founder@demasy.io                |${NC}"
echo -e "${BLUE}  |                website: www.demasy.io                  |${NC}"
echo -e "${BLUE}  |             github: www.github.com/demasy              |${NC}"
echo -e "${BLUE}  |        Ahmed El-Demasy - Founder of Demasy Labs        |${NC}"
echo -e "${BLUE}  |--------------------------------------------------------|${NC}"
echo ""

# Check if running inside a container
if [ -f /.dockerenv ]; then
    echo -e "${GREEN}      Running inside Docker container${NC}"
    CONTAINER_NAME=$(hostname)
    echo -e "${CYAN}      Container: $CONTAINER_NAME${NC}"
else
    echo -e "${YELLOW}      Running on host system${NC}"
fi

echo -e "${CYAN}      Welcome! $USER - $(date)${NC}"
echo ""

# Function to load environment variables
load_env_vars() {
    if [ -f "/usr/demasy/app/.env" ]; then
        source /usr/demasy/app/.env
    elif [ -f ".env" ]; then
        source .env
    fi
}

# Function to check if SQLPlus is available
check_sqlplus() {
    if command -v sqlplus &> /dev/null; then
        echo -e "${GREEN}✓ SQL*Plus is available${NC}"
        SQLPLUS_AVAILABLE=true
        return 0
    else
        echo -e "${YELLOW}! SQL*Plus not found - checking alternatives${NC}"
        SQLPLUS_AVAILABLE=false
        return 1
    fi
}

# Function to check if SQLcl is available
check_sqlcl() {
    if command -v sql &> /dev/null; then
        echo -e "${GREEN}✓ SQLcl is available${NC}"
        SQLCL_AVAILABLE=true
        return 0
    else
        echo -e "${RED}✗ SQLcl not found${NC}"
        SQLCL_AVAILABLE=false
        return 1
    fi
}

# Function to display connection options
show_menu() {
    echo -e "${PURPLE}Available Connection Options:${NC}"
    echo ""
    echo -e "${YELLOW}  1)${NC} Connect as SYS (SYSDBA) - ${CLIENT_TYPE}"
    echo -e "${YELLOW}  2)${NC} Connect as SYSTEM - ${CLIENT_TYPE}"
    echo -e "${YELLOW}  3)${NC} Connect as Custom User - ${CLIENT_TYPE}"
    echo -e "${YELLOW}  4)${NC} Connect to Remote Database - ${CLIENT_TYPE}"
    echo -e "${YELLOW}  5)${NC} Connect using Environment Variables - ${CLIENT_TYPE}"
    echo -e "${YELLOW}  6)${NC} Local Connection (/ as sysdba) - ${CLIENT_TYPE}"
    echo -e "${YELLOW}  7)${NC} Show Connection Information"
    if [[ "$SQLPLUS_AVAILABLE" == true && "$SQLCL_AVAILABLE" == true ]]; then
        echo -e "${YELLOW}  8)${NC} Switch Client Type (Current: ${CLIENT_TYPE})"
    fi
    echo -e "${YELLOW}  q)${NC} Quit"
    echo ""
}

# Function to determine which client to use
select_client() {
    if [[ "$SQLPLUS_AVAILABLE" == true && "$SQLCL_AVAILABLE" == true ]]; then
        echo -e "${CYAN}Both SQL*Plus and SQLcl are available${NC}"
        echo -e "${YELLOW}Choose default client:${NC}"
        echo -e "  1) SQL*Plus (Traditional Oracle client)"
        echo -e "  2) SQLcl (Modern Java-based client)"
        read -p "Select client [1-2]: " client_choice
        case $client_choice in
            1)
                CLIENT_TYPE="SQL*Plus"
                SQL_COMMAND="sqlplus"
                ;;
            2)
                CLIENT_TYPE="SQLcl"
                SQL_COMMAND="sql"
                ;;
            *)
                CLIENT_TYPE="SQL*Plus"
                SQL_COMMAND="sqlplus"
                ;;
        esac
    elif [[ "$SQLPLUS_AVAILABLE" == true ]]; then
        CLIENT_TYPE="SQL*Plus"
        SQL_COMMAND="sqlplus"
    elif [[ "$SQLCL_AVAILABLE" == true ]]; then
        CLIENT_TYPE="SQLcl"
        SQL_COMMAND="sql"
    else
        echo -e "${RED}Neither SQL*Plus nor SQLcl is available!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Using: $CLIENT_TYPE${NC}"
}

# Function to switch client type
switch_client() {
    if [[ "$CLIENT_TYPE" == "SQL*Plus" ]]; then
        CLIENT_TYPE="SQLcl"
        SQL_COMMAND="sql"
    else
        CLIENT_TYPE="SQL*Plus"
        SQL_COMMAND="sqlplus"
    fi
    echo -e "${GREEN}Switched to: $CLIENT_TYPE${NC}"
}

# Function to connect as SYS
connect_as_sys() {
    echo -e "${CYAN}Connecting as SYS using $CLIENT_TYPE...${NC}"
    read -s -p "Enter SYS password: " SYS_PASSWORD
    echo ""
    
    if [ -f /.dockerenv ]; then
        # Inside container - connect locally
        $SQL_COMMAND sys/${SYS_PASSWORD}@FREE as sysdba
    else
        # Outside container - connect remotely
        $SQL_COMMAND sys/${SYS_PASSWORD}@192.168.1.110:1521/FREE as sysdba
    fi
}

# Function to connect as SYSTEM
connect_as_system() {
    echo -e "${CYAN}Connecting as SYSTEM...${NC}"
    read -s -p "Enter SYSTEM password: " SYSTEM_PASSWORD
    echo ""
    
    if [ -f /.dockerenv ]; then
        # Inside container - connect locally
        sqlplus system/${SYSTEM_PASSWORD}@FREE
    else
        # Outside container - connect remotely
        sqlplus system/${SYSTEM_PASSWORD}@192.168.1.110:1521/FREE
    fi
}

# Function to connect as custom user
connect_custom_user() {
    echo -e "${CYAN}Custom User Connection${NC}"
    read -p "Enter username: " USERNAME
    read -s -p "Enter password: " USER_PASSWORD
    echo ""
    read -p "Enter service name (default: FREE): " SERVICE
    SERVICE=${SERVICE:-FREE}
    
    if [ -f /.dockerenv ]; then
        # Inside container - connect locally
        sqlplus ${USERNAME}/${USER_PASSWORD}@${SERVICE}
    else
        # Outside container - connect remotely
        sqlplus ${USERNAME}/${USER_PASSWORD}@192.168.1.110:1521/${SERVICE}
    fi
}

# Function to connect to remote database
connect_remote() {
    echo -e "${CYAN}Remote Database Connection${NC}"
    read -p "Enter hostname/IP (default: 192.168.1.110): " HOSTNAME
    HOSTNAME=${HOSTNAME:-192.168.1.110}
    read -p "Enter port (default: 1521): " PORT
    PORT=${PORT:-1521}
    read -p "Enter service name (default: FREE): " SERVICE
    SERVICE=${SERVICE:-FREE}
    read -p "Enter username: " USERNAME
    read -s -p "Enter password: " PASSWORD
    echo ""
    
    sqlplus ${USERNAME}/${PASSWORD}@${HOSTNAME}:${PORT}/${SERVICE}
}

# Function to connect using environment variables
connect_env_vars() {
    echo -e "${CYAN}Connecting using environment variables...${NC}"
    
    load_env_vars
    
    # Check if environment variables are set
    if [[ -z "$ENV_DB_USER" || -z "$ENV_DB_PASSWORD" || -z "$ENV_IP_DB_SERVER" ]]; then
        echo -e "${RED}Error: Environment variables not properly set${NC}"
        echo -e "${YELLOW}Required variables: ENV_DB_USER, ENV_DB_PASSWORD, ENV_IP_DB_SERVER${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Using environment configuration:${NC}"
    echo -e "${CYAN}  Host: $ENV_IP_DB_SERVER${NC}"
    echo -e "${CYAN}  User: $ENV_DB_USER${NC}"
    echo -e "${CYAN}  Service: ${ENV_DB_SERVICE:-FREE}${NC}"
    echo ""
    
    if [ -f /.dockerenv ]; then
        # Inside container - connect locally
        sqlplus ${ENV_DB_USER}/${ENV_DB_PASSWORD}@${ENV_DB_SERVICE:-FREE}
    else
        # Outside container - connect remotely
        sqlplus ${ENV_DB_USER}/${ENV_DB_PASSWORD}@${ENV_IP_DB_SERVER}:1521/${ENV_DB_SERVICE:-FREE}
    fi
}

# Function for local connection
connect_local() {
    echo -e "${CYAN}Connecting locally as sysdba...${NC}"
    if [ -f /.dockerenv ]; then
        sqlplus / as sysdba
    else
        echo -e "${RED}Error: Local connection only works inside the Oracle container${NC}"
        echo -e "${YELLOW}Use option 4 for remote connection instead${NC}"
        return 1
    fi
}

# Function to show connection information
show_connection_info() {
    echo -e "${PURPLE}Current Connection Information:${NC}"
    echo ""
    
    load_env_vars
    
    echo -e "${CYAN}Environment Variables:${NC}"
    echo -e "  DB Host: ${ENV_IP_DB_SERVER:-'Not set'}"
    echo -e "  DB Port: ${ENV_DB_PORT_LISTENER:-'Not set'}"
    echo -e "  DB Service: ${ENV_DB_SERVICE:-'Not set'}"
    echo -e "  DB User: ${ENV_DB_USER:-'Not set'}"
    echo ""
    
    echo -e "${CYAN}Container Information:${NC}"
    if [ -f /.dockerenv ]; then
        echo -e "  Location: Inside Docker container"
        echo -e "  Container: $(hostname)"
        echo -e "  Local Service: FREE"
    else
        echo -e "  Location: Host system"
        echo -e "  Remote Connection Required: Yes"
    fi
    echo ""
    
    if check_sqlplus; then
        sqlplus -version 2>/dev/null || echo -e "${YELLOW}  SQLPlus version not available${NC}"
    fi
    echo ""
}

# Main script execution
main() {
    # Load environment variables
    load_env_vars
    
    # Check available clients
    check_sqlplus
    check_sqlcl
    
    # Select which client to use
    select_client
    
    # Check if any SQL client is available
    if [[ "$SQLPLUS_AVAILABLE" != true && "$SQLCL_AVAILABLE" != true ]]; then
        echo -e "${RED}Neither SQL*Plus nor SQLcl is available. Please install Oracle Client or run from Oracle container.${NC}"
        exit 1
    fi
    
    # If arguments provided, execute directly
    if [ $# -gt 0 ]; then
        case $1 in
            "sys"|"SYS")
                connect_as_sys
                ;;
            "system"|"SYSTEM")
                connect_as_system
                ;;
            "env"|"ENV")
                connect_env_vars
                ;;
            "local"|"LOCAL")
                connect_local
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo -e "${YELLOW}Available options: sys, system, env, local${NC}"
                exit 1
                ;;
        esac
        return
    fi
    
    # Interactive menu
    while true; do
        show_menu
        if [[ "$SQLPLUS_AVAILABLE" == true && "$SQLCL_AVAILABLE" == true ]]; then
            read -p "Select an option [1-8,q]: " choice
        else
            read -p "Select an option [1-7,q]: " choice
        fi
        echo ""
        
        case $choice in
            1)
                connect_as_sys
                ;;
            2)
                connect_as_system
                ;;
            3)
                connect_custom_user
                ;;
            4)
                connect_remote
                ;;
            5)
                connect_env_vars
                ;;
            6)
                connect_local
                ;;
            7)
                show_connection_info
                ;;
            8)
                if [[ "$SQLPLUS_AVAILABLE" == true && "$SQLCL_AVAILABLE" == true ]]; then
                    switch_client
                else
                    echo -e "${RED}Invalid option. Please try again.${NC}"
                fi
                ;;
            q|Q)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                echo ""
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
        echo -e "${BLUE}  |--------------------------------------------------------|${NC}"
        echo -e "${BLUE}  |             ${YELLOW} SQLPlus Connection Script${NC}${BLUE}                  |${NC}"
        echo -e "${BLUE}  |--------------------------------------------------------|${NC}"
        echo ""
    done
}

# Execute main function with all arguments
main "$@"
