#!/bin/bash
################################################################################
# Start SQLcl MCP Server with Saved Connection
# Uses the sandbox-ai-conn saved connection (pass a name as $1 to override)
################################################################################

# Check if SQLcl is available
if ! command -v sql &> /dev/null; then
    echo "[MCP] Error: SQLcl not found. Please install SQLcl first." >&2
    exit 1
fi

# Use provided connection name or fall back to default
CONNECTION_NAME="${1:-sandbox-ai-conn}"

echo "[MCP] Starting SQLcl MCP Server with saved connection..." >&2
echo "[MCP] Connection: ${CONNECTION_NAME}" >&2

# Export required environment variables
export ORACLE_HOME=/opt/oracle/instantclient
export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::')

# Start MCP server with saved connection
exec sql -mcp "${CONNECTION_NAME}"
