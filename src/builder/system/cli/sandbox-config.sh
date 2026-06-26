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

# ─── Centralized Help Text (Phase 2) ───────────────────────────────────────────
# Help descriptions for all commands (supports: sandbox help search <keyword>)
# Format: "action:resource" → "brief description"
declare -A SANDBOX_HELP_SHORT=(
    # Actions
    [run]="Execute or connect to a service"
    [status]="Show running status of a service"
    [start]="Start a service"
    [stop]="Stop a service"
    [restart]="Restart a service"
    [install]="Install Oracle components"
    [uninstall]="Uninstall Oracle components"
    [download]="Download Oracle components"
    [conn]="Manage MCP database connections"
    [logs]="View and stream log files"
    
    # Resources
    [run:sqlcl]="Open interactive SQLcl session to database"
    [run:mcp]="Launch MCP server"
    [run:healthcheck]="Run sandbox health verification checks"
    [run:monitor]="Run monitoring dashboard (active connections, size, queries)"
    
    [status:database]="Check database port and connectivity"
    [status:apex]="Check APEX/ORDS process and HTTP endpoints"
    [status:mcp]="Check MCP server process status"
    
    [conn:list]="Show all saved MCP connections"
    [conn:add]="Create a new saved connection"
    [conn:delete]="Remove a saved connection"
    [conn:rename]="Rename an existing connection"
    [conn:test]="Verify a connection works"
    
    [logs:apex]="View APEX installation output"
    [logs:install]="View all installation logs (APEX + ORDS)"
    [logs:ords]="View ORDS runtime messages"
    [logs:startup]="View container startup sequence"
    [logs:mcp]="View MCP server log"
    [logs:all]="Combine all log files"
    
    [start:apex]="Start APEX/ORDS service"
    [start:mcp]="Start MCP server daemon"
    
    [stop:apex]="Stop APEX/ORDS service"
    [stop:mcp]="Stop MCP server daemon"
    
    [restart:apex]="Restart APEX/ORDS service"
    [restart:mcp]="Restart MCP server daemon"
    
    [install:apex]="Install Oracle APEX application"
    [uninstall:apex]="Remove Oracle APEX"
    
    [download:apex]="Fetch APEX installation package"
    [download:ords]="Fetch ORDS installation package"
)

# ─── Keywords for help search ──────────────────────────────────────────────────
# Maps keywords to commands (for: sandbox help search <keyword>)
declare -A SANDBOX_HELP_KEYWORDS=(
    # Database/Connection keywords
    [sql]="run:sqlcl status:database conn:list conn:test"
    [database]="status:database run:sqlcl logs:startup"
    [connection]="conn:add conn:list conn:test conn:delete"
    [connect]="conn:add conn:list conn:test run:sqlcl"
    [mcp]="run:mcp start:mcp stop:mcp status:mcp logs:mcp"
    
    # APEX/ORDS keywords
    [apex]="install:apex status:apex logs:apex download:apex uninstall:apex"
    [ords]="download:ords logs:ords"
    [web]="status:apex logs:ords"
    [http]="status:apex run:healthcheck"
    
    # Service management keywords
    [start]="start:apex start:mcp"
    [stop]="stop:apex stop:mcp"
    [restart]="restart:apex restart:mcp"
    [service]="start:apex start:mcp stop:apex stop:mcp restart:apex restart:mcp"
    
    # Monitoring/diagnostics keywords
    [status]="status:database status:apex status:mcp run:healthcheck"
    [health]="run:healthcheck status:database status:apex"
    [monitor]="run:monitor logs:all"
    [dashboard]="run:monitor status:database status:apex status:mcp"
    [performance]="run:monitor status:database"
    
    # Logging/debugging keywords
    [log]="logs:apex logs:ords logs:startup logs:mcp logs:all"
    [logs]="logs:apex logs:ords logs:startup logs:mcp logs:all"
    [debug]="logs:all logs:startup run:healthcheck"
    [error]="logs:startup logs:apex logs:mcp"
    [trace]="logs:all"
    
    # Installation keywords
    [install]="install:apex download:apex"
    [setup]="install:apex run:healthcheck logs:startup"
    [deploy]="install:apex download:apex run:healthcheck"
)

# ─── Command categories (for help organization) ────────────────────────────────
declare -a SANDBOX_HELP_CATEGORIES=(
    "Connectivity: conn:list conn:add conn:test conn:delete conn:rename run:sqlcl"
    "Service Mgmt: start:apex start:mcp stop:apex stop:mcp restart:apex restart:mcp"
    "Installation: install:apex uninstall:apex download:apex download:ords"
    "Monitoring: status:database status:apex status:mcp run:monitor run:healthcheck"
    "Logging: logs:apex logs:ords logs:startup logs:mcp logs:all logs:install"
)
