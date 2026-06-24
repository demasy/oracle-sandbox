# Quick Reference

One-page cheat sheet for Oracle Sandbox.

---

## Sandbox CLI

```bash
# Connect to database
sandbox run sqlcl              # Interactive menu
sandbox run sqlcl -u system    # Connect as system

# Status
sandbox status                 # All services summary
sandbox status database        # Database only
sandbox status apex            # APEX/ORDS only
sandbox status network         # Network connectivity

# APEX / ORDS
sandbox install apex           # Install APEX + ORDS (one-time)
sandbox start apex             # Start ORDS
sandbox stop apex              # Stop ORDS
sandbox restart apex           # Restart ORDS

# Logs
sandbox logs apex              # APEX install log
sandbox logs ords              # ORDS runtime log
sandbox logs all               # All logs

# Connections (SQLcl saved connections)
sandbox conn list              # List saved connections
sandbox conn add --name myconn --user system --host sandbox-db --port 1521 --pdb FREEPDB1
sandbox conn test --name myconn
sandbox conn delete --name myconn

# Monitor
sandbox monitor all            # Full system metrics
sandbox monitor --export json  # Machine-readable output
sandbox run monitor            # Interactive monitoring menu

# Run MCP server
sandbox run mcp

# Help
sandbox help                   # Full help
sandbox help run               # Help for a specific command
```

---

## Shell Aliases

| Alias | Expands To |
|-------|-----------|
| `sb` | `sandbox` |
| `sr` | `sandbox run` |
| `sc` | `sandbox conn` |
| `sl` | `sandbox logs` |
| `ss` | `sandbox status` |
| `si` | `sandbox install` |
| `sk` | `sandbox start` |
| `sp` | `sandbox stop` |
| `sx` | `sandbox restart` |
| `sm` | `sandbox monitor` |

---

## Docker Compose

```bash
docker compose up -d           # Start all services
docker compose down            # Stop all services
docker compose ps              # Container status
docker compose logs -f         # Live logs (all containers)
docker compose build --no-cache  # Rebuild image
```

---

## Direct Container Access

```bash
# Enter shell
docker exec -it sandbox-oracle-server bash
docker exec -it sandbox-oracle-database bash

# Health check
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-database
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-server

# Logs
docker logs -f sandbox-oracle-server
docker logs -f sandbox-oracle-database
```

---

## Connection Strings

| Format | String |
|--------|--------|
| EZ Connect | `system/password@localhost:1521/FREEPDB1` |
| TNS | `(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=FREEPDB1)))` |
| JDBC | `jdbc:oracle:thin:@localhost:1521/FREEPDB1` |
| Internal (container) | `system/password@sandbox-db:1521/FREEPDB1` |

---

## Ports

| Port | Service |
|------|---------|
| `1521` | Oracle TNS Listener |
| `3000` | Management Server (health check / API) |
| `8080` | APEX & ORDS web interface |
| `3001` | Claude Code MCP server |

---

## APEX URLs

| Service | URL |
|---------|-----|
| Application Builder | `http://localhost:8080/ords/f?p=4550:1` |
| SQL Developer Web | `http://localhost:8080/ords/sandbox/_sdw/` |
| APEX Admin | `http://localhost:8080/ords/apex_admin` |
| Health Check | `http://localhost:3000/health` |

---

## Log File Paths (inside container)

| Log | Path |
|-----|------|
| APEX install | `/tmp/apex_install.log` |
| ORDS runtime | `/tmp/ords.log` |
| ORDS install | `/tmp/ords_install.log` |
| REST config | `/tmp/apex_rest_config.log` |
| Startup | `/tmp/auto-user-setup.log` |

---

## Key .env Variables

| Variable | Purpose |
|----------|---------|
| `ENV_DB_PASSWORD` | Oracle database password |
| `ENV_APEX_ADMIN_PASSWORD` | APEX admin password |
| `ENV_DB_SERVICE` | PDB name (`FREEPDB1`) |
| `ENV_IP_DB_SERVER` | Database container IP |
| `ENV_IP_APP_SERVER` | Server container IP |
| `ENV_APEX_PORT` | APEX host port (default `8080`) |
| `ENV_AUTO_INSTALL_APEX_ON_STARTUP` | Auto-install APEX on start |
| `ENV_INSTALL_APEX` | Download APEX/ORDS at build time |
