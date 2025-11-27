# Database Connectivity

## Connection Methods

#### Method 1: Oracle SQLcl (Recommended)

Modern command-line interface with enhanced features:

```bash
# From host machine (requires container access)
docker exec -it demasy-server sqlcl

# Or use the preconfigured alias
docker exec -it demasy-server oracle
```


#### Method 2: SQL Command

Direct SQL connection using the `sql` wrapper:

```bash
docker exec -it demasy-server sql
```

#### Method 3: Custom Connection String

For specific user connections:

```bash
# Syntax
docker exec -it demasy-server bash -c "sql username/password@hostname:port/service"

# Example - Connect as SYSTEM
docker exec -it demasy-server bash -c "sql system/${ORACLE_PWD}@oracle-al-database-26ai:1521/FREE"

# Example - Connect as SYSDBA
docker exec -it demasy-server bash -c "sql sys/${ORACLE_PWD}@oracle-al-database-26ai:1521/FREE as sysdba"
```

#### Method 4: SQL*Plus (Traditional)

For compatibility with legacy scripts:

```bash
docker exec -it demasy-server sqlplus

# Or with connection string
docker exec -it oracle-al-database-26ai sqlplus / as sysdba
```

<br>

#### Connection Parameters

| Parameter | Environment Variable | Default Value | Description |
|-----------|---------------------|---------------|-------------|
| **Hostname** | `DEMASYLABS_DB_HOST` | `oracle-al-database-26ai` | Database container name |
| **Port** | `DEMASYLABS_DB_PORT` | `1521` | Listener port |
| **Service Name** | `DEMASYLABS_DB_SERVICE` | `FREE` | Database service |
| **SID** | `DEMASYLABS_DB_SID` | `FREE` | System identifier |
| **PDB Name** | - | `FREEPDB1` | Pluggable database |
| **Admin User** | - | `SYS` / `SYSTEM` | Administrative accounts |
| **Admin Password** | `ORACLE_PWD` | *from .env* | Set during setup |

<br>

#### Connection Pool Configuration

For Node.js applications using the management server:

| Setting | Environment Variable | Default | Description |
|---------|---------------------|---------|-------------|
| **Minimum Connections** | `DEMASYLABS_DB_POOL_MIN` | `1` | Minimum pool size |
| **Maximum Connections** | `DEMASYLABS_DB_POOL_MAX` | `5` | Maximum pool size |
| **Pool Increment** | `DEMASYLABS_DB_POOL_INCREMENT` | `1` | Growth increment |

<br> 

## Connection String Formats

#### EZ Connect Format
```
hostname:port/service_name
oracle-al-database-26ai:1521/FREE
```

#### TNS Format
```
(DESCRIPTION=
  (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-al-database-26ai)(PORT=1521))
  (CONNECT_DATA=(SERVICE_NAME=FREE))
)
```

#### JDBC Format
```
jdbc:oracle:thin:@oracle-al-database-26ai:1521:FREE
```

### External Connections

To connect from outside the Docker network:

```bash
# Update hostname to localhost or host IP
sql username/password@localhost:1521/FREE

# Or using IP address
sql username/password@192.168.1.10:1521/FREE
```

### Common Connection Examples

```bash
# Connect as SYS with SYSDBA privileges
docker exec -it demasy-server bash -c "sql sys/${ORACLE_PWD}@oracle-al-database-26ai:1521/FREE as sysdba"

# Connect to pluggable database
docker exec -it demasy-server bash -c "sql system/${ORACLE_PWD}@oracle-al-database-26ai:1521/FREEPDB1"

# Connect with specific schema
docker exec -it demasy-server bash -c "sql your_user/your_password@oracle-al-database-26ai:1521/FREE"
```
