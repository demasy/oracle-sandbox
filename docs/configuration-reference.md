# Configuration Reference

<br> 

## Network Configuration

| Component | Variable | Default | Description |
|-----------|----------|---------|-------------|
| **Network Name** | — | `sandbox_network` | Custom Docker bridge network |
| **Subnet** | `ENV_NETWORK_SUBNET` | `192.168.1.0/24` | Network CIDR |
| **Database IP** | `ENV_IP_DB_SERVER` | `192.168.1.110` | Static IP for database container |
| **Server IP** | `ENV_IP_APP_SERVER` | `192.168.1.120` | Static IP for management server |
| **Gateway** | `ENV_NETWORK_GATEWAY` | `192.168.1.1` | Network gateway |

<br>

## Environment Variables Reference

All variables are set in `.env` (copy from `.env.example`). Variables are forwarded into containers via `docker-compose.yml`.

### Database Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_DB_SID` | `FREE` | Oracle SID |
| `ENV_DB_SERVICE` | `FREEPDB1` | Pluggable database service name |
| `ENV_DB_NAME` | `FREE` | Database name |
| `ENV_DB_CHARACTERSET` | `AL32UTF8` | Character set |
| `ENV_DB_USER` | `system` | Default admin user |
| `ENV_DB_MCP_USER` | `sandbox_ai` | MCP connection user |
| `ENV_DB_MCP_SERVICE` | `SANDBOX_PDB` | MCP connection PDB |
| `ENV_DB_PASSWORD` | — | **Required** — database password (⚠️ change from default) |
| `ENV_DB_PORT_LISTENER` | `1521` | TNS listener port |
| `ENV_IP_DB_SERVER` | `192.168.1.110` | Database container static IP |

### Connection Pool

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_DB_POOL_MIN` | `1` | Minimum JDBC connections |
| `ENV_DB_POOL_MAX` | `5` | Maximum JDBC connections |
| `ENV_DB_POOL_INCREMENT` | `1` | Pool growth increment |

### APEX Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_APEX_HOME` | `/opt/oracle/apex` | APEX installation directory |
| `ENV_APEX_IMAGES_DIR` | `/tmp/i` | Static assets directory (~27K files) |
| `ENV_APEX_INSTALL_LOG` | `/tmp/apex_install.log` | Installation log file |
| `ENV_APEX_TABLE_SPACE` | `SANDBOX_APEX_TS` | APEX metadata tablespace |
| `ENV_APEX_TABLE_SPACE_FILES` | `SANDBOX_APEX_FILES_TS` | APEX files tablespace |
| `ENV_APEX_TABLESPACE_SIZE` | `500M` | Initial tablespace size |
| `ENV_APEX_TABLESPACE_AUTOEXTEND` | `100M` | Tablespace autoextend increment |
| `ENV_APEX_DEFAULT_WORKSPACE` | `SANDBOX` | Default workspace name |
| `ENV_APEX_ADMIN_USERNAME` | `ADMIN` | Workspace administrator username |
| `ENV_APEX_ADMIN_PASSWORD` | — | **Required** — admin password (⚠️ change from default) |
| `ENV_APEX_EMAIL` | — | Admin email address |
| `ENV_APEX_SECURITY_GROUP_ID` | `10` | Security group ID |
| `ENV_APEX_PORT` | `8080` | APEX/ORDS host port mapping |

### ORDS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_ORDS_HOME` | `/opt/oracle/ords` | ORDS installation directory |
| `ENV_ORDS_CONFIG` | `/opt/oracle/ords/config` | ORDS configuration directory |
| `ENV_ORDS_LOG` | `/tmp/ords.log` | ORDS log file path |
| `ENV_ORDS_PORT` | `8080` | ORDS in-container listen port |
| `ENV_ORDS_JDBC_MIN_LIMIT` | `3` | Minimum JDBC connections |
| `ENV_ORDS_JDBC_MAX_LIMIT` | `20` | Maximum JDBC connections |
| `ENV_ORDS_JDBC_INITIAL_LIMIT` | `3` | Initial JDBC connections |
| `ENV_ORDS_STATEMENT_TIMEOUT` | `900` | SQL timeout in seconds (15 min) |

### MCP Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_MCP_ENABLED` | `true` | Enable MCP server |
| `ENV_MCP_PORT` | `3001` | MCP server host port |

<br>

## Container Resource Limits

### Database Container (`sandbox-oracle-database`)

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_DB_CPU_LIMIT` | `2` | CPU core limit |
| `ENV_DB_MEMORY_LIMIT` | `4g` | Memory limit |

Reservations: 2 CPUs, 4 GB memory.

### Application Server (`sandbox-oracle-server`)

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_SERVER_CPU_LIMIT` | `3.0` | CPU core limit |
| `ENV_SERVER_MEMORY_LIMIT` | `3g` | Memory limit |

Reservations: 2 CPUs, 2 GB memory.

<br>

## Volumes

| Volume | Mount Point | Container | Purpose |
|--------|-------------|-----------|---------|
| `sandbox_oracle_vol` | `/opt/oracle/oradata` | database | Oracle database files |
| `sandbox_logs_vol` | `/home/oracle/logs` | server | Application and database logs |
| `sandbox_dbtools_vol` | `/home/sandbox/.dbtools` | server | SQLcl saved connections |

<br>

## Port Mapping

| Variable | Host Port | Container Port | Service |
|----------|-----------|----------------|---------|
| `ENV_DB_PORT_LISTENER` | `1521` | `1521` | Oracle TNS listener |
| `ENV_SERVER_PORT` | `3000` | `3000` | Management server health/API |
| `ENV_APEX_PORT` | `8080` | `8080` | APEX & ORDS web interface |
| `ENV_MCP_PORT` | `3001` | `3001` | Claude Code MCP server |
