# Startup Configuration Guide

## Overview

This document describes the environment variables that control the Oracle Sandbox container startup behavior, particularly the automatic APEX installation process.

## Environment Variables

### Build-Time Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_INSTALL_APEX` | `true` | Download APEX/ORDS software during Docker build |

### Runtime Startup Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_AUTO_INSTALL_APEX_ON_STARTUP` | `true` | Automatically install APEX if not detected in database |
| `ENV_SHOW_APEX_INSTALL_LOGS` | `true` | Display installation output in container startup logs |
| `ENV_APEX_INSTALL_TIMEOUT` | `600` | Maximum time (seconds) to wait for APEX installation |
| `ENV_STARTUP_WAIT_FOR_DB` | `true` | Wait for database to be ready before APEX checks |
| `ENV_STARTUP_DB_WAIT_TIMEOUT` | `120` | Maximum time (seconds) to wait for database readiness |
| `ENV_STARTUP_DB_WAIT_INTERVAL` | `5` | Interval (seconds) between database readiness checks |

## Configuration Modes

### Mode 1: Full Automatic (Default)

```bash
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=true
ENV_SHOW_APEX_INSTALL_LOGS=true
ENV_STARTUP_WAIT_FOR_DB=true
```

**Behavior:**
- Downloads APEX/ORDS during build
- Waits for database to be ready on startup
- Automatically installs APEX if not detected
- Displays installation progress in real-time

**Best for:** Development environments where you want a fully automated setup.

### Mode 2: Background Installation

```bash
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=true
ENV_SHOW_APEX_INSTALL_LOGS=false
ENV_STARTUP_WAIT_FOR_DB=true
```

**Behavior:**
- Downloads APEX/ORDS during build
- Waits for database to be ready on startup
- Automatically installs APEX if not detected
- Installation runs in background (logs to file only)

**Best for:** CI/CD environments where console output should be minimal.

**Monitor installation:**
```bash
docker exec -it sandbox-oracle-server tail -f /tmp/apex-startup-install.log
```

### Mode 3: Manual Installation Only

```bash
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=false
```

**Behavior:**
- Downloads APEX/ORDS during build
- Shows instructions to install manually
- No automatic installation

**Best for:** Training environments where users learn the installation process.

**Manual installation:**
```bash
docker exec -it sandbox-oracle-server install-apex
```

### Mode 4: No APEX at All

```bash
ENV_INSTALL_APEX=false
```

**Behavior:**
- No APEX/ORDS downloaded during build
- No installation checks or prompts
- Container starts with database access only

**Best for:** Database-only environments without APEX requirements.

## Detailed Variable Descriptions

### `ENV_INSTALL_APEX`

**Type:** Boolean (`true` | `false`)  
**Default:** `true`  
**Stage:** Build-time

Controls whether APEX and ORDS software are downloaded during Docker image build.

- `true`: Downloads APEX 24.2 and ORDS 25.3 (~500MB) into image
- `false`: Skips APEX/ORDS download, reduces image size

⚠️ **Important:** This is a build argument. Changes require rebuilding the image:
```bash
docker-compose build --no-cache
```

### `ENV_AUTO_INSTALL_APEX_ON_STARTUP`

**Type:** Boolean (`true` | `false`)  
**Default:** `true`  
**Stage:** Runtime

Controls whether APEX installation runs automatically when the container starts.

- `true`: Automatically installs APEX if not detected in database
- `false`: Shows manual installation instructions only

**Dependencies:**
- Requires `ENV_INSTALL_APEX=true` (software must be downloaded first)
- Requires database connection (waits for DB if `ENV_STARTUP_WAIT_FOR_DB=true`)

### `ENV_SHOW_APEX_INSTALL_LOGS`

**Type:** Boolean (`true` | `false`)  
**Default:** `true`  
**Stage:** Runtime

Controls whether installation output appears in container startup logs.

- `true`: Installation output streams to console (visible in `docker logs`)
- `false`: Installation runs in background, logs saved to `/tmp/apex-startup-install.log`

**When to use `false`:**
- CI/CD pipelines with log size limits
- Environments where clean startup logs are required
- When you prefer to monitor installation separately

**Monitor background installation:**
```bash
# View live installation progress
docker exec -it sandbox-oracle-server tail -f /tmp/apex-startup-install.log

# Check if installation completed
docker exec -it sandbox-oracle-server cat /tmp/apex-startup-install.log | tail -20
```

### `ENV_APEX_INSTALL_TIMEOUT`

**Type:** Integer (seconds)  
**Default:** `600` (10 minutes)  
**Stage:** Runtime

Maximum time to wait for APEX installation to complete before timing out.

**Typical installation times:**
- Fast hardware (SSD, 4+ cores): 3-4 minutes
- Standard hardware: 4-6 minutes
- Slow hardware: 6-10 minutes

**Recommendations:**
- Development: `600` (10 minutes)
- CI/CD: `900` (15 minutes - allows for slower runners)
- Production-like: `1200` (20 minutes - conservative)

**If installation times out:**
```bash
# Check logs for the cause
docker exec -it sandbox-oracle-server cat /tmp/apex-startup-install.log

# Increase timeout and restart
# Edit .env: ENV_APEX_INSTALL_TIMEOUT=900
docker-compose down
docker-compose up -d
```

### `ENV_STARTUP_WAIT_FOR_DB`

**Type:** Boolean (`true` | `false`)  
**Default:** `true`  
**Stage:** Runtime

Controls whether the startup script waits for the database to be fully ready before checking APEX installation.

- `true`: Polls database with simple query until connection succeeds
- `false`: Proceeds immediately (may fail if database not ready)

**How it works:**
1. Runs `SELECT 1 FROM DUAL` query every `ENV_STARTUP_DB_WAIT_INTERVAL` seconds
2. Waits up to `ENV_STARTUP_DB_WAIT_TIMEOUT` seconds
3. Proceeds with APEX checks if database responds
4. Times out with warning if database doesn't respond in time

**When to use `false`:**
- Database is guaranteed to be ready (e.g., existing database)
- You want the container to start immediately without waiting

### `ENV_STARTUP_DB_WAIT_TIMEOUT`

**Type:** Integer (seconds)  
**Default:** `120` (2 minutes)  
**Stage:** Runtime

Maximum time to wait for database to become ready.

**Typical database startup times:**
- First start (new database): 60-90 seconds
- Restart (existing database): 30-60 seconds
- Recovery mode: 90-120+ seconds

**Recommendations:**
- Development: `120` (2 minutes - safe default)
- CI/CD: `180` (3 minutes - allows for slower systems)
- Fast systems: `60` (1 minute - if you know DB starts quickly)

### `ENV_STARTUP_DB_WAIT_INTERVAL`

**Type:** Integer (seconds)  
**Default:** `5`  
**Stage:** Runtime

How often to check if the database is ready (polling interval).

**Impact:**
- Lower value (e.g., `2`): More responsive, more log messages, slightly more CPU
- Higher value (e.g., `10`): Cleaner logs, less CPU, slower to detect readiness

**Recommendations:**
- Interactive development: `5` (good balance)
- CI/CD pipelines: `10` (cleaner logs)
- Fast systems: `2` (quick detection)

## Configuration File Locations

### `.env` File

Located at project root: `/Users/Shared/data/projects/demasylabs/repo/github/demasy/github/oracle-sandbox/.env`

All environment variables are defined here with `ENV_` prefix.

### Docker Compose

Variables are mapped from `ENV_*` to `SANDBOX_*` in `docker-compose.yml`:

```yaml
environment:
  - SANDBOX_AUTO_INSTALL_APEX_ON_STARTUP=${ENV_AUTO_INSTALL_APEX_ON_STARTUP}
  - SANDBOX_SHOW_APEX_INSTALL_LOGS=${ENV_SHOW_APEX_INSTALL_LOGS}
  # ... etc
```

### Startup Script

The container uses `SANDBOX_*` variables at runtime:

```bash
if [ "${SANDBOX_AUTO_INSTALL_APEX_ON_STARTUP:-true}" = "true" ]; then
    # Auto-install logic
fi
```

## Troubleshooting

### Installation Logs Not Showing

**Symptom:** `ENV_SHOW_APEX_INSTALL_LOGS=true` but no output appears

**Causes & Solutions:**

1. **Output buffering:**
   ```bash
   # Check if installation actually ran
   docker exec -it sandbox-oracle-server ls -lh /tmp/apex-startup-install.log
   
   # View saved logs
   docker exec -it sandbox-oracle-server cat /tmp/apex-startup-install.log
   ```

2. **Installation script issues:**
   ```bash
   # Test installation manually with debug output
   docker exec -it sandbox-oracle-server bash -x /usr/demasy/scripts/oracle/apex/install.sh
   ```

3. **Early exit or timeout:**
   ```bash
   # Check for timeout (exit code 124)
   docker exec -it sandbox-oracle-server cat /tmp/apex-startup-install.log | grep -i timeout
   
   # Increase timeout
   # Edit .env: ENV_APEX_INSTALL_TIMEOUT=900
   ```

### Database Readiness Timeout

**Symptom:** "Database readiness timeout reached"

**Solutions:**

1. **Increase timeout:**
   ```bash
   # Edit .env
   ENV_STARTUP_DB_WAIT_TIMEOUT=180  # 3 minutes
   ```

2. **Check database status:**
   ```bash
   # View database logs
   docker logs sandbox-oracle-database
   
   # Check if database is actually ready
   docker exec -it sandbox-oracle-database sqlplus -s system/password@//localhost:1521/FREE
   ```

3. **Skip waiting (if database is known to be ready):**
   ```bash
   # Edit .env
   ENV_STARTUP_WAIT_FOR_DB=false
   ```

### APEX Installation Fails

**Symptom:** "APEX installation failed with exit code: X"

**Solutions:**

1. **Check detailed logs:**
   ```bash
   docker exec -it sandbox-oracle-server cat /tmp/apex-startup-install.log
   ```

2. **Verify database permissions:**
   ```bash
   docker exec -it sandbox-oracle-server sqlcl <<EOF
   CONNECT system/${ENV_DB_PASSWORD}@${ENV_IP_DB_SERVER}:1521/${ENV_DB_SERVICE}
   SELECT * FROM dba_ts_quotas WHERE username = 'SYSTEM';
   EXIT;
   EOF
   ```

3. **Run installation manually for detailed output:**
   ```bash
   docker exec -it sandbox-oracle-server install-apex
   ```

4. **Check available disk space:**
   ```bash
   docker exec -it sandbox-oracle-server df -h /opt/oracle/oradata
   ```

### Changes Not Taking Effect

**Symptom:** Modified `.env` variables but behavior unchanged

**Solutions:**

1. **For build-time variables (`ENV_INSTALL_APEX`):**
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

2. **For runtime variables (all others):**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **Verify variables are set in container:**
   ```bash
   docker exec -it sandbox-oracle-server env | grep SANDBOX
   ```

## Best Practices

### Development Environments

```bash
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=true
ENV_SHOW_APEX_INSTALL_LOGS=true
ENV_APEX_INSTALL_TIMEOUT=600
ENV_STARTUP_WAIT_FOR_DB=true
ENV_STARTUP_DB_WAIT_TIMEOUT=120
ENV_STARTUP_DB_WAIT_INTERVAL=5
```

### CI/CD Pipelines

```bash
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=true
ENV_SHOW_APEX_INSTALL_LOGS=false  # Keep logs clean
ENV_APEX_INSTALL_TIMEOUT=900      # Allow extra time
ENV_STARTUP_WAIT_FOR_DB=true
ENV_STARTUP_DB_WAIT_TIMEOUT=180   # Generous timeout
ENV_STARTUP_DB_WAIT_INTERVAL=10   # Reduce log noise
```

### Training/Workshop Environments

```bash
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=false  # Users install manually
ENV_STARTUP_WAIT_FOR_DB=true
ENV_STARTUP_DB_WAIT_TIMEOUT=120
```

### Database-Only Environments

```bash
ENV_INSTALL_APEX=false  # Skip APEX entirely
```

## Examples

### Example 1: Quick Start with Visible Logs

```bash
# .env configuration (default)
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=true
ENV_SHOW_APEX_INSTALL_LOGS=true

# Start containers
docker-compose up -d

# Watch logs in real-time
docker logs -f sandbox-oracle-server

# Expected output:
# ✅ Database is ready
# ℹ️ APEX not yet installed in database
# ℹ️ Installing APEX automatically (this takes 3-5 minutes)...
# [Installation output appears here...]
# ✅ APEX installation completed successfully!
```

### Example 2: Silent Background Installation

```bash
# .env configuration
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=true
ENV_SHOW_APEX_INSTALL_LOGS=false

# Start containers
docker-compose up -d

# Monitor installation separately
docker exec -it sandbox-oracle-server tail -f /tmp/apex-startup-install.log

# Check when complete
docker exec -it sandbox-oracle-server cat /tmp/apex-startup-install.log | tail -5
```

### Example 3: Manual Control

```bash
# .env configuration
ENV_INSTALL_APEX=true
ENV_AUTO_INSTALL_APEX_ON_STARTUP=false

# Start containers
docker-compose up -d

# Install APEX when ready
docker exec -it sandbox-oracle-server install-apex

# Or enter container and install
docker exec -it sandbox-oracle-server bash
install-apex
```

## Related Documentation

- [Service Management Guide](./service-management.md)
- [Database Connectivity Guide](../database/connectivity.md)
- [Troubleshooting Guide](./troubleshooting.md)
- [APEX Installation Guide](../database/apex-installation.md)

## Version History

- **v2.0.0** (2025-12-03): Added startup configuration environment variables
- **v1.0.0** (2025-11-25): Initial documentation

---

**Maintained by:** Demasy Labs  
**Contact:** founder@demasy.io  
**Repository:** oracle-sandbox
