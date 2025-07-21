#!/bin/bash
clear

bold=$(tput bold)
normal=$(tput sgr0)

echo ""
echo "  |--------------------------------------------------------|"
echo -e "  |            \e[1;31m     Demasy Labs Database V1.0  \e[0m            |"
echo -e "  |                \e[1;33m Developed by Demasy Labs\e[0m               |"
echo "  |                email: founder@demasy.io                |"
echo "  |                website: www.demasy.io                  |"
echo "  |             github: www.github.com/demasy              |"
echo "  |        Ahmed El-Demasy - Founder of Demasy Labs        |"
echo "  |--------------------------------------------------------|"
echo ""
echo "      Welcome! $USER - $(date)"
echo ""
echo "       - Host: $ROKETTO_DB_HOST"
echo "       - Port: $ROKETTO_DB_PORT"
echo "       - Service: $ROKETTO_DB_SERVICE"
echo "       - User: $ROKETTO_DB_USER"
echo ""

# Check required environment variables
if [[ -z "$ROKETTO_DB_HOST" || -z "$ROKETTO_DB_PORT" || -z "$ROKETTO_DB_SERVICE" || -z "$ROKETTO_DB_USER" || -z "$ROKETTO_DB_PASS" ]]; then
  echo "Error: One or more required environment variables are not set."
  exit 1
fi

# Connect to Oracle
sql "$ROKETTO_DB_USER/$ROKETTO_DB_PASS@$ROKETTO_DB_HOST:$ROKETTO_DB_PORT/$ROKETTO_DB_SERVICE" || {
  echo "Failed to connect to Oracle Database."
  exit 2
}