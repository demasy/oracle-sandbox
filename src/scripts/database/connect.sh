#!/bin/bash
clear

bold=$(tput bold)
normal=$(tput sgr0)

echo ""
echo "  |--------------------------------------------------------|"
echo -e "  |          \e[1;31m     Demasy Labs Database V1.0  \e[0m              |"
echo -e "  |             \e[1;33m Developed by Demasy Labs\e[0m                  |"
echo "  |                email: founder@demasy.io                |"
echo "  |                website: www.demasy.io                  |"
echo "  |             github: www.github.com/demasy              |"
echo "  |        Ahmed El-Demasy - Founder of Demasy Labs        |"
echo "  |--------------------------------------------------------|"
echo ""
echo "      Welcome! $USER - $(date)"
echo ""
echo "       - Host: $DEMASYLABS_DB_HOST"
echo "       - Port: $DEMASYLABS_DB_PORT"
echo "       - Service: $DEMASYLABS_DB_SERVICE"
echo "       - User: $DEMASYLABS_DB_USER"
echo ""

# Check required environment variables
if [[ -z "$DEMASYLABS_DB_HOST" || -z "$DEMASYLABS_DB_PORT" || -z "$DEMASYLABS_DB_SERVICE" || -z "$DEMASYLABS_DB_USER" || -z "$DEMASYLABS_DB_PASS" ]]; then
  echo "Error: One or more required environment variables are not set."
  exit 1
fi

# Connect to Oracle
sql "$DEMASYLABS_DB_USER/$DEMASYLABS_DB_PASS@$DEMASYLABS_DB_HOST:$DEMASYLABS_DB_PORT/$DEMASYLABS_DB_SERVICE" || {
  echo "Failed to connect to Oracle Database."
  exit 2
}