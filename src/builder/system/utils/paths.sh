#!/bin/bash
# Canonical path constants for the Oracle Sandbox image.
# Usage: source /usr/sandbox/app/system/utils/paths.sh
[[ -n "$_PATHS_LOADED" ]] && return; _PATHS_LOADED=1

# ─────────────────────────────────────────────
# App Root
# ─────────────────────────────────────────────
APP=/usr/sandbox/app
SYSTEM=$APP/system
SB_LOG=$APP/logs          # Sandbox log directory
DEMASY_LABS=$APP/demasylabs  # Planned future use

# ─────────────────────────────────────────────
# System Scripts  (/usr/sandbox/app/system/*)
# ─────────────────────────────────────────────
ADMIN=$SYSTEM/admin       # Admin scripts (healthcheck)
BUILD=$SYSTEM/build       # Startup and builder scripts
SETUP=$SYSTEM/setup       # Image setup scripts (run once at build time)
UTILS=$SYSTEM/utils       # Shared utilities (this file lives here)
# XX_DOWNLOAD=$SYSTEM/download # Download scripts for Oracle components
# XX_INSTALL=$SYSTEM/install   # Installation scripts

DOWNLOAD=$APP/download         # Download scripts for Oracle components
INSTALL=$APP/install           # Installation scripts
INSTALL_ORACLE=$INSTALL/oracle # Oracle component install scripts

# ─────────────────────────────────────────────
# CLI  (/usr/sandbox/app/cli/*)
# ─────────────────────────────────────────────
CLI=$SYSTEM/cli           # Sandbox CLI commands and completions

# ─────────────────────────────────────────────
# Oracle Scripts  (/usr/sandbox/app/oracle/*)
# ─────────────────────────────────────────────
ORACLE_SCRIPTS=$APP/oracle
APEX=$ORACLE_SCRIPTS/apex       # APEX management scripts
MCP=$ORACLE_SCRIPTS/mcp         # MCP server scripts
SQLCL=$ORACLE_SCRIPTS/sqlcl     # SQLcl connection scripts
SQLPLUS=$ORACLE_SCRIPTS/sqlplus # SQL*Plus connection scripts

# ─────────────────────────────────────────────
# Oracle Home  (/opt/oracle/*)
# ─────────────────────────────────────────────
ORACLE_HOME=/opt/oracle
ORACLE_INSTANTCLIENT=$ORACLE_HOME/instantclient
ORACLE_APEX_HOME=$ORACLE_HOME/apex
ORACLE_ORDS_HOME=$ORACLE_HOME/ords
ORACLE_ORDS_BIN=$ORACLE_ORDS_HOME/bin/ords
ORACLE_ORDS_CONFIG=$ORACLE_ORDS_HOME/config
ORACLE_SQLCL_HOME=$ORACLE_HOME/sqlcl
ORACLE_SQLCL_BIN=$ORACLE_SQLCL_HOME/bin/sql
ORACLE_DATA=$ORACLE_HOME/oradata/FREE
ORACLE_PDB_DATA=$ORACLE_DATA/FREEPDB1

# ─────────────────────────────────────────────
# Users & Home Directories
# ─────────────────────────────────────────────
ROOT_BASHRC=/root/.bashrc
ORACLE_LOGS=/home/oracle/logs
SANDBOX_HOME=/home/sandbox
SANDBOX_BASHRC=$SANDBOX_HOME/.bashrc
SANDBOX_DBTOOLS=$SANDBOX_HOME/.dbtools
SANDBOX_CONNECTIONS=$SANDBOX_DBTOOLS/connections

# ─────────────────────────────────────────────
# System Binaries
# ─────────────────────────────────────────────
BIN=/usr/local/bin
JAVA_JVM=/usr/lib/jvm

# ─────────────────────────────────────────────
# Tmp  (/tmp/sandbox/*)
# ─────────────────────────────────────────────
TMP=/tmp/sandbox
LOG=$TMP/logs

# Working directories
TMP_APEX=$TMP/apex-install
TMP_APEX_IMAGES=$TMP/apex-images
TMP_AUDIT=$TMP/sandbox-audit
TMP_MCP=$TMP/mcp-patch
TMP_ORDS_CONFIG=$TMP/ords-config
TMP_TEMPLATES=$TMP/sandbox-templates

# Log files
LOG_STARTUP=$LOG/startup.log
LOG_APEX_INSTALL=$LOG/apex-install.log
LOG_APEX_REST=$LOG/apex-rest-config.log
LOG_MCP=$LOG/mcp.log
LOG_ORDS=$LOG/ords.log
LOG_ORDS_ACCESS=$LOG/ords-access.log
LOG_ORDS_INSTALL=$LOG/ords-install.log
