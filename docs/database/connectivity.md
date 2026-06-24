# Database Connectivity

## Connection Methods

#### Method 1: Oracle SQLcl (Recommended)

Modern command-line interface with enhanced features:

```bash
# From host machine (requires container access)
docker exec -it sandbox-oracle-server sqlcl

# Or use the preconfigured alias
docker exec -it sandbox-oracle-server oracle
```


#### Method 2: SQL Command

Direct SQL connection using the `sql` wrapper:

```bash
docker exec -it sandbox-oracle-server sql
```

#### Method 3: Custom Connection String

For specific user connections:

```bash
# Syntax
docker exec -it sandbox-oracle-server bash -c "sql username/password@hostname:port/service"

# Example - Connect as SYSTEM
docker exec -it sandbox-oracle-server bash -c "sql system/${ENV_DB_PASSWORD}@sandbox-oracle-database:1521/FREE"

# Example - Connect as SYSDBA
docker exec -it sandbox-oracle-server bash -c "sql sys/${ENV_DB_PASSWORD}@sandbox-oracle-database:1521/FREE as sysdba"
```

#### Method 4: SQL*Plus (Traditional)

For compatibility with legacy scripts:

```bash
docker exec -it sandbox-oracle-server sqlplus

# Or with connection string
docker exec -it sandbox-oracle-database sqlplus / as sysdba
```

<br>

#### Connection Parameters

| Parameter | Environment Variable | Default Value | Description |
|-----------|---------------------|---------------|-------------|
| **Hostname** | `SANDBOX_DB_HOST` | `sandbox-oracle-database` | Database container name |
| **Port** | `SANDBOX_DB_PORT` | `1521` | Listener port |
| **Service Name** | `SANDBOX_DB_SERVICE` | `FREE` | Database service |
| **SID** | `SANDBOX_DB_SID` | `FREE` | System identifier |
| **PDB Name** | - | `FREEPDB1` | Pluggable database |
| **Admin User** | - | `SYS` / `SYSTEM` | Administrative accounts |
| **Admin Password** | `ENV_DB_PASSWORD` | *from .env* | Set during setup |

<br>

#### Connection Pool Configuration

For Node.js applications using the management server:

| Setting | Environment Variable | Default | Description |
|---------|---------------------|---------|-------------|
| **Minimum Connections** | `SANDBOX_DB_POOL_MIN` | `1` | Minimum pool size |
| **Maximum Connections** | `SANDBOX_DB_POOL_MAX` | `5` | Maximum pool size |
| **Pool Increment** | `SANDBOX_DB_POOL_INCREMENT` | `1` | Growth increment |

<br> 

## Connection String Formats

#### EZ Connect Format
```
hostname:port/service_name
sandbox-oracle-database:1521/FREE
```

#### TNS Format
```
(DESCRIPTION=
  (ADDRESS=(PROTOCOL=TCP)(HOST=sandbox-oracle-database)(PORT=1521))
  (CONNECT_DATA=(SERVICE_NAME=FREE))
)
```

#### JDBC Format
```
jdbc:oracle:thin:@sandbox-oracle-database:1521:FREE
```

### External Connections

To connect from outside the Docker network:

```bash
# Update hostname to localhost or host IP
sql username/password@localhost:1521/FREE

# Or using IP address
sql username/password@192.168.1.110:1521/FREE
```

### Common Connection Examples

```bash
# Connect as SYS with SYSDBA privileges
docker exec -it sandbox-oracle-server bash -c "sql sys/${ENV_DB_PASSWORD}@sandbox-oracle-database:1521/FREE as sysdba"

# Connect to pluggable database
docker exec -it sandbox-oracle-server bash -c "sql system/${ENV_DB_PASSWORD}@sandbox-oracle-database:1521/FREEPDB1"

# Connect with specific schema
docker exec -it sandbox-oracle-server bash -c "sql your_user/your_password@sandbox-oracle-database:1521/FREE"
```
