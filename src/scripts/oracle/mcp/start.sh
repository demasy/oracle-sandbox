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

# Set connection details from environment or use defaults
# Use MCP-specific user if set, otherwise fall back to default DB user
MCP_USER="${DEMASYLABS_DB_MCP_USER:-${DEMASYLABS_DB_USER:-system}}"
MCP_PASS="${DEMASYLABS_DB_PASSWORD:-${DEMASYLABS_DB_PASS:-Demasy1986}}"
DB_CONNECTION="${MCP_USER}/${MCP_PASS}@${DEMASYLABS_DB_HOST:-192.168.1.110}:${DEMASYLABS_DB_PORT:-1521}/${DEMASYLABS_DB_SERVICE:-FREEPDB1}"

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
