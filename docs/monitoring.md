# Monitoring & Log Management

<br>

## Monitoring


<br>

### Automated Health Checks

Both containers implement automated health monitoring:

- **Check Interval:** Every 30 seconds
- **Timeout:** 5 seconds
- **Start Period:** 10 seconds
- **Retries:** 3 attempts before marking unhealthy

<br>

### Health Check Methods

<br>

**Method 1: HTTP Endpoint**

```bash
curl http://localhost:3000/health
```

**Response (Healthy):**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-25T12:00:00.000Z",
  "uptime": 3600,
  "database": "connected"
}
```

<br>

**Method 2: Docker Inspect**

```bash
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-server
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-database
```

<br>

**Method 3: Built-in Command**

```bash
docker exec sandbox-oracle-server healthcheck
```

**Expected output:**
```
Server is healthy.
```

<br>

## Log Management

<br>

### Database Logs

**Configuration:**
- **Driver:** JSON file
- **Max Size:** 10MB per file
- **Max Files:** 3 (rotation)
- **Total Size:** ~30MB

**Access database logs:**

```bash
# View all logs
docker logs sandbox-oracle-database

# Follow logs in real-time
docker logs -f sandbox-oracle-database

# View last 100 lines
docker logs --tail 100 sandbox-oracle-database

# View with timestamps
docker logs -t sandbox-oracle-database

# Filter by time
docker logs --since 1h sandbox-oracle-database
docker logs --since 2025-11-25T10:00:00 sandbox-oracle-database
```

<br>

### Management Server Logs

```bash
# View application logs
docker logs sandbox-oracle-server

# Follow logs
docker logs -f sandbox-oracle-server

# View with grep filter
docker logs sandbox-oracle-server 2>&1 | grep ERROR
```

<br>

### Application Logs Volume

Persistent logs are stored in the `sandbox_logs_vol` volume:

```bash
# Inspect volume
docker volume inspect sandbox_logs_vol

# Access logs from host
docker run --rm -v sandbox_logs_vol:/logs alpine ls -la /logs
```

<br>

### APEX/ORDS Logs

```bash
# ORDS server logs
docker exec sandbox-oracle-server tail -f /tmp/ords.log

# APEX installation logs
docker exec sandbox-oracle-server tail -f /tmp/apex_install.log

# ORDS configuration logs
docker exec sandbox-oracle-server cat /tmp/ords_install.log
```

<br>

## Resource Monitoring

<br>

### Real-time Resource Usage

```bash
# Monitor all containers
docker stats

# Monitor specific container
docker stats sandbox-oracle-database

# One-time snapshot
docker stats --no-stream
```

**Output includes:**
- CPU usage percentage
- Memory usage and limit
- Memory percentage
- Network I/O
- Block I/O
- Process count

<br>

### Container Details

```bash
# Full container inspection
docker inspect sandbox-oracle-database

# Get specific information
docker inspect --format='{{.State.Status}}' sandbox-oracle-database
docker inspect --format='{{.NetworkSettings.IPAddress}}' sandbox-oracle-database
```

## Performance Monitoring

<br>

### Database Performance

```bash
# Connect to database
docker exec -it sandbox-oracle-database sqlplus / as sysdba

# Run performance queries
SELECT * FROM V$SESSION WHERE USERNAME IS NOT NULL;
SELECT * FROM V$SQL WHERE ELAPSED_TIME > 1000000;
SELECT * FROM V$SYSTEM_EVENT;
```

<br>

### Process Monitoring

```bash
# List running processes in container
docker exec sandbox-oracle-server ps aux

# Check ORDS process
docker exec sandbox-oracle-server netstat -tulnp | grep :8080

# Monitor Java processes
docker exec sandbox-oracle-server jps -v
```
