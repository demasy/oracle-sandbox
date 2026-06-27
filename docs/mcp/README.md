# MCP Integration Guide

Oracle Sandbox exposes a **Model Context Protocol (MCP) server** powered by SQLcl. This lets AI assistants (Claude, GitHub Copilot, etc.) query Oracle Database 26ai directly through natural language — no separate driver or connection setup required.

---

## How it works

```
AI Assistant (Claude / Copilot)
        │
        │  stdio (MCP protocol)
        ▼
docker exec -i sandbox-oracle-server start-mcp
        │
        ▼
SQLcl  --mcp  (inside container)
        │
        ▼
sandbox_ai @ sandbox-oracle-database:1521/SANDBOX_PDB
        │
        ▼
Oracle AI Database 26ai Free
```

The MCP server runs inside the `sandbox-oracle-server` container using SQLcl's built-in `--mcp` flag. Communication between the AI assistant and the server is over **stdio** — no network port required from the host.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Container running | `docker compose up -d` — both containers must be healthy |
| `.mcp.json` present | Already included in the workspace root |
| MCP-capable client | Claude Desktop, VS Code with GitHub Copilot, or any MCP client |
| APEX/ORDS optional | MCP works independently of APEX installation |

---

## Configuration

The `.mcp.json` file in the workspace root is pre-configured:

```json
{
  "mcpServers": {
    "sandbox-sqlcl-mcp": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "sandbox-oracle-server",
        "start-mcp"
      ]
    }
  }
}
```

No manual edits are needed. The `start-mcp` command is a script deployed inside the container that invokes `sql -mcp` with the correct connection details.

---

## Setup in VS Code (GitHub Copilot)

1. Open **Command Palette** (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Type `MCP` → select **MCP: List Servers**
3. Locate `sandbox-sqlcl-mcp` — status should show **Running**
4. If not running: select **MCP: Restart MCP Server** → choose `sandbox-sqlcl-mcp`

### Verify from the CLI

```bash
docker exec -i sandbox-oracle-server start-mcp --version
```

---

## Setup in Claude Desktop

Add the following to your Claude Desktop `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "oracle-sandbox": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "sandbox-oracle-server",
        "start-mcp"
      ]
    }
  }
}
```

Restart Claude Desktop. The Oracle tools will appear in the tool list.

---

## Available MCP tools

| Tool | Purpose | Example |
|------|---------|---------|
| `connect` | Establish a database session using a saved connection | `connect to sandbox-ai-conn` |
| `run-sql` | Execute a SQL statement | `SELECT table_name FROM user_tables` |
| `run-sqlcl` | Execute a SQLcl command | `DESC employees` |
| `list-connections` | List all saved SQLcl connections | — |

### Example session

```
User: Connect to the database and show me all tables in the SANDBOX schema.

AI  → connect (sandbox-ai-conn)
AI  → run-sql: SELECT table_name FROM user_tables ORDER BY 1
```

```
TABLE_NAME
-----------------------------
CUSTOMERS
ORDERS
PRODUCTS
...
```

---

## Default MCP connection

The MCP server connects as `sandbox_ai` to `SANDBOX_PDB` by default.

| Setting | Default |
|---------|---------|
| Database user | `sandbox_ai` |
| PDB | `SANDBOX_PDB` |
| Saved connection name | `sandbox-ai-conn` |
| DB host (internal) | `sandbox-oracle-database` |
| Port | `1521` |

These are set via environment variables in `docker-compose.yml`:

| Variable | Default | Source |
|----------|---------|--------|
| `SANDBOX_DB_MCP_USER` | `sandbox_ai` | `ENV_DB_MCP_USER` |
| `SANDBOX_DB_MCP_SERVICE` | `SANDBOX_PDB` | `ENV_DB_MCP_SERVICE` |
| `SANDBOX_DB_HOST` | `sandbox-oracle-database` | `ENV_IP_DB_SERVER` |
| `SANDBOX_DB_PORT` | `1521` | `ENV_DB_PORT_LISTENER` |
| `SANDBOX_DB_PASSWORD` | *(from `.env`)* | `ENV_DB_PASSWORD` |

---

## CLI control

Manage the MCP server with the `sb` CLI from inside the container:

```bash
# Start MCP server
sb start mcp

# Stop MCP server
sb stop mcp

# View MCP status
sb status

# Tail MCP logs
sb logs mcp
```

Or from the host:

```bash
docker compose exec sandbox-oracle-server sb start mcp
docker compose exec sandbox-oracle-server sb logs mcp
```

---

## Known behaviors

**`connect` tool may return an error on first call**
This is expected behavior in the upstream SQLcl MCP implementation. The connection is still established — proceed to use `run-sql` normally after the `connect` call.

**Queries run as `sandbox_ai`**
The MCP user has access to `SANDBOX_PDB` only. To query `DEMASY_PDB` or other PDBs, update `ENV_DB_MCP_SERVICE` in your `.env` file and rebuild the container.

**stdin must remain open**
The `docker exec -i` flag is required. Do not replace it with `-it`; the MCP protocol uses stdin/stdout and a TTY allocation will interfere.

---

## Troubleshooting

**MCP server shows "not running" in VS Code**

```bash
# Confirm container is healthy
docker compose ps

# Try the command manually
docker exec -i sandbox-oracle-server start-mcp
```

**`Cannot connect` error when running SQL**

```bash
# Check saved connections exist
docker compose exec -T sandbox-oracle-server bash -c "sb conn list"

# Manually recreate the MCP connection
docker compose exec -T sandbox-oracle-server bash -c \
  "sql /nolog -c 'conn save sandbox-ai-conn sandbox_ai/PASSWORD@//sandbox-oracle-database:1521/SANDBOX_PDB'"
```

**Connection refused (`ORA-12541`)**

The database container may not be ready. Wait for the health check to pass:

```bash
docker compose ps
# sandbox-oracle-database should show (healthy)
```

---

## Related

- [Database Connectivity](../database/connectivity.md) — SQLcl saved connections and connection strings
- [Management API](../api/README.md) — health check endpoint
- [Service Management](../operations/service-management.md) — container and service lifecycle
