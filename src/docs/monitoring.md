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
docker inspect --format='{{.State.Health.Status}}' demasy-server
docker inspect --format='{{.State.Health.Status}}' oracle-al-database-26ai
```

<br>

**Method 3: Built-in Command**

```bash
docker exec demasy-server healthcheck
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
docker logs oracle-al-database-26ai

# Follow logs in real-time
docker logs -f oracle-al-database-26ai

# View last 100 lines
docker logs --tail 100 oracle-al-database-26ai

# View with timestamps
docker logs -t oracle-al-database-26ai

# Filter by time
docker logs --since 1h oracle-al-database-26ai
docker logs --since 2025-11-25T10:00:00 oracle-al-database-26ai
```

<br>

### Management Server Logs

```bash
# View application logs
docker logs demasy-server

# Follow logs
docker logs -f demasy-server

# View with grep filter
docker logs demasy-server 2>&1 | grep ERROR
```

<br>

### Application Logs Volume

Persistent logs are stored in the `demasylabs_logs` volume:

```bash
# Inspect volume
docker volume inspect demasylabs_logs

# Access logs from host
docker run --rm -v demasylabs_logs:/logs alpine ls -la /logs
```

<br>

### APEX/ORDS Logs

```bash
# ORDS server logs
docker exec demasy-server tail -f /tmp/ords.log

# APEX installation logs
docker exec demasy-server tail -f /tmp/apex_install.log

# ORDS configuration logs
docker exec demasy-server cat /tmp/ords_install.log
```

<br>

## Resource Monitoring

<br>

### Real-time Resource Usage

```bash
# Monitor all containers
docker stats

# Monitor specific container
docker stats oracle-al-database-26ai

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
docker inspect oracle-al-database-26ai

# Get specific information
docker inspect --format='{{.State.Status}}' oracle-al-database-26ai
docker inspect --format='{{.NetworkSettings.IPAddress}}' oracle-al-database-26ai
```

## Performance Monitoring

<br>

### Database Performance

```bash
# Connect to database
docker exec -it oracle-al-database-26ai sqlplus / as sysdba

# Run performance queries
SELECT * FROM V$SESSION WHERE USERNAME IS NOT NULL;
SELECT * FROM V$SQL WHERE ELAPSED_TIME > 1000000;
SELECT * FROM V$SYSTEM_EVENT;
```

<br>

### Process Monitoring

```bash
# List running processes in container
docker exec demasy-server ps aux

# Check ORDS process
docker exec demasy-server netstat -tulnp | grep :8080

# Monitor Java processes
docker exec demasy-server jps -v
```

## Alert Configuration

### Email Notifications (Optional)

Configure Docker to send alerts for container events:

```yaml
# docker-compose.yml
services:
  demasylabs-oracle-database:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "production"
```

### Log Aggregation

For production environments, consider integrating with:
- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Grafana + Prometheus**
- **Splunk**
- **DataDog**
