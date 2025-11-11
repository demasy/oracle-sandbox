#!/bin/bash
clear

bold=$(tput bold)
normal=$(tput sgr0)

echo ""
echo "  |--------------------------------------------------------|"
echo -e "  |          \e[1;31m     Demasy Labs Database V1.0  \e[0m              |"
echo -e "  |             \e[1;33m SQL*Plus Connection Script\e[0m                |"
echo -e "  |                email: founder@demasy.io                |"
echo -e "  |                website: www.demasy.io                  |"
echo -e "  |             github: www.github.com/demasy              |"
echo -e "  |        Ahmed El-Demasy - Founder of Demasy Labs        |"
echo -e "  |--------------------------------------------------------|"
echo ""

# Check architecture and SQL*Plus availability
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    CLIENT_TYPE="SQL*Plus (Native)"
    if command -v sqlplus &> /dev/null; then
        SQLPLUS_AVAILABLE=true
    else
        SQLPLUS_AVAILABLE=false
    fi
else
    CLIENT_TYPE="SQLcl (SQL*Plus Fallback - ARM64)"
    SQLPLUS_AVAILABLE=true  # Available through fallback
fi

echo "      Welcome! $USER - $(date)"
echo ""
echo "       - Architecture: $ARCH"
echo "       - Client Type: $CLIENT_TYPE"
echo "       - Host: $DEMASYLABS_DB_HOST"
echo "       - Port: $DEMASYLABS_DB_PORT"
echo "       - Service: $DEMASYLABS_DB_SERVICE"
echo "       - User: $DEMASYLABS_DB_USER"
echo ""

# Check required environment variables
if [[ -z "$DEMASYLABS_DB_HOST" || -z "$DEMASYLABS_DB_PORT" || -z "$DEMASYLABS_DB_SERVICE" || -z "$DEMASYLABS_DB_USER" || -z "$DEMASYLABS_DB_PASS" ]]; then
  echo "Error: One or more required environment variables are not set."
  echo "Required variables: DEMASYLABS_DB_HOST, DEMASYLABS_DB_PORT, DEMASYLABS_DB_SERVICE, DEMASYLABS_DB_USER, DEMASYLABS_DB_PASS"
  exit 1
fi

# Check if SQL*Plus (or fallback) is available
if [[ "$SQLPLUS_AVAILABLE" != true ]]; then
    echo "Error: SQL*Plus is not available on this system."
    echo "Please ensure Oracle Client is properly installed."
    exit 1
fi

# Connect to Oracle using SQL*Plus or SQLcl fallback
echo "Connecting to Oracle Database using SQL*Plus..."
echo ""

if [[ "$ARCH" = "x86_64" ]] && [[ -f "/opt/oracle/instantclient/sqlplus" ]]; then
    # Use native SQL*Plus on x86_64
    /opt/oracle/instantclient/sqlplus "$DEMASYLABS_DB_USER/$DEMASYLABS_DB_PASS@$DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT/$DEMASYLABS_DB_SERVICE" || {
        echo "Failed to connect to Oracle Database using SQL*Plus."
        exit 2
    }
else
    # Use SQLcl as fallback on ARM64 or when SQL*Plus is not available
    echo "Using SQLcl as fallback..."
    sql "$DEMASYLABS_DB_USER/$DEMASYLABS_DB_PASS@$DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT/$DEMASYLABS_DB_SERVICE" || {
        echo "Failed to connect to Oracle Database using SQLcl fallback."
        exit 2
    }
fi