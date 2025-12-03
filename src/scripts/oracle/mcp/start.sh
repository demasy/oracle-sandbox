#!/bin/bash
################################################################################
# Start SQLcl MCP Server
# Model Context Protocol server for Oracle Database via SQLcl
################################################################################

# Check if SQLcl is available
if ! command -v sql &> /dev/null; then
    echo "Error: SQLcl not found. Please install SQLcl first."
    exit 1
fi

# Set connection details from environment (no hardcoded fallbacks)
MCP_USER="${DEMASYLABS_DB_MCP_USER:-${DEMASYLABS_DB_USER}}"
MCP_PASS="${DEMASYLABS_DB_PASSWORD:-${DEMASYLABS_DB_PASS}}"

# Validate required environment variables
if [ -z "$MCP_USER" ] || [ -z "$MCP_PASS" ]; then
    echo "Error: Database credentials not set"
    echo "Required: DEMASYLABS_DB_MCP_USER (or DEMASYLABS_DB_USER) and DEMASYLABS_DB_PASSWORD (or DEMASYLABS_DB_PASS)"
    exit 1
fi

if [ -z "$DEMASYLABS_DB_HOST" ] || [ -z "$DEMASYLABS_DB_PORT" ] || [ -z "$DEMASYLABS_DB_SERVICE" ]; then
    echo "Error: Database connection parameters not set"
    echo "Required: DEMASYLABS_DB_HOST, DEMASYLABS_DB_PORT, DEMASYLABS_DB_SERVICE"
    exit 1
fi

DB_CONNECTION="${MCP_USER}/${MCP_PASS}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}"

echo "Starting SQLcl MCP Server..."
echo "Connection: ${MCP_USER}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${DEMASYLABS_DB_SERVICE}"

# Start SQLcl MCP server
# SQLcl 25.x+ has built-in MCP support via the 'mcp' command
cd /opt/oracle/sqlcl/bin

# Export required environment variables
export ORACLE_HOME=/opt/oracle/instantclient
export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::')

# Start MCP server
./sql -mcp -connect "$DB_CONNECTION"
