# 📋 Sandbox CLI User Guide

<div align="center">

**Complete reference for the Sandbox Command-Line Interface (CLI)**

Master the unified command-line toolkit for managing Oracle Sandbox operations, connections, and configurations.

[Quick Start](#quick-start-5-minutes) • [Beginner Guide](#beginner-guide) • [Advanced Features](#advanced-features) • [Reference](#quick-command-reference) • [Troubleshooting](#troubleshooting)

</div>

<br>

## 📑 Table of Contents

1. [Overview](#overview)
2. [Quick Start (5 minutes)](#quick-start-5-minutes)
3. [Beginner Guide](#beginner-guide)
   - [Phase 1: Aliases & Shortcuts](#phase-1-aliases--shortcuts)
   - [Phase 2: Help System](#phase-2-help-system)
   - [Phase 3: Common Commands](#phase-3-common-commands)
4. [Advanced Features](#advanced-features)
   - [Phase 4: Output Formatting](#phase-4-output-formatting)
   - [Phase 5: Batch Operations & State Diff](#phase-5-batch-operations--state-diff)
   - [Phase 6: Interactive Shell & Completions](#phase-6-interactive-shell--completions)
5. [Quick Command Reference](#quick-command-reference)
6. [Real-World Workflows](#real-world-workflows)
7. [Troubleshooting](#troubleshooting)
8. [Getting Help](#getting-help)

<br>

## Overview

The **Sandbox CLI** is a unified command-line toolkit that simplifies all aspects of managing your Oracle Sandbox environment. Instead of remembering complex Docker commands, you can use simple, intuitive commands:

```bash
sb status          # Check health of all services
sb shell          # Enter interactive mode
sb help           # Get help on any command
```

### Key Features

| Feature | What It Does |
|---------|-------------|
| **Unified Interface** | One command (`sandbox`) for all operations |
| **Smart Aliases** | 20+ shortcuts (sb, sr, sc, sl, etc.) |
| **3-Level Help** | Top-level, action-level, resource-level help |
| **Multiple Formats** | JSON, CSV, table, or quiet modes |
| **Batch Operations** | Run multiple commands reliably |
| **Configuration Export** | Backup and restore setups |
| **State Comparison** | Audit and compare configurations |
| **Interactive Shell** | REPL mode with history and auto-completion |
| **Tab Completion** | Smart suggestions for bash/zsh |

### Architecture: 6 Phases

| Phase | Purpose | Benefit |
|-------|---------|---------|
| **Phase 1** | Aliases & Config | Reduce typing with 20+ shortcuts |
| **Phase 2** | Help & Discovery | Learn features via hierarchical help |
| **Phase 3** | Code Libraries | 30% code reduction, maintainability |
| **Phase 4** | Output Formatting | JSON/CSV/table support |
| **Phase 5** | Batch & Diff | Automation and audit trails |
| **Phase 6** | Shell & Completions | Interactive mode with history |

<br>

## Quick Start (5 minutes)

### Step 1: Access the Container

```bash
cd /path/to/oracle-sandbox
docker compose exec -it sandbox-oracle-server bash
```

### Step 2: Try These Commands

```bash
# Check health of all services
sb status

# See all available commands
sb help

# Enter interactive shell mode
sb shell

# List saved database connections
sb conn list

# View database logs
sb logs database
```

### Step 3: Get Help Anytime

```bash
# Help on specific topic
sb help search database

# Help for specific action
sb run help

# Full help with all commands
sb help
```

**That's it!** You now have access to all sandbox management tools.

<br>

## Beginner Guide

### Phase 1: Aliases & Shortcuts

Typing `sandbox` every time is tedious. That's why we have shortcuts:

#### Common Aliases

| Shortcut | Full Command | Purpose |
|----------|--------------|---------|
| `sb` | `sandbox` | Main CLI dispatcher |
| `sr` | `sandbox run` | Run tools (sqlcl, sqlplus, monitor) |
| `sc` | `sandbox conn` | Manage database connections |
| `sl` | `sandbox logs` | View service logs |
| `ss` | `sandbox status` | Check service status |
| `si` | `sandbox import` | Import configurations |
| `sk` | `sandbox kill` | Stop services |
| `sp` | `sandbox install` | Install components (APEX) |
| `sx` | `sandbox export` | Export configurations |

#### Using Aliases

Instead of:
```bash
sandbox run sqlcl
sandbox status all
sandbox conn list
```

Simply type:
```bash
sr sqlcl          # Much shorter!
ss all
sc list
```

#### See All Aliases

```bash
# View all available aliases
alias | grep -E '^alias (sb|sr|sc|sl|ss)='

# Or enable alias expansion
shopt -s expand_aliases
```

---

### Phase 2: Help System

The CLI has a **3-level help hierarchy** to help you discover features:

#### Level 1: Top-Level Help

See all actions and resources:

```bash
sb help
```

**Output shows:**
- All available actions (run, status, conn, logs, export, import, batch, etc.)
- All available resources per action
- Beautiful Demasy Labs banner

#### Level 2: Action-Level Help

Get help for a specific action:

```bash
sb run help           # Help for "run" action
sb conn help          # Help for "conn" action
sb logs help          # Help for "logs" action
```

#### Level 3: Keyword Search

Find commands by keyword:

```bash
# Search for database-related commands
sb help search database

# Search for monitoring commands
sb help search monitor

# Search for connection commands
sb help search connection
```

#### Examples

```bash
# Beginner: Explore what's available
sb help

# Intermediate: Find connection-related commands
sb help search connection

# Advanced: Get help for specific action
sb run help
sb status help
```

---

### Phase 3: Common Commands

Let's go through the most frequently used commands:

#### 1. Check Status

```bash
# Status of all services
sb status all

# Status of specific service
sb status database      # Oracle database
sb status apex          # APEX and ORDS
sb status mcp           # MCP connection
```

#### 2. Run Database Tools

```bash
# Connect with SQLcl
sb run sqlcl

# Run monitoring script
sb run monitor active-connections

# Run health check
sb run healthcheck
```

**Inside SQLcl:**
```sql
-- You can now run SQL
SELECT user FROM dual;
SELECT * FROM v$database;
EXIT;
```

#### 3. Manage Connections

```bash
# List saved connections
sb conn list

# Test a connection
sb conn test sandbox-ai-conn

# View connection details
sb conn describe sandbox-ai-conn
```

#### 4. View Logs

```bash
# Database logs
sb logs database

# APEX installation logs
sb logs apex

# All available logs
sb logs help
```

#### 5. Install Components

```bash
# Install APEX and ORDS
sb install apex

# Reinstall if needed
sb install apex --force
```

<br>

## Advanced Features

### Phase 4: Output Formatting

By default, CLI shows human-readable output (table format). But you can change it for different purposes:

#### Supported Formats

| Format | Use Case | Example |
|--------|----------|---------|
| `table` | Human reading (default) | `sb status all` |
| `json` | Automation, scripting | `sb status all --format json` |
| `csv` | Spreadsheet import | `sb status all --format csv` |
| `quiet` | Scripts, suppress banner | `sb status all --quiet` |

#### Table Format (Human-Readable)

```bash
sb status all
```

**Output:**
```
╔════════════════════════════════════════╗
║        DEMASY LABS SANDBOX CLI         ║
╚════════════════════════════════════════╝

Service Status:
┌─────────────────┬──────────┐
│ Service         │ Status   │
├─────────────────┼──────────┤
│ Oracle Database │ ✓ Healthy│
│ Management      │ ✓ Healthy│
│ APEX/ORDS       │ ✓ Running│
└─────────────────┴──────────┘
```

#### JSON Format (Automation)

```bash
sb status all --format json
```

**Output:**
```json
{
  "timestamp": "2026-06-24T10:15:30Z",
  "status": "healthy",
  "services": {
    "database": { "status": "healthy", "uptime_seconds": 3600 },
    "apex": { "status": "running", "port": 8080 }
  }
}
```

**Parse with jq:**
```bash
# Get just the database status
sb status all --format json | jq '.services.database.status'

# Extract specific value
sb status all --format json | jq '.services[].status'
```

#### CSV Format (Spreadsheets)

```bash
sb conn list --format csv
```

**Output:**
```csv
name,user,service,host,port
sandbox-ai-conn,SANDBOX_AI,SANDBOX_PDB,192.168.1.110,1521
```

**Import to spreadsheet:**
```bash
sb conn list --format csv > connections.csv
# Now open connections.csv in Excel/Google Sheets
```

#### Quiet Format (Scripts)

```bash
# Suppress banner, show only essential info
sb status all --quiet
```

Useful when CLI output is piped to other commands or scripts.

---

### Phase 5: Batch Operations & State Diff

For automation and configuration management:

#### 5A. Batch Execution

Run multiple commands from a file:

**Create commands.txt:**
```bash
cat > commands.txt << 'EOF'
status all
conn list
logs database
EOF
```

**Execute batch:**
```bash
sb batch execute --file commands.txt
```

**Dry-run (preview without executing):**
```bash
sb batch execute --file commands.txt --dry-run
```

#### 5B. Configuration Export/Import

**Export current configuration:**
```bash
sb export config > sandbox-backup.json
```

**Import configuration to another sandbox:**
```bash
sb import config sandbox-backup.json
```

**Export state (detailed snapshot):**
```bash
sb export state > state-2026-06-24.json
```

#### 5C. State Diff (Compare Configurations)

Compare two configurations to see what changed:

```bash
# Compare before and after
sb diff state before.json after.json

# Text format (unified diff)
sb diff state before.json after.json --format text

# JSON format (side-by-side)
sb diff state before.json after.json --format json
```

**Real-world example:**
```bash
# Backup state before changes
sb export state > state-before.json

# Make some changes...
# (install APEX, add connections, etc.)

# See what changed
sb diff state state-before.json state-after.json --format text
```

---

### Phase 6: Interactive Shell & Completions

#### Interactive Shell Mode

Enter an interactive REPL (Read-Eval-Print Loop):

```bash
sb shell
```

**Inside the shell:**
```
sandbox> help
Available commands:
  help           - Show this help message
  history        - View command history
  history clear  - Clear history
  history search <keyword> - Search history
  quit / exit    - Exit shell

sandbox> status all
[Status output]

sandbox> conn list
[Connections]

sandbox> help search database
[Search results]

sandbox> exit
```

#### Command History

```bash
# View command history
sandbox> history

# Search history
sandbox> history search status

# Clear history
sandbox> history clear

# History file location
# ~/.sandbox_history
```

#### Tab Completion (Bash/Zsh)

**Dynamic action suggestions:**
```bash
sb [TAB]  →  Shows: run, status, conn, logs, export, import, batch, etc.
```

**Dynamic resource suggestions:**
```bash
sb run [TAB]  →  Shows: sqlcl, sqlplus, monitor, healthcheck
```

**Flag suggestions:**
```bash
sb status [TAB]  →  Shows: --format, --help, --quiet, --dry-run
```

**Set up completions (already enabled):**
```bash
# Bash
source ~/.bashrc

# Zsh
source ~/.zshrc
```

<br>

## Quick Command Reference

### All CLI Commands by Action

#### 🏃 `run` — Execute Tools

| Resource | Purpose | Example |
|----------|---------|---------|
| `sqlcl` | Connect with SQLcl | `sb run sqlcl` |
| `sqlplus` | Connect with SQL*Plus | `sb run sqlplus system@FREEPDB1` |
| `monitor` | Run monitoring scripts | `sb run monitor active-connections` |
| `healthcheck` | System diagnostics | `sb run healthcheck` |

#### 📊 `status` — Check Health

| Resource | Purpose | Example |
|----------|---------|---------|
| `all` | All services | `sb status all` |
| `database` | Oracle Database | `sb status database` |
| `apex` | APEX/ORDS | `sb status apex` |
| `mcp` | MCP connection | `sb status mcp` |

#### 🔌 `conn` — Manage Connections

| Resource | Purpose | Example |
|----------|---------|---------|
| `list` | List connections | `sb conn list` |
| `test` | Test connection | `sb conn test sandbox-ai-conn` |
| `describe` | Connection details | `sb conn describe sandbox-ai-conn` |
| `add` | Add new connection | `sb conn add --name myconn --user user` |
| `delete` | Delete connection | `sb conn delete myconn` |

#### 📜 `logs` — View Service Logs

| Resource | Purpose | Example |
|----------|---------|---------|
| `database` | Database logs | `sb logs database` |
| `apex` | APEX logs | `sb logs apex` |
| `ords` | ORDS logs | `sb logs ords` |
| `startup` | Startup logs | `sb logs startup` |
| `mcp` | MCP logs | `sb logs mcp` |
| `all` | All logs | `sb logs all` |

#### 💾 `export` — Save Configuration

| Resource | Purpose | Example |
|----------|---------|---------|
| `config` | Full configuration | `sb export config > config.json` |
| `state` | Detailed state snapshot | `sb export state > state.json` |
| `connections` | Connection list | `sb export connections > conns.json` |

#### 📥 `import` — Load Configuration

| Resource | Purpose | Example |
|----------|---------|---------|
| `config` | Load configuration | `sb import config config.json` |
| `connections` | Load connections | `sb import connections conns.json` |

#### ⚙️ `batch` — Bulk Operations

| Resource | Purpose | Example |
|----------|---------|---------|
| `execute` | Run commands from file | `sb batch execute --file commands.txt` |

#### 📈 `monitor` — System Monitoring

| Resource | Purpose | Example |
|----------|---------|---------|
| `system` | System resources | `sb monitor system` |
| `database` | Database metrics | `sb monitor database` |
| `apex` | APEX status | `sb monitor apex` |

#### 🔍 `diff` — Compare State

| Resource | Purpose | Example |
|----------|---------|---------|
| `state` | Compare configurations | `sb diff state before.json after.json` |

#### 📥 `install` — Install Components

| Resource | Purpose | Example |
|----------|---------|---------|
| `apex` | Install APEX/ORDS | `sb install apex` |

#### ❓ `help` — Get Help

| Resource | Purpose | Example |
|----------|---------|---------|
| (no arg) | Show all help | `sb help` |
| `search KEYWORD` | Keyword search | `sb help search database` |
| `ACTION` | Help for action | `sb run help` |

#### 🎛️ `shell` — Interactive Mode

| Command | Purpose | Example |
|---------|---------|---------|
| (no arg) | Enter shell | `sb shell` |

<br>

## Real-World Workflows

### Workflow 1: Daily Health Check

**Goal**: Quickly verify all services are healthy

```bash
# Option A: Simple status check
sb status all

# Option B: JSON output for monitoring systems
sb status all --format json | jq '.services[] | {name: .name, status: .status}'

# Option C: Detailed inspection
sb shell
  > status all
  > logs database | tail -20
  > exit
```

---

### Workflow 2: Backup Before Changes

**Goal**: Save current configuration before making changes

```bash
# Export everything
sb export config > backup-$(date +%Y%m%d-%H%M%S).json

# Later: Compare what changed
sb export state > state-after.json
sb diff state backup-state.json state-after.json --format text
```

---

### Workflow 3: Setup Reproducible Environment

**Goal**: Apply same configuration to multiple sandboxes

```bash
# On Sandbox A: Export configuration
sb export config > my-setup.json

# On Sandbox B: Import configuration
sb import config my-setup.json

# Verify
sb status all
```

---

### Workflow 4: Interactive Exploration

**Goal**: Explore database without remembering all commands

```bash
# Enter shell
sb shell

# Inside shell:
sandbox> help              # See what's available
sandbox> help search table # Find table-related commands
sandbox> status all        # Check health
sandbox> conn list         # See connections
sandbox> run sqlcl         # Connect to database
  SQL> SELECT * FROM tab;
  SQL> EXIT;
sandbox> logs database     # Check for errors
sandbox> exit
```

---

### Workflow 5: Batch Database Setup

**Goal**: Run multiple setup commands reliably

**Create setup.txt:**
```bash
cat > setup.txt << 'EOF'
status all
conn test sandbox-ai-conn
export config
logs startup
EOF
```

**Execute:**
```bash
# Dry run first (see what will happen)
sb batch execute --file setup.txt --dry-run

# Actual execution
sb batch execute --file setup.txt

# With specific format
sb batch execute --file setup.txt --format json
```

---

### Workflow 6: Compare Environments

**Goal**: See differences between dev and production setups

```bash
# On DEV sandbox: Export state
sb export state > dev-state.json

# On PROD sandbox: Export state
sb export state > prod-state.json

# Compare (can run on either sandbox)
sb diff state dev-state.json prod-state.json --format text

# Output shows what differs
```

<br>

## Troubleshooting

### Issue 1: Aliases Not Working

**Symptom**: `sb: command not found`

**Solution:**
```bash
# Reload shell configuration
source ~/.bashrc        # Bash
# or
source ~/.zshrc         # Zsh

# Or restart terminal
```

---

### Issue 2: Tab Completion Not Working

**Symptom**: Pressing TAB doesn't show suggestions

**Solution:**
```bash
# Ensure completion files are sourced
# Check if in ~/.bashrc or ~/.zshrc:
[[ -f /usr/sandbox/app/cli/sandbox-completion.bash ]] && source /usr/sandbox/app/cli/sandbox-completion.bash

# Restart your terminal or:
exec $SHELL
```

---

### Issue 3: `sandbox` Command Not Found

**Symptom**: Error when running `sb` or `sandbox`

**Solution:**
```bash
# Ensure you're in the container
docker compose ps                                    # Check if running
docker compose exec -it sandbox-oracle-server bash  # Enter container

# Inside container:
which sandbox
ls -la /usr/sandbox/app/cli/sandbox.sh

# If not found, rebuild
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

---

### Issue 4: Shell History Not Persisting

**Symptom**: Command history lost after exiting shell

**Solution:**
```bash
# Check history file permissions
ls -la ~/.sandbox_history

# Fix permissions if needed
chmod 600 ~/.sandbox_history

# Recreate if missing
touch ~/.sandbox_history
chmod 600 ~/.sandbox_history
```

---

### Issue 5: Help System Returns Empty Results

**Symptom**: `sb help` shows nothing or errors

**Solution:**
```bash
# Check help file
cat /usr/sandbox/app/cli/sandbox-help.sh | head -20

# Try with verbose output
bash -x /usr/sandbox/app/cli/sandbox.sh help 2>&1 | head -50

# Check for file corruptions
ls -la /usr/sandbox/app/cli/sandbox-*.sh
```

---

### Issue 6: Output Not Formatting Correctly

**Symptom**: `--format json` returns table, not JSON

**Solution:**
```bash
# Verify format is supported for that action
sb status help

# Try explicit flag placement
sb status all --format json

# Not this:
sb --format json status all

# If still failing, check format file
cat /usr/sandbox/app/cli/sandbox-format.sh | head -30
```

---

### Issue 7: Batch Operations Failing Silently

**Symptom**: `sb batch execute` runs but shows no output

**Solution:**
```bash
# Use verbose/debug mode
bash -x /usr/sandbox/app/cli/sandbox.sh batch execute --file commands.txt

# Check batch file format (each command on new line)
cat commands.txt

# Try dry-run first
sb batch execute --file commands.txt --dry-run

# Check logs for errors
sb logs startup
```

---

### Issue 8: Tab Completion Shows Nothing

**Symptom**: Pressing TAB shows no suggestions

**Solution:**
```bash
# Ensure completion function is loaded
declare -f _sandbox_completion  # Should show function

# If not loaded, manually source
source /usr/sandbox/app/cli/sandbox-completion.bash  # Bash
# or
source /usr/sandbox/app/cli/sandbox-completion.zsh   # Zsh

# Check if completion is registered
complete -p sandbox

# If not, register manually (bash)
complete -o bashdefault -o default -F _sandbox_completion sandbox sb
```

<br>

## Getting Help

### In Container

```bash
# Built-in help
sb help                    # All commands
sb help search KEYWORD     # Keyword search
sb ACTION help             # Help for action

# Examples
sb help search monitor
sb run help
sb conn help
```

### Outside Container

```bash
# Documentation
cat docs/SANDBOX_CLI_USER_GUIDE.md         # This file
cat docs/oracle-apex-installation.md       # APEX-specific
cat docs/troubleshooting.md                # General troubleshooting

# GitHub
https://github.com/demasy/oracle-sandbox/issues  # Report issues
https://github.com/demasy/oracle-sandbox         # View code
```

### Still Stuck?

```bash
# Create a test case
docker compose exec -T sandbox-oracle-server bash << 'EOF'
echo "=== Sandbox CLI Version ==="
sb --version 2>/dev/null || echo "No version flag"

echo "=== Help Output ==="
sb help

echo "=== Status ==="
sb status all

echo "=== Aliases ==="
alias | grep -E '^alias (sb|sr|sc|sl|ss)='
EOF

# Share output with the team
# Email to founder@demasy.io or GitHub issue
```

<br>

---

<div align="center">

**Happy CLI-ing!** 🚀

For more information, see [README.md](../README.md) or the [docs/](../docs) folder.

</div>
