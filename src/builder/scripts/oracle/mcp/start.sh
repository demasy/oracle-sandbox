#!/bin/bash
################################################################################
# Start SQLcl MCP Server
# Model Context Protocol server for Oracle Database via SQLcl
################################################################################

# Check if SQLcl is available
if ! command -v sql &> /dev/null; then
    echo "Error: SQLcl not found. Please install SQLcl first." >&2
    exit 1
fi

# Set connection details from environment (no hardcoded fallbacks)
MCP_USER="${DEMASYLABS_DB_MCP_USER:-${DEMASYLABS_DB_USER}}"
MCP_PASS="${DEMASYLABS_DB_PASSWORD:-${DEMASYLABS_DB_PASS}}"

# Validate required environment variables
if [ -z "$MCP_USER" ] || [ -z "$MCP_PASS" ]; then
    echo "Error: Database credentials not set" >&2
    echo "Required: DEMASYLABS_DB_MCP_USER (or DEMASYLABS_DB_USER) and DEMASYLABS_DB_PASSWORD (or DEMASYLABS_DB_PASS)" >&2
    exit 1
fi

MCP_SERVICE="${DEMASYLABS_DB_MCP_SERVICE:-${DEMASYLABS_DB_SERVICE}}"

if [ -z "$DEMASYLABS_DB_HOST" ] || [ -z "$DEMASYLABS_DB_PORT" ] || [ -z "$MCP_SERVICE" ]; then
    echo "Error: Database connection parameters not set" >&2
    echo "Required: DEMASYLABS_DB_HOST, DEMASYLABS_DB_PORT, DEMASYLABS_DB_MCP_SERVICE (or DEMASYLABS_DB_SERVICE)" >&2
    exit 1
fi

CONN_STRING="${MCP_USER}/${MCP_PASS}@//${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${MCP_SERVICE}"
CONN_NAME="sandbox-ai-conn"

echo "Refreshing saved connection '${CONN_NAME}'..." >&2

# Recreate the saved connection from env vars so credentials are always current
sql /nolog <<EOF >/dev/null 2>&1
CONN -save ${CONN_NAME} -savepwd ${CONN_STRING}
exit
EOF

echo "Starting SQLcl MCP Server..." >&2
echo "Connection: ${MCP_USER}@${DEMASYLABS_DB_HOST}:${DEMASYLABS_DB_PORT}/${MCP_SERVICE}" >&2

# Export required environment variables
export ORACLE_HOME=/opt/oracle/instantclient
export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::')

# Start MCP server — saved connection triggers auto-connect at startup
exec sql -mcp "${CONN_NAME}"
