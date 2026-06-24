# Troubleshooting

## Common Issues

### Port Already in Use

**Symptom:** Container fails to start with port binding error

**Solution:**

```bash
# Check what's using the port
lsof -i :1521
netstat -an | grep 1521

# Stop conflicting service or change port in .env
# ENV_DB_PORT_LISTENER=1522
```

---

### Database Initialization Timeout

**Symptom:** Database takes longer than 10 minutes to initialize

**Solution:**

```bash
# Check available resources
docker system df
docker system prune  # Free up space

# Monitor initialization
docker logs -f sandbox-oracle-database
```

Look for: `DATABASE IS READY TO USE!`

---

### Connection Refused

**Symptom:** Cannot connect to database

**Solution:**
```bash
# Verify database is healthy
docker ps --filter "name=sandbox-oracle-database"

# Check listener status
docker exec sandbox-oracle-database lsnrctl status

# Verify network connectivity
docker exec sandbox-oracle-server ping sandbox-db

# Check firewall rules
sudo iptables -L
```

---

### APEX Installation Fails

**Symptom:** `install-apex` command returns errors

**Solution:**
```bash
# Check database is running and healthy
docker exec -it sandbox-oracle-database sqlplus / as sysdba

# Review installation logs
docker exec sandbox-oracle-server cat /tmp/apex_install.log

# Verify DB connectivity from server container
docker exec sandbox-oracle-server ping sandbox-db
```

---

### APEX Images Not Loading

**Symptom:** APEX UI shows missing images / broken layout

**Solution:**
```bash
# Verify images directory
docker exec sandbox-oracle-server ls -la /tmp/i | wc -l
# Should show ~27000 files

# If empty, restart ORDS to reload static files
docker exec sandbox-oracle-server stop-apex
docker exec sandbox-oracle-server start-apex
```

---

### ORDS Not Starting / Port 8080 Not Responding

**Symptom:** APEX URL returns connection refused; port 8080 is not reachable

**Solution:**
```bash
# Check if ORDS process is running
docker exec sandbox-oracle-server ps aux | grep ords

# Check if port is bound
docker exec sandbox-oracle-server netstat -tulnp | grep :8080

# View ORDS logs for errors
docker exec sandbox-oracle-server cat /tmp/ords.log

# Restart ORDS
docker exec sandbox-oracle-server stop-apex
docker exec sandbox-oracle-server start-apex

# If still failing, reinstall APEX
docker exec sandbox-oracle-server install-apex
```

---

### Container Health Stuck at "starting"

**Symptom:** `docker ps` shows `(health: starting)` for more than 5 minutes

**Solution:**
```bash
# Check what the health check is testing
docker inspect --format='{{json .State.Health}}' sandbox-oracle-database | jq .

# For database — verify SQL connectivity manually
docker exec sandbox-oracle-database sqlplus / as sysdba

# For server — verify HTTP health endpoint
curl -f http://localhost:3000/health

# If DB is slow to initialize, increase start_period in docker-compose.yml:
# start_period: 360s
```

---

### APEX Install Timeout / Partial Install

**Symptom:** APEX install log shows timeout; APEX only partially installed

**Solution:**
```bash
# Check the install log
docker exec sandbox-oracle-server cat /tmp/apex_install.log | tail -30

# Increase timeout in .env and restart
ENV_APEX_INSTALL_TIMEOUT=900
docker compose down && docker compose up -d

# Or run install manually with no timeout
docker exec -it sandbox-oracle-server install-apex
```

---

### SQLcl Connection Fails Inside Container

**Symptom:** `sandbox run sqlcl` fails or hangs

**Solution:**
```bash
# Verify database hostname is reachable
docker exec sandbox-oracle-server ping sandbox-db
docker exec sandbox-oracle-server nc -zv sandbox-db 1521

# Check environment variables in container
docker exec sandbox-oracle-server env | grep SANDBOX_DB

# Try explicit connection string
docker exec -it sandbox-oracle-server bash -c \
  "sql system/\${SANDBOX_DB_PASSWORD}@sandbox-db:1521/FREEPDB1"
```

---

### Volume Permission Errors

**Symptom:** Container logs show `Permission denied` on `/opt/oracle/oradata` or `/home/oracle/logs`

**Solution:**
```bash
# Check volume ownership
docker run --rm -v sandbox_oracle_vol:/data alpine ls -la /data

# Reset volume (WARNING: destroys all database data)
docker compose down
docker volume rm sandbox_oracle_vol
docker compose up -d
```

---

### Docker Out of Disk Space

**Symptom:** Build or pull fails with "no space left on device"

**Solution:**
```bash
# Check disk usage
docker system df

# Remove unused images, containers, volumes
docker system prune -a --volumes

# Or selectively
docker image prune -a      # Remove unused images
docker volume prune        # Remove unused volumes
docker container prune     # Remove stopped containers
```

---

### Container Exits Immediately on Startup

**Symptom:** `docker ps` shows container exited seconds after starting

**Solution:**
```bash
# Check exit logs
docker logs sandbox-oracle-server
docker logs sandbox-oracle-database

# Check exit code
docker inspect --format='{{.State.ExitCode}}' sandbox-oracle-server

# Common causes:
# - Missing required .env variable → add it to .env
# - Image not built → run: docker compose build --no-cache
# - Port conflict → change port in .env
```

---

### Network Connectivity Between Containers Fails

**Symptom:** Server container cannot reach database; `ping sandbox-db` fails

**Solution:**
```bash
# Check both containers are on the same network
docker network inspect sandbox_network

# Verify container IPs
docker inspect --format='{{.NetworkSettings.Networks.sandbox_network.IPAddress}}' sandbox-oracle-database
docker inspect --format='{{.NetworkSettings.Networks.sandbox_network.IPAddress}}' sandbox-oracle-server

# Recreate network by restarting everything
docker compose down && docker compose up -d
```

---

### MCP Server Not Connecting

**Symptom:** Claude Code MCP tool shows "connection failed" or times out

**Solution:**
```bash
# Verify container is running and healthy
docker ps --filter name=sandbox-oracle-server

# Check MCP port is bound
docker exec sandbox-oracle-server netstat -tulnp | grep :3001

# Restart the MCP server in Claude Code:
# Cmd+Shift+P → MCP: Restart MCP Server → sandbox-sqlcl-mcp

# Verify MCP environment variables
docker exec sandbox-oracle-server env | grep -E "MCP|SANDBOX_DB_MCP"
```

> **Note:** The MCP `connect` tool may return an error message — this is expected SQLcl MCP behavior. The connection is established successfully. Proceed to run queries normally.

---

### Reset / Clean Start from Scratch

**Symptom:** Environment is in a broken state; want a fresh start

```bash
# Stop and remove all containers
docker compose down

# Remove all sandbox volumes (WARNING: destroys database data)
docker volume rm sandbox_oracle_vol sandbox_logs_vol sandbox_dbtools_vol

# Remove the built image (forces full rebuild)
docker image rm sandbox-oracle-sandbox:latest

# Rebuild and start fresh
docker compose build --no-cache
docker compose up -d
```

---

## Collecting Diagnostics

When reporting an issue, include:

```bash
# Container status
docker ps -a --filter "name=sandbox"

# Recent logs (last 50 lines each)
docker logs --tail 50 sandbox-oracle-database
docker logs --tail 50 sandbox-oracle-server

# Health state
docker inspect --format='{{json .State.Health}}' sandbox-oracle-database
docker inspect --format='{{json .State.Health}}' sandbox-oracle-server

# System resources
docker system df
docker stats --no-stream
```
