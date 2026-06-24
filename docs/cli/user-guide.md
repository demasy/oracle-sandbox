# Sandbox CLI User Guide

<div align="center">

**Complete reference for the Sandbox Command-Line Interface (CLI)**

Master the unified command-line toolkit for managing Oracle Sandbox operations, connections, and configurations.

[Quick Start](#quick-start) • [Command Reference](#command-reference) • [Global Flags](#global-flags) • [Aliases](#aliases) • [Workflows](#real-world-workflows) • [Troubleshooting](#troubleshooting)

</div>

<br>

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Syntax](#syntax)
4. [Global Flags](#global-flags)
5. [Command Reference](#command-reference)
   - [run](#run--execute-tools)
   - [status](#status--check-health)
   - [conn](#conn--manage-connections)
   - [logs](#logs--view-logs)
   - [start / stop / restart](#start--stop--restart--service-control)
   - [install / uninstall / download](#install--uninstall--download)
   - [monitor](#monitor--metrics-dashboard)
   - [audit](#audit--operation-history)
   - [template](#template--configuration-snapshots)
   - [batch](#batch--bulk-operations)
   - [export / import](#export--import--configurationbackup)
   - [help](#help--discovery)
6. [Output Formats](#output-formats)
7. [Aliases & Shortcuts](#aliases--shortcuts)
8. [Tab Completion](#tab-completion)
9. [Real-World Workflows](#real-world-workflows)
10. [Troubleshooting](#troubleshooting)

<br>

## Overview

The **Sandbox CLI** (`sandbox`) is the unified command-line interface for managing your Oracle Sandbox environment — APEX, ORDS, MCP, database connections, logs, and metrics — from a single entrypoint.

```bash
sandbox <action> <resource> [parameters]
sandbox <action> -h | --help
sandbox help search <keyword>
```

All commands are also accessible through short aliases (`sb`, `sr`, `sc`, etc.) and support `--format json|csv|table` output for scripting.

<br>

## Quick Start

### Step 1: Enter the container

```bash
docker compose exec -it sandbox-oracle-server bash
```

### Step 2: Try these commands

```bash
sandbox status all          # Health of all services
sandbox status database     # Oracle database only
sandbox status apex         # APEX / ORDS only

sandbox run sqlcl           # Open interactive SQLcl session
sandbox run healthcheck     # Run full health verification

sandbox conn list           # List saved database connections
sandbox logs apex           # View APEX installation log
sandbox logs ords           # View ORDS runtime log

sandbox install apex        # Install Oracle APEX + ORDS
sandbox start apex          # Start ORDS/APEX service
sandbox stop apex           # Stop ORDS/APEX service
```

### Step 3: Get help anytime

```bash
sandbox help                        # All actions and resources
sandbox run -h                      # Help for the run action
sandbox conn add -h                 # Help for conn add
sandbox help search connection      # Keyword search
```

<br>

## Syntax

```
sandbox <action> <resource> [parameters]
        [--dry-run] [--quiet|-q] [--verbose]
```

| Part | Description |
|------|-------------|
| `action` | What to do: `run`, `status`, `conn`, `logs`, `start`, `stop`, `restart`, `install`, `uninstall`, `download`, `monitor`, `audit`, `template`, `batch`, `export`, `import`, `help` |
| `resource` | What to act on (depends on action; see each section below) |
| `parameters` | Flags specific to the action/resource combination |

**Resource is optional** for: `status`, `monitor`, `audit`, `template`, `batch`, `export`, `import` — omitting it shows an interactive selection menu.

<br>

## Global Flags

These flags work with every action and must appear anywhere in the command:

| Flag | Effect |
|------|--------|
| `--dry-run` | Preview what would happen without making any changes |
| `--quiet` / `-q` | Suppress banner; output only essential info (auto-enabled for `--format json|csv`) |
| `--verbose` | Show extra diagnostic output |

```bash
sandbox conn add --name myconn --user system --dry-run   # Preview only
sandbox status all --quiet                                # No banner
sandbox batch execute --file setup.txt --dry-run          # Preview batch
```

<br>

## Command Reference

---

### `run` — Execute Tools

```
sandbox run <resource> [parameters]
```

| Resource | Purpose | Notes |
|----------|---------|-------|
| `sqlcl` | Open interactive SQLcl session | Prompts for user if `--user` omitted |
| `mcp` | Launch MCP server (foreground) | Runs until Ctrl-C |
| `healthcheck` | Run full sandbox health checks | Checks DB, APEX, ORDS, network |
| `monitor` | Run a SQL monitoring script | Requires a script name as argument |

#### `run sqlcl`

```bash
sandbox run sqlcl -u system            # Connect as SYSTEM
sandbox run sqlcl -u sys               # Connect as SYS (sysdba)
sandbox run sqlcl -u demasy            # Connect as DEMASY schema user
sandbox run sqlcl -u demasy_ai         # Connect as AI/MCP user
sandbox run sqlcl -u sandbox           # Connect as SANDBOX schema user
sandbox run sqlcl -u sandbox_ai        # Connect as SANDBOX_AI user
sandbox run sqlcl -u system --pdb MYPDB  # Override PDB
```

Valid users: `sys` `system` `sandbox` `sandbox_ai` `demasy` `demasy_ai`

| Flag | Default | Description |
|------|---------|-------------|
| `-u` / `--user` | _(interactive menu)_ | Database user to connect as |
| `-p` / `--pass` | env password | Password override |
| `--pdb` | service default per user | PDB/service name override |

#### `run monitor`

```bash
sandbox run monitor                         # List available monitoring scripts
sandbox run monitor active-connections      # Run a specific monitoring script
sandbox run monitor tablespace-usage
sandbox run monitor top-queries-cpu
```

Scripts are SQL files located at `/usr/sandbox/app/oracle/admin/monitoring/`.

---

### `status` — Check Health

```
sandbox status [resource] [--format table|json|csv]
```

| Resource | What it checks |
|----------|---------------|
| `database` | DB port reachability, SQL ping, open PDBs |
| `apex` | ORDS process (PID), HTTP endpoint response |
| `mcp` | MCP process status and active connection name |
| `network` | Docker bridge, subnet, gateway, container IPs |
| `all` | All of the above in one output |

```bash
sandbox status database                    # Database only
sandbox status apex                        # APEX/ORDS only
sandbox status mcp                         # MCP server only
sandbox status network                     # Docker network
sandbox status all                         # Everything
sandbox status all --format json           # JSON output for scripting
sandbox status all --format csv            # CSV output
```

When no resource is given, an interactive menu appears.

---

### `conn` — Manage Connections

```
sandbox conn <resource> [parameters]
```

| Resource | Purpose |
|----------|---------|
| `list` | Show all saved SQLcl connections |
| `add` | Create a new saved connection |
| `delete` | Remove a saved connection |
| `rename` | Rename an existing connection |
| `test` | Verify a connection works |

#### `conn list`

```bash
sandbox conn list
sandbox conn list --format json
sandbox conn list --format csv
```

#### `conn add`

```bash
sandbox conn add --name myconn --user system
sandbox conn add --name dev-conn --user demasy --pdb FREEPDB1
sandbox conn add --name ai-conn --user demasy_ai --host 192.168.1.10 --port 1521 --pdb FREEPDB1 --pass mypassword
```

| Flag | Required | Description |
|------|----------|-------------|
| `--name` / `-n` | Yes | Connection name |
| `--user` / `-u` | Yes | Database user |
| `--pass` / `-p` | No | Password (defaults to env password) |
| `--host` | No | Hostname (default: `sandbox-oracle-database`) |
| `--port` | No | Port (default: `1521`) |
| `--pdb` | No | PDB / service name (default: `FREEPDB1`) |

#### `conn delete`

```bash
sandbox conn delete --name myconn
```

#### `conn rename`

```bash
sandbox conn rename --from old-name --to new-name
```

| Flag | Description |
|------|-------------|
| `--from` / `-f` | Current connection name |
| `--to` / `-t` | New connection name |

#### `conn test`

```bash
sandbox conn test --name myconn
```

Runs `SELECT 'OK' FROM DUAL` through the saved connection and reports pass/fail.

---

### `logs` — View Logs

```
sandbox logs <resource> [-f] [-n <lines>]
```

| Resource | Log files shown |
|----------|----------------|
| `apex` | `/tmp/apex_install.log`, `/tmp/apex_rest_config.log` |
| `install` | All APEX + ORDS installation logs |
| `ords` | `/tmp/ords.log` |
| `startup` | `/tmp/auto-user-setup.log` |
| `mcp` | _(MCP writes no log file — use `sandbox run mcp` for live output)_ |
| `all` | All log files combined |

```bash
sandbox logs apex                   # Last 50 lines of APEX install log
sandbox logs ords -f                # Stream ORDS log live (tail -f)
sandbox logs startup -n 100         # Last 100 lines of startup log
sandbox logs all -f                 # Stream all logs multiplexed
```

| Flag | Description |
|------|-------------|
| `-f` / `--follow` | Stream output live (like `tail -f`) |
| `-n` / `--lines` | Number of lines to show (default: 50) |

---

### `start` / `stop` / `restart` — Service Control

```
sandbox start|stop|restart <resource>
```

| Resource | Service |
|----------|---------|
| `apex` | APEX / ORDS service |
| `mcp` | MCP server daemon |

```bash
sandbox start apex
sandbox stop apex
sandbox restart apex
sandbox start mcp
sandbox stop mcp
sandbox restart mcp
```

---

### `install` / `uninstall` / `download`

```
sandbox install apex           # Install Oracle APEX + ORDS inside the container
sandbox uninstall apex         # Remove Oracle APEX from the database
sandbox download apex          # Download APEX installation package
sandbox download ords          # Download ORDS installation package
```

---

### `monitor` — Metrics Dashboard

```
sandbox monitor [resource] [--export prometheus|grafana|json]
```

| Resource | Metrics collected |
|----------|-----------------|
| `system` | CPU, memory, disk, uptime |
| `database` | Active connections, transactions |
| `apex` | ORDS response time, request count |
| `all` | All of the above |

```bash
sandbox monitor                         # Interactive resource selection
sandbox monitor system                  # System metrics table
sandbox monitor database                # Database metrics table
sandbox monitor all                     # Full dashboard
sandbox monitor all --export json       # JSON (Grafana-compatible)
sandbox monitor all --export prometheus # Prometheus text format
sandbox monitor --menu                  # Force interactive menu
```

---

### `audit` — Operation History

```
sandbox audit [resource] [parameters]
```

| Resource | Purpose |
|----------|---------|
| `list` | Show recent audit log entries |
| `show` | Show detail for a specific entry |
| `search` | Filter audit log by keyword |
| `export` | Export audit log |
| `stats` | Audit statistics summary |
| `rollback` | Attempt rollback of a logged operation |

```bash
sandbox audit list
sandbox audit list --limit 100
sandbox audit search --filter "conn"
sandbox audit show --id <entry-id>
sandbox audit export
sandbox audit stats
sandbox audit rollback --id <entry-id>
```

Audit entries are stored in `/tmp/sandbox_audit/` as JSON files with action, resource, user, timestamp, and rollback command.

---

### `template` — Configuration Snapshots

```
sandbox template [resource] [parameters]
```

| Resource | Purpose |
|----------|---------|
| `save` | Save current env/connections as a named template |
| `load` | Restore a previously saved template |
| `list` | List all saved templates |
| `delete` | Remove a template |
| `export` | Export a template to file |
| `import` | Import a template from file |

```bash
sandbox template save --name production
sandbox template load --name production
sandbox template list
sandbox template delete --name staging
sandbox template export --name production > prod.json
sandbox template import --file prod.json
```

Templates are stored in `/tmp/sandbox_templates/` as JSON snapshots of environment variables and connection state.

---

### `batch` — Bulk Operations

```
sandbox batch <resource> --file <path> [--dry-run]
```

| Resource | Purpose |
|----------|---------|
| `execute` | Run a file of sandbox commands line-by-line |
| `apply-connections` | Create multiple connections from a CSV file |
| `apply-commands` | Apply a set of sandbox commands |
| `apply-with-rollback` | Apply commands with rollback support |

#### `batch execute`

Create a plain-text file with one sandbox command per line:

```
# setup.txt
conn list
status database
logs startup
```

```bash
sandbox batch execute --file setup.txt
sandbox batch execute --file setup.txt --dry-run   # Preview only
```

#### `batch apply-connections`

CSV format: `name,user,host,port,pdb,password` (use `-` for optional fields):

```csv
name,user,host,port,pdb,password
dev-conn,system,192.168.1.10,1521,FREEPDB1,-
ai-conn,demasy_ai,-,-,FREEPDB1,mypassword
```

```bash
sandbox batch apply-connections --file connections.csv
sandbox batch apply-connections --file connections.csv --dry-run
```

---

### `export` / `import` — Configuration Backup

```
sandbox export [config|connections|all] [--format json|csv]
sandbox import [config|connections|all] --file <path>
```

| Resource | Content |
|----------|---------|
| `config` | Environment variables and DB connection defaults |
| `connections` | All saved SQLcl connections |
| `all` | Config + connections combined |

```bash
sandbox export config                             # Print config to stdout
sandbox export config > backup.json               # Save to file
sandbox export connections --format csv > conns.csv
sandbox export all > full-backup.json

sandbox import config --file backup.json
sandbox import connections --file conns.json
```

---

### `help` — Discovery

```bash
sandbox help                        # Show all actions and resources
sandbox help search <keyword>       # Keyword search across all commands
sandbox <action> -h                 # Help for a specific action
sandbox <action> <resource> -h      # Help for a specific resource
```

Supported search keywords include: `sql`, `database`, `connection`, `mcp`, `apex`, `ords`, `log`, `monitor`, `install`, `health`, `debug` and more.

```bash
sandbox help search apex
sandbox help search connection
sandbox help search monitor
sandbox conn -h
sandbox run sqlcl -h
```

<br>

## Output Formats

All commands that produce data support `--format`:

| Format | Use case | Flag |
|--------|----------|------|
| `table` | Human-readable (default) | `--format table` |
| `json` | Scripting / automation | `--format json` |
| `csv` | Spreadsheet import | `--format csv` |

```bash
sandbox status all --format json
sandbox conn list --format csv
sandbox monitor all --export prometheus   # monitor uses --export instead
```

Banner is automatically suppressed for `json` and `csv` formats. Use `--quiet` to suppress it for any format.

```bash
# Parse with jq
sandbox status all --format json | jq '.database.port_status'

# Save and import CSV
sandbox conn list --format csv > connections.csv
```

<br>

## Aliases & Shortcuts

Source the aliases file in your shell profile:

```bash
# Add to ~/.bashrc or ~/.zshrc:
[[ -f /usr/sandbox/app/cli/sandbox-aliases.sh ]] && source /usr/sandbox/app/cli/sandbox-aliases.sh
```

### Core aliases

| Alias | Expands to |
|-------|------------|
| `sb` | `sandbox` |
| `sr` | `sandbox run` |
| `sc` | `sandbox conn` |
| `sl` | `sandbox logs` |
| `ss` | `sandbox status` |
| `si` | `sandbox install` |
| `sk` | `sandbox start` |
| `sp` | `sandbox stop` |
| `sx` | `sandbox restart` |
| `sdownload` | `sandbox download` |
| `suninstall` | `sandbox uninstall` |

### Status shortcuts

| Alias | Expands to |
|-------|------------|
| `ssd` | `sandbox status database` |
| `ssa` | `sandbox status apex` |
| `ssm` | `sandbox status mcp` |

### Log shortcuts

| Alias | Expands to |
|-------|------------|
| `slapex` | `sandbox logs apex` |
| `slords` | `sandbox logs ords` |
| `slall` | `sandbox logs all` |

### Monitor shortcuts

| Alias | Expands to |
|-------|------------|
| `sm` | `sandbox run monitor` |
| `sma` | `sandbox run monitor active-connections` |
| `smd` | `sandbox run monitor database-size` |
| `smt` | `sandbox run monitor tablespace-usage` |
| `smq` | `sandbox run monitor top-queries-cpu` |
| `sml` | `sandbox run monitor archive-log-status` |

### Usage examples

```bash
ss all              # sandbox status all
sr sqlcl -u system  # sandbox run sqlcl -u system
sc list             # sandbox conn list
sl apex -f          # sandbox logs apex --follow
sk apex             # sandbox start apex
ssd                 # sandbox status database
sma                 # sandbox run monitor active-connections
```

<br>

## Tab Completion

Completion scripts are provided for both bash and zsh:

```bash
# Bash — add to ~/.bashrc:
[[ -f /usr/sandbox/app/cli/sandbox-completion.bash ]] && source /usr/sandbox/app/cli/sandbox-completion.bash

# Zsh — add to ~/.zshrc:
[[ -f /usr/sandbox/app/cli/sandbox-completion.zsh ]] && source /usr/sandbox/app/cli/sandbox-completion.zsh
```

Tab completion covers actions, resources, and flags:

```
sandbox [TAB]           →  run  status  conn  logs  start  stop  ...
sandbox run [TAB]       →  sqlcl  mcp  healthcheck  monitor
sandbox conn [TAB]      →  list  add  delete  rename  test
sandbox status [TAB]    →  database  apex  mcp  network  all
sandbox logs [TAB]      →  apex  install  ords  startup  mcp  all
```

<br>

## Real-World Workflows

### Daily health check

```bash
sandbox status all

# Or individual checks:
ssd         # database
ssa         # APEX/ORDS
ssm         # MCP
```

### Tail APEX install log in real time

```bash
sandbox logs apex -f
# or from outside the container:
docker exec sandbox-oracle-server tail -f /tmp/apex_install.log
```

### Connect to the database and run SQL

```bash
sandbox run sqlcl -u system
# Inside SQLcl:
SQL> SELECT banner FROM v$version;
SQL> SELECT name, open_mode FROM v$pdbs;
SQL> EXIT
```

### Add and test a connection

```bash
sandbox conn add --name ai-conn --user demasy_ai --pdb FREEPDB1
sandbox conn test --name ai-conn
sandbox conn list
```

### Batch-create connections from CSV

```bash
cat > conns.csv << 'EOF'
name,user,host,port,pdb,password
dev-sys,system,-,-,FREEPDB1,-
dev-ai,demasy_ai,-,-,FREEPDB1,-
EOF
sandbox batch apply-connections --file conns.csv --dry-run
sandbox batch apply-connections --file conns.csv
```

### Export and restore configuration

```bash
# Export
sandbox export all > backup-$(date +%Y%m%d).json

# Restore on another sandbox
sandbox import config --file backup-20260617.json
sandbox import connections --file backup-20260617.json
```

### Save and reuse a configuration template

```bash
sandbox template save --name dev-env
# ... make changes ...
sandbox template load --name dev-env     # Restore
sandbox template list
```

### Machine-readable monitoring for CI

```bash
# JSON for parsing
sandbox status all --format json | jq '.database.port_status'
sandbox monitor all --export json

# Prometheus scrape endpoint simulation
sandbox monitor all --export prometheus
```

<br>

## Troubleshooting

### `sb`: command not found

```bash
# Reload aliases
source /usr/sandbox/app/cli/sandbox-aliases.sh

# Or use the full command
sandbox status all
```

### `sandbox`: command not found

```bash
# Confirm you are inside the container
docker compose exec -it sandbox-oracle-server bash

# Check the binary is in PATH
which sandbox
ls /usr/sandbox/app/cli/sandbox.sh
```

### Tab completion does nothing

```bash
# Verify function is loaded
declare -f _sandbox_completion

# Load manually if needed
source /usr/sandbox/app/cli/sandbox-completion.bash

# Check registration
complete -p sandbox
```

### `--format json` produces a table instead

```bash
# Flag must come after the resource
sandbox status all --format json    # correct
sandbox --format json status all    # wrong — flag is ignored

# Banner suppression is automatic for json/csv; use --quiet if still showing
sandbox status all --format json --quiet
```

### Connection not found after `conn add`

```bash
# Verify it was saved
sandbox conn list

# If empty, SQLcl may have reported an error — run manually to see output
/opt/oracle/sqlcl/bin/sql /nolog <<EOF
CONN -save "myconn" -savepwd system/password@//sandbox-oracle-database:1521/FREEPDB1
EXIT
EOF
```

### APEX/ORDS not responding

```bash
sandbox status apex             # Check process and HTTP status
sandbox logs ords -f            # Watch ORDS runtime log
sandbox restart apex            # Restart ORDS
sandbox logs install            # Check if installation completed successfully
```

### Batch file runs but shows no output

```bash
sandbox batch execute --file commands.txt --dry-run     # Preview
sandbox batch execute --file commands.txt --verbose     # Verbose mode
bash -x /usr/sandbox/app/cli/sandbox.sh batch execute --file commands.txt
```

<br>

---

<div align="center">

For more, see [README.md](../README.md) or open an issue on GitHub.

</div>
