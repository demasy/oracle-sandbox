#!/bin/bash
# One-time image setup: run all admin configuration scripts in order.

ADMIN=/usr/sandbox/app/system/admin
MCP=/usr/sandbox/app/oracle/mcp/
CLI=/usr/sandbox/app/cli

$ADMIN/setup-sql-wrapper.sh
$ADMIN/setup-symlinks.sh
$MCP/patch-mcp-version-query.sh
$ADMIN/setup-sandbox-user.sh
$CLI/setup-shell-profile.sh
