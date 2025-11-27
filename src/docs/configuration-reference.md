# Configuration Reference

<br> 

## Network Configuration

| Component | Value | Description |
|-----------|-------|-------------|
| **Network Name** | `demasylabs_network` | Custom Docker bridge network |
| **Subnet** | `192.168.1.0/24` | Network CIDR |
| **Database IP** | `192.168.1.10` | Static IP for database container |
| **Server IP** | `192.168.1.20` | Static IP for management server |
| **Gateway** | `192.168.1.1` | Network gateway |

<br>

## Environment Variables Reference

### Database Configuration

```bash
# Core Settings
ORACLE_PWD=                    # Required: Database system password (⚠️ CHANGE THIS!)
DATABASE_NAME=DEMASY           # Database name (max 8 chars)
TZ=Asia/Riyadh                 # Timezone

# Connection Settings
DEMASYLABS_DB_HOST=oracle-al-database-26ai
DEMASYLABS_DB_PORT=1521
DEMASYLABS_DB_SERVICE=FREE
DEMASYLABS_DB_SID=FREE
DEMASYLABS_DB_USER=system
DEMASYLABS_DB_PASSWORD=${ORACLE_PWD}
```

### Connection Pool

```bash
DEMASYLABS_DB_POOL_MIN=1
DEMASYLABS_DB_POOL_MAX=5
DEMASYLABS_DB_POOL_INCREMENT=1
```

### APEX Configuration

```bash
ENV_APEX_HOME=/opt/oracle/apex                              # APEX installation directory
ENV_APEX_IMAGES_DIR=/tmp/i                                  # Static assets directory (~27K files)
ENV_APEX_INSTALL_LOG=/tmp/apex_install.log                  # Installation log file
ENV_APEX_TABLE_SPACE=DL_APEX_TS                             # APEX metadata tablespace
ENV_APEX_TABLE_SPACE_FILES=DL_APEX_FILES_TS                 # APEX files tablespace
ENV_APEX_DEFAULT_WORKSPACE=INTERNAL                         # Default workspace name
ENV_APEX_ADMIN_USERNAME=ADMIN                               # Workspace administrator username
ENV_APEX_ADMIN_PASSWORD=YourAPEXPassword123                 # ⚠️ CHANGE THIS! Admin password
ENV_APEX_ADMIN_EMAIL=name@domain.io                         # ⚠️ CHANGE THIS! Admin email
ENV_APEX_EMAIL=name@domain.io                               # ⚠️ CHANGE THIS! Default email
ENV_APEX_SECURITY_GROUP_ID=10                               # Security group (10=INTERNAL)
ENV_APEX_TABLESPACE_SIZE=500M                               # Initial tablespace size
ENV_APEX_TABLESPACE_AUTOEXTEND=100M                         # Tablespace growth increment
```

#### ORDS Configuration

```bash
ENV_ORDS_PORT=8080                                          # ORDS HTTP listener port
ENV_ORDS_JDBC_MIN_LIMIT=3                                   # Minimum JDBC connections
ENV_ORDS_JDBC_MAX_LIMIT=20                                  # Maximum JDBC connections
ENV_ORDS_JDBC_INITIAL_LIMIT=3                               # Initial JDBC connections
ENV_ORDS_STATEMENT_TIMEOUT=900                              # SQL timeout (seconds, 15 min)
ENV_ORDS_HOME=/opt/oracle/ords                              # ORDS installation directory
ENV_ORDS_CONFIG=/opt/oracle/ords/config                     # ORDS configuration directory
ENV_ORDS_LOG=/tmp/ords.log                                  # ORDS log file path
```


## Container Resource Limits

### Database Container

```yaml
resources:
  limits:
    cpus: '1'
    memory: 3GB
  reservations:
    cpus: '0.5'
    memory: 2GB
```

### Management Server

```yaml
resources:
  limits:
    cpus: '1'
    memory: 512MB
  reservations:
    cpus: '0.25'
    memory: 256MB
```

## Volume Mounts

| Volume | Mount Point | Purpose |
|--------|-------------|---------|
| `demasylabs_logs` | `/home/oracle/logs` | Application logs |
| Database datafiles | `/opt/oracle/oradata` | Database files (internal) |
| APEX images | `/tmp/i` | APEX static assets |
| ORDS config | `/opt/oracle/ords/config` | ORDS configuration |
