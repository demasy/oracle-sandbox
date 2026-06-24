#!/bin/bash
# Canonical path constants for the Oracle Sandbox image.
# Usage: source /usr/sandbox/app/system/utils/paths.sh

APP=/usr/sandbox/app
SYSTEM=$APP/system

# System paths
BUILD=$SYSTEM/build       # Startup and builder scripts
ADMIN=$SYSTEM/admin       # Image setup and admin scripts
UTILS=$SYSTEM/utils       # Shared utilities (this file lives here)
DOWNLOAD=$SYSTEM/download # Download scripts for Oracle components
INSTALL=$SYSTEM/install   # Installation scripts

# CLI
CLI=$APP/cli              # Sandbox CLI commands and completions

# Oracle scripts
ORACLE=$APP/oracle
MCP=$ORACLE/mcp           # MCP server scripts
APEX=$ORACLE/apex         # APEX management scripts
SQLCL=$ORACLE/sqlcl       # SQLcl connection scripts
SQLPLUS=$ORACLE/sqlplus   # SQL*Plus connection scripts
