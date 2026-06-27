# ─── sandbox config ───────────────────────────────────────────────────────────
# Sourced by sandbox.sh before dispatch — centralized configuration for all scripts
# ─────────────────────────────────────────────────────────────────────────────

# ─── Database Users ───────────────────────────────────────────────────────────
# Valid users for "sandbox run sqlcl --user <user>"
VALID_SQLCL_USERS="sys system sandbox sandbox_ai demasy demasy_ai"

# ─── Action & Resource Definitions ────────────────────────────────────────────
# Maps actions → valid resources (replaces inline resources_for() function)
declare -A SANDBOX_RESOURCES=(
    [download]="apex"
    [install]="apex"
    [uninstall]="apex"
    [start]="apex mcp"
    [stop]="apex mcp"
    [restart]="apex mcp"
    [run]="sqlcl mcp healthcheck script"
    [status]="database apex mcp network all"
    [conn]="list add delete test rename"
    [logs]="apex install ords startup mcp all"
    [export]="config connections all"
    [import]="config connections all"
    [batch]="apply-connections apply-commands apply-with-rollback execute"
    [monitor]="system database apex all"
    [audit]="list show search export stats rollback"
    [template]="save load list delete export import"
    [backup]="full connections ords config schemas list"
    [restore]="full connections ords config schemas"
)

# Actions that allow omitting resource (run all resources as dashboard)
SANDBOX_OPTIONAL_RESOURCE_ACTIONS="status export import batch monitor audit template"

# ─── Log File Registry ────────────────────────────────────────────────────────
# Centralized paths for log files (replaces hard-coded paths in action scripts)
declare -A SANDBOX_LOG_PATHS=(
    [apex]="/tmp/apex_install.log"
    [install]="/tmp/apex_install.log"
    [ords]="/tmp/ords_install.log"
    [startup]="/var/log/sandbox_startup.log"
    [mcp]="/tmp/sqlcl_mcp.log"
)

# ─── Sandbox Paths ────────────────────────────────────────────────────────────
SANDBOX_HOME="${SANDBOX_HOME:-/usr/sandbox}"
SANDBOX_APP="${SANDBOX_APP:-${SANDBOX_HOME}/app}"
SANDBOX_SCRIPTS="${SANDBOX_SCRIPTS:-${SANDBOX_APP}/scripts}"
SANDBOX_CLI="${SANDBOX_CLI:-${SANDBOX_APP}/cli}"
SANDBOX_UTILS="${SANDBOX_UTILS:-${SANDBOX_APP}/system/utils}"
SANDBOX_MONITORING="${SANDBOX_MONITORING:-${SANDBOX_APP}/oracle/admin/monitoring}"

# ─── Database Connection Defaults ─────────────────────────────────────────────
# Connection parameters (sourced from environment, with defaults)
SANDBOX_DB_HOST="${SANDBOX_DB_HOST:-localhost}"
SANDBOX_DB_PORT="${SANDBOX_DB_PORT:-1521}"
SANDBOX_DB_SERVICE="${SANDBOX_DB_SERVICE:-FREEPDB1}"
SANDBOX_DB_USER="${SANDBOX_DB_USER:-system}"

# ─── Output Formatting ────────────────────────────────────────────────────────
# Default output format (table | json | csv | quiet)
SANDBOX_OUTPUT_FORMAT="${SANDBOX_OUTPUT_FORMAT:-table}"

# Default log tail line count for "sandbox logs" command
SANDBOX_LOG_TAIL_LINES="${SANDBOX_LOG_TAIL_LINES:-50}"

# ─── CLI Aliases ──────────────────────────────────────────────────────────────
# Command aliases for convenience (sourced by sandbox-aliases.sh)
declare -A SANDBOX_ALIASES=(
    [sb]="sandbox"
    [sr]="sandbox run"
    [sc]="sandbox conn"
    [sl]="sandbox logs"
    [ss]="sandbox status"
    [si]="sandbox install"
    [sk]="sandbox start"
    [sp]="sandbox stop"
    [sx]="sandbox restart"
)

# ─── Debug & Verbosity ────────────────────────────────────────────────────────
# Enable debug output (set to 1 to enable)
SANDBOX_DEBUG="${SANDBOX_DEBUG:-0}"

# ─── Centralized Help Text ─────────────────────────────────────────────────────
# Help descriptions for all commands (supports: sandbox help search <keyword>)
# Format: "action:resource" → "brief description"
declare -A SANDBOX_HELP_SHORT=(
    # ── Actions ──
    [run]="Execute or connect to a service"
    [status]="Show running status of a service"
    [start]="Start a service"
    [stop]="Stop a service"
    [restart]="Restart a service"
    [install]="Install Oracle components"
    [uninstall]="Uninstall Oracle components"
    [download]="Download Oracle APEX + ORDS"
    [conn]="Manage saved database connections"
    [logs]="View and stream log files"
    [export]="Export configuration and connections"
    [import]="Import configuration and connections"
    [backup]="Backup connections, ORDS config, and schemas"
    [restore]="Restore from a previous backup"
    [audit]="View and search CLI audit logs"
    [batch]="Execute batch operations from a file"
    [monitor]="Collect system and database metrics"
    [template]="Save and load configuration templates"

    # ── run ──
    [run:sqlcl]="Open an interactive SQLcl session"
    [run:mcp]="Run the MCP server (use start mcp instead)"
    [run:healthcheck]="Run a full sandbox health check"
    [run:script]="Execute an Oracle admin script"

    # ── status ──
    [status:database]="Check database port and SQL connectivity"
    [status:apex]="Check APEX/ORDS process and HTTP endpoints"
    [status:mcp]="Check MCP server process"
    [status:network]="Show container network topology and connectivity"
    [status:all]="Show all service statuses"

    # ── conn ──
    [conn:list]="List all saved connections"
    [conn:add]="Add a new saved connection"
    [conn:delete]="Delete a saved connection"
    [conn:rename]="Rename a saved connection"
    [conn:test]="Test a saved connection"

    # ── logs ──
    [logs:apex]="APEX installation log"
    [logs:install]="All installation logs (APEX + ORDS)"
    [logs:ords]="ORDS runtime log"
    [logs:startup]="Container startup log"
    [logs:mcp]="MCP server log"
    [logs:all]="All log files combined"

    # ── start / stop / restart ──
    [start:apex]="Start Oracle APEX (ORDS)"
    [start:mcp]="Start the MCP server"
    [stop:apex]="Stop Oracle APEX (ORDS)"
    [stop:mcp]="Stop the MCP server"
    [restart:apex]="Restart Oracle APEX (ORDS)"
    [restart:mcp]="Restart the MCP server"

    # ── install / uninstall / download ──
    [install:apex]="Install Oracle APEX + ORDS"
    [uninstall:apex]="Uninstall Oracle APEX + ORDS"
    [download:apex]="Download Oracle APEX + ORDS packages"

    # ── export / import ──
    [export:config]="Export all sandbox settings"
    [export:connections]="Export saved connections"
    [export:all]="Export everything"
    [import:config]="Import sandbox settings from file"
    [import:connections]="Import saved connections from file"

    # ── backup / restore ──
    [backup:full]="Backup everything"
    [backup:connections]="Backup saved connection files"
    [backup:ords]="Backup ORDS configuration"
    [backup:config]="Backup sandbox environment config"
    [backup:schemas]="Backup Oracle schemas via Data Pump"
    [backup:list]="List available backups"
    [restore:full]="Restore everything from a backup"
    [restore:connections]="Restore saved connections"
    [restore:ords]="Restore ORDS configuration"
    [restore:config]="Restore sandbox environment config"
    [restore:schemas]="Restore Oracle schemas via Data Pump"

    # ── audit ──
    [audit:list]="List recent audit log entries"
    [audit:show]="Show a single audit entry by ID"
    [audit:search]="Search audit logs by keyword"
    [audit:export]="Export audit log as JSON or CSV"
    [audit:stats]="Show audit statistics and summary"
    [audit:rollback]="Rollback an operation by ID"

    # ── batch ──
    [batch:execute]="Execute sandbox commands from a file"
    [batch:apply-connections]="Add connections from a CSV file"
    [batch:apply-commands]="Run sandbox commands from a text file"

    # ── monitor ──
    [monitor:system]="System metrics (CPU, memory, disk)"
    [monitor:database]="Database metrics (connections, transactions)"
    [monitor:apex]="APEX/ORDS metrics"
    [monitor:all]="All metrics combined"

    # ── template ──
    [template:save]="Save current config as a template"
    [template:load]="Load a saved template"
    [template:list]="List all templates"
    [template:delete]="Delete a template"
    [template:export]="Export a template to a file"
    [template:import]="Import a template from a file"
)

# ─── Keywords for help search ──────────────────────────────────────────────────
declare -A SANDBOX_HELP_KEYWORDS=(
    [sql]="run:sqlcl status:database conn:list conn:test"
    [sqlcl]="run:sqlcl conn:list conn:add conn:test"
    [database]="status:database run:sqlcl logs:startup backup:schemas restore:schemas"
    [db]="status:database run:sqlcl backup:schemas"
    [connection]="conn:add conn:list conn:test conn:delete conn:rename"
    [connect]="conn:add conn:list conn:test run:sqlcl"
    [conn]="conn:list conn:add conn:test conn:delete conn:rename"
    [mcp]="run:mcp start:mcp stop:mcp status:mcp logs:mcp"
    [apex]="install:apex uninstall:apex status:apex logs:apex download:apex start:apex stop:apex"
    [ords]="install:apex logs:ords start:apex stop:apex backup:ords restore:ords"
    [web]="status:apex logs:ords start:apex"
    [http]="status:apex run:healthcheck"
    [start]="start:apex start:mcp"
    [stop]="stop:apex stop:mcp"
    [restart]="restart:apex restart:mcp"
    [service]="start:apex start:mcp stop:apex stop:mcp restart:apex restart:mcp"
    [status]="status:database status:apex status:mcp status:network run:healthcheck"
    [health]="run:healthcheck status:database status:apex status:mcp"
    [healthcheck]="run:healthcheck status:database status:apex status:mcp"
    [monitor]="monitor:system monitor:database monitor:apex monitor:all"
    [dashboard]="monitor:all status:database status:apex status:mcp"
    [performance]="monitor:database monitor:system status:database"
    [log]="logs:apex logs:ords logs:startup logs:mcp logs:all"
    [logs]="logs:apex logs:ords logs:startup logs:mcp logs:all"
    [startup]="logs:startup status:database"
    [debug]="logs:all logs:startup run:healthcheck"
    [error]="logs:startup logs:apex logs:mcp"
    [install]="install:apex download:apex"
    [setup]="install:apex run:healthcheck logs:startup"
    [deploy]="install:apex download:apex run:healthcheck"
    [download]="download:apex"
    [backup]="backup:full backup:connections backup:ords backup:config backup:schemas backup:list"
    [restore]="restore:full restore:connections restore:ords restore:config restore:schemas"
    [audit]="audit:list audit:search audit:stats audit:export audit:rollback"
    [export]="export:config export:connections backup:full audit:export"
    [import]="import:config import:connections"
    [template]="template:save template:load template:list template:delete"
    [batch]="batch:execute batch:apply-connections batch:apply-commands"
    [network]="status:network status:database status:apex"
    [script]="run:script run:healthcheck"
    [list]="conn:list backup:list audit:list template:list"
    [rename]="conn:rename"
    [delete]="conn:delete template:delete"
    [save]="template:save backup:full"
    [schema]="backup:schemas restore:schemas"
    [schemas]="backup:schemas restore:schemas"
    [pump]="backup:schemas restore:schemas"
    [full]="backup:full restore:full"
)

# ─── Command categories (for help organization) ────────────────────────────────
declare -a SANDBOX_HELP_CATEGORIES=(
    "Connections:  conn:list conn:add conn:test conn:rename conn:delete run:sqlcl"
    "Services:     start:apex start:mcp stop:apex stop:mcp restart:apex restart:mcp"
    "Status:       status:database status:apex status:mcp status:network run:healthcheck"
    "Logs:         logs:startup logs:apex logs:ords logs:mcp logs:all"
    "Installation:  install:apex uninstall:apex download:apex"
    "Backup:       backup:full backup:connections backup:schemas backup:list restore:full"
    "Data:         export:config export:connections import:config import:connections"
    "Audit:        audit:list audit:search audit:stats audit:rollback"
    "Automation:   batch:execute template:save template:load monitor:all run:script"
)
