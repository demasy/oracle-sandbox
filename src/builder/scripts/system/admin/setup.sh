#!/bin/bash
# setup.sh — Image build-time setup orchestrator.
# Called once during docker build (RUN setup.sh) to configure the runtime image.
# Runs all admin scripts in dependency order: sql wrapper → symlinks → mcp patch → user → shell profile.

source /usr/sandbox/app/system/utils/paths.sh

$ADMIN/setup-sql-wrapper.sh
$ADMIN/setup-symlinks.sh
$MCP/patch-mcp-version-query.sh
$ADMIN/setup-sandbox-user.sh
$CLI/setup-shell-profile.sh
