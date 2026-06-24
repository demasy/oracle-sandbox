# Frequently Asked Questions

---

## Setup & Getting Started

**Q: Do I need to install Oracle Database separately?**

No. Oracle Database 26ai Free runs inside the `sandbox-oracle-database` container. Everything is pre-configured — just copy `.env.example` to `.env`, set your passwords, and run `docker compose up -d`.

---

**Q: How long does the first startup take?**

The Oracle database takes 5–10 minutes to initialize on first run (it's creating the database files). Subsequent starts take 1–2 minutes. Monitor progress with:
```bash
docker logs -f sandbox-oracle-database
```
Wait for `DATABASE IS READY TO USE!`

---

**Q: Do I need to install APEX manually?**

By default, no — APEX installs automatically on first startup (`ENV_AUTO_INSTALL_APEX_ON_STARTUP=true`). Set it to `false` if you want to control when installation runs, then trigger it manually with:
```bash
sandbox install apex
```

---

**Q: Why is APEX slow on first load?**

APEX loads ~27,000 static image files on the first request. This is normal — subsequent page loads are much faster as files are cached by the browser. If it consistently times out, check ORDS logs: `sandbox logs ords`.

---

## Configuration

**Q: What's the difference between `ENV_APEX_PORT` and `ENV_ORDS_PORT`?**

- `ENV_APEX_PORT` — the **host** port that gets mapped to the container (what you access in your browser, e.g. `http://localhost:8080`)
- `ENV_ORDS_PORT` — the port ORDS listens on **inside** the container (internal use)

They default to the same value (`8080`), but keeping them separate lets you map a different host port without changing ORDS configuration.

---

**Q: How do I change ports if 8080 or 1521 are already in use?**

Edit `.env`:
```bash
ENV_DB_PORT_LISTENER=1522   # Change database port
ENV_APEX_PORT=8081           # Change APEX/ORDS port
```
Then restart: `docker compose down && docker compose up -d`

---

**Q: How do I apply changes to `.env`?**

Runtime variables take effect after a restart:
```bash
docker compose down
docker compose up -d
```

Build-time variables (`ENV_INSTALL_APEX`, download URLs) require a rebuild:
```bash
docker compose build --no-cache
docker compose up -d
```

---

**Q: Can I use a different network subnet?**

Yes — edit `.env`:
```bash
ENV_NETWORK_SUBNET=10.0.1.0/24
ENV_NETWORK_GATEWAY=10.0.1.1
ENV_IP_DB_SERVER=10.0.1.110
ENV_IP_APP_SERVER=10.0.1.120
```
Then recreate containers: `docker compose down && docker compose up -d`

---

## Database & Connections

**Q: Can I connect from SQL Developer / DBeaver / DataGrip on my Mac?**

Yes. The database listens on `localhost:1521`. Use these connection details:
- **Host:** `localhost`
- **Port:** `1521`
- **Service Name:** `FREEPDB1`
- **Username:** `system`
- **Password:** your `ENV_DB_PASSWORD`

---

**Q: What users are available by default?**

| User | Purpose | Connect String |
|------|---------|----------------|
| `system` | DBA access | `system/pwd@localhost:1521/FREEPDB1` |
| `sys` | Full SYSDBA access | `sys/pwd@localhost:1521/FREE as sysdba` |
| `sandbox` | Developer schema | `sandbox/pwd@localhost:1521/FREEPDB1` |
| `sandbox_ai` | MCP / AI queries | `sandbox_ai/pwd@localhost:1521/SANDBOX_PDB` |

---

**Q: How do I add my own PDB?**

```bash
# Connect as SYSDBA and create a new PDB
sandbox run sqlcl -u sys
SQL> CREATE PLUGGABLE DATABASE mypdb ADMIN USER myadmin IDENTIFIED BY mypassword;
SQL> ALTER PLUGGABLE DATABASE mypdb OPEN;
```

---

**Q: How do I reset the database to a clean state?**

```bash
# Stop containers and remove the database volume
docker compose down
docker volume rm sandbox_oracle_vol

# Restart — Oracle will reinitialize from scratch
docker compose up -d
```

> **Warning:** This destroys all database data, including any schemas you've created.

---

## APEX & ORDS

**Q: What workspace do I use to log into APEX?**

- **APEX Admin Console** (`/ords/apex_admin`): workspace = `INTERNAL`, user = `ADMIN`
- **Application Builder** (`/ords/f?p=4550:1`): workspace = `SANDBOX`, user = `ADMIN`

---

**Q: How do I install a custom APEX application?**

1. Open Application Builder at `http://localhost:8080/ords/f?p=4550:1`
2. Log in with workspace `SANDBOX`, user `ADMIN`
3. Click **Import** and upload your `.sql` export file

---

**Q: ORDS stopped responding — how do I restart it?**

```bash
sandbox restart apex
# or
docker exec sandbox-oracle-server stop-apex
docker exec sandbox-oracle-server start-apex
```

Check the log if it doesn't come back: `sandbox logs ords`

---

## MCP (Claude Code Integration)

**Q: Why does the MCP `connect` tool return an error?**

This is expected SQLcl MCP behavior — the connect tool always returns an error message even when the connection succeeds. Ignore it and proceed to run queries with `run-sql` or `run-sqlcl`.

---

**Q: The MCP server shows "disconnected" in Claude Code — how do I reconnect?**

1. Verify the container is running: `docker ps --filter name=sandbox-oracle-server`
2. In Claude Code: `Cmd+Shift+P` → `MCP: Restart MCP Server` → select `sandbox-sqlcl-mcp`
3. Then ask Claude: `connect to sandbox-ai-conn using the MCP server`

---

**Q: Can I use the MCP server with multiple databases?**

The MCP server uses the `sandbox-ai-conn` saved connection by default (connects to `SANDBOX_AI` in `SANDBOX_PDB`). You can add connections with `sandbox conn add` and switch between them using the `connect` MCP tool.

---

## Performance & Resources

**Q: How much RAM does this environment need?**

Minimum 6 GB free RAM, recommended 12 GB or more. The database alone reserves 4 GB. If containers are being killed, Docker Desktop's memory limit may be too low — increase it in Docker Desktop → Settings → Resources.

---

**Q: The environment is running slowly — what can I do?**

```bash
# Check resource usage
docker stats --no-stream

# If memory is tight, reduce pool limits in .env:
ENV_DB_POOL_MAX=3
ENV_ORDS_JDBC_MAX_LIMIT=10

# Apply changes
docker compose down && docker compose up -d
```
