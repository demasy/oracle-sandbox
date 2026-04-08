#!/bin/bash
################################################################################
# Start SQLcl MCP Server with Saved Connection
# Uses the demasylabs-ai-conn saved connection
################################################################################

# Check if SQLcl is available
if ! command -v sql &> /dev/null; then
    echo "Error: SQLcl not found. Please install SQLcl first."
    exit 1
fi

# Use provided connection name or fall back to default
CONNECTION_NAME="${1:-demasylabs-ai-conn}"

echo "Starting SQLcl MCP Server with saved connection..."
echo "Connection: ${CONNECTION_NAME}"

# Start SQLcl MCP server
cd /opt/oracle/sqlcl/bin

# Export required environment variables
export ORACLE_HOME=/opt/oracle/instantclient
export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::')

# Start MCP server with saved connection
./sql -mcp "${CONNECTION_NAME}"
