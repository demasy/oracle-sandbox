#!/bin/bash
# Patch SQLcl MCP server: fix version query to match "Oracle AI Database" product name.
# The default filter 'Oracle Database%' returns no rows for Oracle AI Database Free edition,
# causing Version(null) NPE in ConnectTool.

TMPDIR=/tmp/mcp-patch
rm -rf "$TMPDIR" && mkdir -p "$TMPDIR"
cd "$TMPDIR"

jar xf /opt/oracle/sqlcl/lib/dbtools-mcp.jar \
    oracle/dbtools/extension/mcp/command/xml/McpToolsQueries.xml

sed -i "s/WHERE product LIKE 'Oracle Database%'/WHERE product LIKE 'Oracle%'/" \
    oracle/dbtools/extension/mcp/command/xml/McpToolsQueries.xml

jar uf /opt/oracle/sqlcl/lib/dbtools-mcp.jar \
    oracle/dbtools/extension/mcp/command/xml/McpToolsQueries.xml

rm -rf "$TMPDIR"
