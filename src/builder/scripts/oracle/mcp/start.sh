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
MCP_USER="${SANDBOX_DB_MCP_USER:-${SANDBOX_DB_USER}}"
MCP_PASS="${SANDBOX_DB_PASSWORD:-${SANDBOX_DB_PASS}}"

# Validate required environment variables
if [ -z "$MCP_USER" ] || [ -z "$MCP_PASS" ]; then
    echo "Error: Database credentials not set" >&2
    echo "Required: SANDBOX_DB_MCP_USER (or SANDBOX_DB_USER) and SANDBOX_DB_PASSWORD (or SANDBOX_DB_PASS)" >&2
    exit 1
fi

MCP_SERVICE="${SANDBOX_DB_MCP_SERVICE:-${SANDBOX_DB_SERVICE}}"

if [ -z "$SANDBOX_DB_HOST" ] || [ -z "$SANDBOX_DB_PORT" ] || [ -z "$MCP_SERVICE" ]; then
    echo "Error: Database connection parameters not set" >&2
    echo "Required: SANDBOX_DB_HOST, SANDBOX_DB_PORT, SANDBOX_DB_MCP_SERVICE (or SANDBOX_DB_SERVICE)" >&2
    exit 1
fi

CONN_STRING="${MCP_USER}/${MCP_PASS}@//${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT}/${MCP_SERVICE}"
CONN_NAME="sandbox-ai-conn"

echo "[MCP] Refreshing saved connection '${CONN_NAME}'..." >&2

# Recreate the saved connection from env vars so credentials are always current
sql /nolog <<EOF 2>&1 | while IFS= read -r line; do echo "[MCP] $line" >&2; done
CONN -save ${CONN_NAME} -savepwd ${CONN_STRING}
exit
EOF
SAVE_RC=${PIPESTATUS[0]}
if [ $SAVE_RC -ne 0 ]; then
    echo "[MCP] Warning: connection save returned exit code $SAVE_RC" >&2
else
    echo "[MCP] Saved connection '${CONN_NAME}' refreshed successfully" >&2
fi

echo "[MCP] Starting SQLcl MCP Server..." >&2
echo "[MCP] Connection: ${MCP_USER}@${SANDBOX_DB_HOST}:${SANDBOX_DB_PORT}/${MCP_SERVICE}" >&2

# Export required environment variables
export ORACLE_HOME=/opt/oracle/instantclient
export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::')

# Start MCP server — saved connection triggers auto-connect at startup
exec sql -mcp "${CONN_NAME}"
