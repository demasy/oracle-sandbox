#!/bin/bash
################################################################################
# Setup Saved SQLcl Connection for MCP
# Creates the sandbox-ai-conn saved connection with credentials
################################################################################

# Resolve credentials — MCP user falls back to default DB user
DEMASYLABS_DB_MCP_USER="${DEMASYLABS_DB_MCP_USER:-${DEMASYLABS_DB_USER}}"
DEMASYLABS_DB_MCP_SERVICE="${DEMASYLABS_DB_MCP_SERVICE:-${DEMASYLABS_DB_SERVICE}}"
DEMASYLABS_DB_PASSWORD="${DEMASYLABS_DB_PASSWORD:-${DEMASYLABS_DB_PASS}}"

# Check required environment variables
if [ -z "$DEMASYLABS_DB_MCP_USER" ] || [ -z "$DEMASYLABS_DB_PASSWORD" ]; then
    echo "Error: Required environment variables not set"
    echo "Please set: DEMASYLABS_DB_MCP_USER (or DEMASYLABS_DB_USER) and DEMASYLABS_DB_PASSWORD (or DEMASYLABS_DB_PASS)"
    exit 1
fi

if [ -z "$DEMASYLABS_DB_HOST" ] || [ -z "$DEMASYLABS_DB_PORT" ] || [ -z "$DEMASYLABS_DB_MCP_SERVICE" ]; then
    echo "Error: Database connection variables not set"
    echo "Please set: DEMASYLABS_DB_HOST, DEMASYLABS_DB_PORT, DEMASYLABS_DB_MCP_SERVICE"
    exit 1
fi

echo "Setting up saved SQLcl connection..."
echo "User: ${DEMASYLABS_DB_MCP_USER}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_MCP_SERVICE}"

# Create (or overwrite) the saved connection — stores credentials in ~/.dbtools
/opt/oracle/sqlcl/bin/sql /nolog <<EOSQL
CONN -save sandbox-ai-conn -savepwd ${DEMASYLABS_DB_MCP_USER}/${DEMASYLABS_DB_PASSWORD}@//${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_MCP_SERVICE}
EXIT
EOSQL

# SQLcl 26.x stores each connection in its own subdirectory under ~/.dbtools/connections/
if find /root/.dbtools/connections -name "dbtools.properties" 2>/dev/null | xargs grep -l "sandbox-ai-conn" 2>/dev/null | grep -q .; then
    echo "Saved connection 'sandbox-ai-conn' created successfully"
else
    echo "Error: saved connection 'sandbox-ai-conn' not found in ~/.dbtools/connections — setup failed"
    exit 1
fi