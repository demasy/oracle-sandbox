#!/bin/bash
# setup.sh — Image build-time setup orchestrator.
# Called once during docker build (RUN setup.sh) to configure the runtime image.
# Runs all admin scripts in dependency order: sql wrapper → symlinks → mcp patch → user → shell profile.

source /usr/sandbox/app/system/utils/paths.sh

$SETUP/setup-sql.sh
$SETUP/create-symlinks.sh
$SETUP/patch-mcp.sh
$SETUP/create-os-user.sh
$CLI/setup-shell-profile.sh
