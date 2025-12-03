#!/bin/bash
################################################################################
# Setup Saved SQLcl Connection for MCP
# Creates the demasylabs-ai-conn saved connection with credentials
################################################################################

# Check required environment variables
if [ -z "$DEMASYLABS_DB_MCP_USER" ] || [ -z "$DEMASYLABS_DB_PASSWORD" ]; then
    echo "Error: Required environment variables not set"
    echo "Please set: DEMASYLABS_DB_MCP_USER, DEMASYLABS_DB_PASSWORD"
    exit 1
fi

if [ -z "$DEMASYLABS_DB_HOST" ] || [ -z "$DEMASYLABS_DB_PORT" ] || [ -z "$DEMASYLABS_DB_SERVICE" ]; then
    echo "Error: Database connection variables not set"
    echo "Please set: DEMASYLABS_DB_HOST, DEMASYLABS_DB_PORT, DEMASYLABS_DB_SERVICE"
    exit 1
fi

echo "Setting up saved SQLcl connection..."

# Remove old connection data if exists
rm -f /root/.sqlcl/connections.json 2>/dev/null

# Create the saved connection using environment variables
/opt/oracle/sqlcl/bin/sql /nolog <<EOSQL
CONNECT ${DEMASYLABS_DB_MCP_USER}/${DEMASYLABS_DB_PASSWORD}@//${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}
CONN -save demasylabs-ai-conn -savepwd
EXIT
EOSQL

echo "Saved connection 'demasylabs-ai-conn' created successfully"