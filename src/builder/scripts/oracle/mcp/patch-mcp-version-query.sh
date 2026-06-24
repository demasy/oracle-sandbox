#!/bin/bash
# patch-mcp-version-query.sh — Patch dbtools-mcp.jar to support Oracle AI Database.
# Widens the version query filter from 'Oracle Database%' to 'Oracle%' so ConnectTool
# can resolve the database version on Oracle AI Database Free (which returns no rows
# with the default filter, causing a Version(null) NPE).

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
