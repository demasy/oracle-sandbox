#!/bin/bash
# setup-symlinks.sh — Register all sandbox commands in /usr/local/bin.
# Creates symlinks so sandbox, sb, demasy, sqlcl, sqlplus, start-mcp, and
# download-oracle-components are available on PATH without full paths.

source /usr/sandbox/app/system/utils/paths.sh

# Download helper
ln -s $DOWNLOAD/download.sh $BIN/download-oracle-components

# CLI tools
ln -s $CLI/sandbox.sh $BIN/demasy
ln -s $CLI/sandbox.sh $BIN/sandbox
ln -s $CLI/sandbox.sh $BIN/sb
ln -s $SQLPLUS/sqlplus-connect.sh $BIN/sqlplus
ln -s $SQLCL/sqlcl-connect.sh    $BIN/sqlcl

# MCP tools
ln -s $MCP/start.sh $BIN/start-mcp
ln -s $MCP/start.sh $BIN/mcp
