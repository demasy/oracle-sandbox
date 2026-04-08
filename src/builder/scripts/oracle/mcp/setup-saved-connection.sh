#!/bin/bash
################################################################################
# Setup Saved SQLcl Connection for MCP
# Creates the demasylabs-ai-conn saved connection with credentials
################################################################################

# Resolve credentials — MCP user falls back to default DB user
DEMASYLABS_DB_MCP_USER="${DEMASYLABS_DB_MCP_USER:-${DEMASYLABS_DB_USER}}"
DEMASYLABS_DB_PASSWORD="${DEMASYLABS_DB_PASSWORD:-${DEMASYLABS_DB_PASS}}"

# Check required environment variables
if [ -z "$DEMASYLABS_DB_MCP_USER" ] || [ -z "$DEMASYLABS_DB_PASSWORD" ]; then
    echo "Error: Required environment variables not set"
    echo "Please set: DEMASYLABS_DB_MCP_USER (or DEMASYLABS_DB_USER) and DEMASYLABS_DB_PASSWORD (or DEMASYLABS_DB_PASS)"
    exit 1
fi

if [ -z "$DEMASYLABS_DB_HOST" ] || [ -z "$DEMASYLABS_DB_PORT" ] || [ -z "$DEMASYLABS_DB_SERVICE" ]; then
    echo "Error: Database connection variables not set"
    echo "Please set: DEMASYLABS_DB_HOST, DEMASYLABS_DB_PORT, DEMASYLABS_DB_SERVICE"
    exit 1
fi

echo "Setting up saved SQLcl connection..."
echo "User: ${DEMASYLABS_DB_MCP_USER}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}"

# Create (or overwrite) the saved connection — stores credentials in ~/.dbtools
/opt/oracle/sqlcl/bin/sql /nolog <<EOSQL
CONN -save demasylabs-ai-conn -savepwd ${DEMASYLABS_DB_MCP_USER}/${DEMASYLABS_DB_PASSWORD}@//${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}
EXIT
EOSQL

# SQLcl 26.x stores each connection in its own subdirectory under ~/.dbtools/connections/
if find /root/.dbtools/connections -name "dbtools.properties" 2>/dev/null | xargs grep -l "demasylabs-ai-conn" 2>/dev/null | grep -q .; then
    echo "Saved connection 'demasylabs-ai-conn' created successfully"
else
    echo "Warning: saved connection 'demasylabs-ai-conn' not found in ~/.dbtools/connections — setup may have failed"
fi