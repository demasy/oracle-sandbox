# Oracle Database External Connection Guide

## Current Working Configuration ✅

Your Oracle database is **already accessible** from outside the Docker network via:

### 1. Port Forwarding (Recommended)
```bash
# Database Connection
sqlplus system/${ENV_DB_PASSWORD}@127.0.0.1:1521/FREEPDB1

# Alternative using localhost
sqlplus system/${ENV_DB_PASSWORD}@localhost:1521/FREEPDB1

# JDBC Connection String
jdbc:oracle:thin:@127.0.0.1:1521:FREE
# or
jdbc:oracle:thin:@127.0.0.1:1521/FREEPDB1
```

### 2. Available Services from Host
- **Oracle Database**: `127.0.0.1:1521`
- **APEX Web Interface**: `http://127.0.0.1:8080/ords/f?p=4550:1`
- **Management API**: `http://127.0.0.1:3000/health`
- **MCP Server**: `127.0.0.1:3001`

> **Note:** Enterprise Manager Express (port 5500) is **not available** in Oracle Database Free Edition.

### 3. Testing Connectivity
```bash
# Test port accessibility
nc -zv 127.0.0.1 1521

# Test with telnet (if available)
telnet 127.0.0.1 1521

# Test with curl for HTTP services
curl http://127.0.0.1:3000/health
curl http://127.0.0.1:8080/ords/f?p=4550:1
```

## Network Architecture

```
┌─── Host Machine ────────────────────────────────────────┐
│  127.0.0.1:1521  ←→  Port Forward  ←→  192.168.1.110:1521  │
│  127.0.0.1:8080  ←→  Port Forward  ←→  192.168.1.120:8080  │
│  127.0.0.1:3000  ←→  Port Forward  ←→  192.168.1.120:3000  │
│  127.0.0.1:3001  ←→  Port Forward  ←→  192.168.1.120:3001  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─── Docker Bridge Network (192.168.1.0/24) ─────────────┐
│                                                         │
│  ┌─── Oracle Database ─────┐  ┌─── Management Server ──┐│
│  │  192.168.1.110:1521     │  │  192.168.1.120:3000    ││
│  │  (TNS Listener)         │  │  192.168.1.120:8080    ││
│  └──────────────────────────┘  │  192.168.1.120:3001    ││
│                                 │  (ORDS/APEX/MCP)      ││
│                                 └────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

## Connection Examples

### SQL*Plus / SQLcl
```bash
# From macOS host
sqlplus system/${ENV_DB_PASSWORD}@127.0.0.1:1521/FREEPDB1

# From within management container
docker exec -it sandbox-oracle-server sqlcl
```

### Python (cx_Oracle)
```python
import os
import cx_Oracle

# Connection string for external access
connection = cx_Oracle.connect(
    user="system",
  password=os.environ["ENV_DB_PASSWORD"],
    dsn="127.0.0.1:1521/FREEPDB1"
)
```

### Java (JDBC)
```java
String url = "jdbc:oracle:thin:@127.0.0.1:1521:FREE";
String user = "system";
String password = System.getenv("ENV_DB_PASSWORD");

Connection conn = DriverManager.getConnection(url, user, password);
```

### Node.js (oracledb)
```javascript
const oracledb = require('oracledb');

const connection = await oracledb.getConnection({
  user: "system",
  password: process.env.ENV_DB_PASSWORD,
  connectString: "127.0.0.1:1521/FREEPDB1"
});
```

## Troubleshooting

### Check Services Status
```bash
# Check containers
docker ps

# Check port forwarding
netstat -an | grep -E "1521|3000|8080|3001"

# Check network connectivity
nc -zv 127.0.0.1 1521
```

### Common Connection Strings
```bash
# CDB Connection
system/${ENV_DB_PASSWORD}@127.0.0.1:1521:FREE

# PDB Connection (Recommended)
system/${ENV_DB_PASSWORD}@127.0.0.1:1521/FREEPDB1

# With explicit service
system/${ENV_DB_PASSWORD}@127.0.0.1:1521/FREEPDB1
```

## Security Notes

- Default credentials are configured in `.env` file
- Never hardcode credentials in scripts or source files
- Change default passwords for production use
- Database is accessible from any machine that can reach your host
- Consider firewall rules if needed

---
**Status**: ✅ Ready for external connections
**Updated**: January 15, 2026