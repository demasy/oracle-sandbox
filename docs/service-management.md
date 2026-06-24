# Service Management

## Container Overview

| Container | Name | Role |
|-----------|------|------|
| Database | `sandbox-oracle-database` | Oracle AI Database 26ai Free |
| Server | `sandbox-oracle-server` | APEX, ORDS, SQLcl, MCP |

**Startup order:** Database must be running before the server. `docker compose up -d` handles this automatically via `depends_on`.

<br>

## Docker Compose (Recommended)

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart all services
docker compose restart

# View status of all containers
docker compose ps

# View live logs for all containers
docker compose logs -f

# Rebuild image and restart (after code changes)
docker compose up -d --build
```

### Apply .env Changes

```bash
# After editing .env, restart containers to apply
docker compose down
docker compose up -d

# Verify environment variables loaded in container
docker exec sandbox-oracle-server env | grep SANDBOX
```

<br>

## Health Check Interpretation

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-database
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-server
```

| Status | Meaning | Action |
|--------|---------|--------|
| `healthy` | Container passed health check | No action needed |
| `starting` | Within `start_period`; not yet checked | Wait — normal during startup |
| `unhealthy` | Health check failed 3+ times | Check logs; see [Troubleshooting](./troubleshooting.md) |
| `none` | No health check defined | Informational only |

**Database health check** runs: `SELECT 1 FROM DUAL` via SQL*Plus every 30 s.
**Server health check** runs: `curl http://localhost:3000/health` every 30 s.

<br>

## Database Service

#### Start / Stop / Restart
```bash
docker start sandbox-oracle-database
docker stop sandbox-oracle-database
docker restart sandbox-oracle-database
```

#### Access Database Shell
```bash
docker exec -it sandbox-oracle-database bash
```

#### View Database Logs
```bash
# View all logs
docker logs sandbox-oracle-database

# Follow logs in real-time
docker logs -f sandbox-oracle-database

# View last 100 lines
docker logs --tail 100 sandbox-oracle-database

# View logs with timestamps
docker logs -t sandbox-oracle-database
```

#### Monitor Database
```bash
# Container details
docker inspect sandbox-oracle-database

# Real-time resource usage
docker stats sandbox-oracle-database

# Health status
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-database
```

#### Check Listener
```bash
netstat -an | grep 1521
```

#### Backup Database (Container Snapshot)
```bash
docker commit sandbox-oracle-database oracle-db-backup:$(date +%Y%m%d)
```

> For data-level backups use Oracle Data Pump (`expdp`) or RMAN from inside the container.

<br>

## Management Server

#### Start / Stop / Restart
```bash
docker start sandbox-oracle-server
docker stop sandbox-oracle-server
docker restart sandbox-oracle-server
```

#### Access Shell
```bash
docker exec -it sandbox-oracle-server bash
```

#### View Logs
```bash
# View all logs
docker logs sandbox-oracle-server

# Follow logs in real-time
docker logs -f sandbox-oracle-server

# View last 100 lines
docker logs --tail 100 sandbox-oracle-server
```

#### Check Container Status
```bash
docker inspect sandbox-oracle-server
docker stats sandbox-oracle-server
```

<br>

## Useful Diagnostic Commands

```bash
# List all sandbox containers (running and stopped)
docker ps -a --filter "name=sandbox"

# Show resource usage for both containers
docker stats sandbox-oracle-database sandbox-oracle-server --no-stream

# Inspect the Docker network
docker network inspect sandbox_network

# List sandbox volumes
docker volume ls --filter "name=sandbox"
```
