# Database Builtin Objects Configuration

This directory contains the YAML-based configuration and SQL scripts for all database objects created during Docker image build.

## Overview

The builtin objects system enables **declarative database object management** for the Oracle Sandbox. Instead of imperative scripts, you define what objects should exist in YAML format, and the initialization system creates them automatically.

## Directory Structure

```
builtin-objects/
├── database-objects.yaml          # Main configuration file (declarative)
├── post-pdb-init.sql              # Post-PDB setup (synonyms, views, monitoring)
├── enable-ai-features.sql         # Oracle AI 26ai features (vectors, graphs, ML)
└── README.md                       # This file
```

## Files

### `database-objects.yaml`

**Purpose:** Declarative configuration of all database objects

**Contains:**
- PDB definitions (SANDBOX_PDB)
- Tablespace configurations
- User definitions with privilege levels
- Role definitions
- SQL script references
- Initialization sequence

**Privilege Levels:**
- `minimal` - Basic CONNECT + RESOURCE roles
- `normal` - SELECT_CATALOG_ROLE + cross-schema operations
- `all` - Full DBA + administrative privileges

**Example:**
```yaml
users:
  - username: sandbox
    privileges:
      level: minimal
  - username: demasy_ai
    privileges:
      level: all
```

### `post-pdb-init.sql`

**Purpose:** Post-PDB initialization SQL operations

**Executes After:**
- PDB is created
- Tablespaces are created
- Users are created with privileges

**Creates:**
- Public synonyms for common packages
- Package execution grants
- Monitoring views
- Audit logging
- Database parameter settings

### `enable-ai-features.sql`

**Purpose:** Enable Oracle AI Database 26ai features

**Features Enabled:**
- Vector Storage (Embeddings, AI/ML vectors)
- Graph Database Support
- JSON Search Index
- Full-Text Search (Oracle Text)
- Spatial Indexing
- Machine Learning Model Storage
- AI-Optimized Database Parameters

**Tables Created:**
- `ai_embeddings` - Vector embeddings storage for AI/ML
- `ml_models` - Machine learning model definitions
- `ml_predictions` - ML prediction results
- `property_graphs` - Graph database metadata

**Views Created:**
- `ai_features_status` - Feature availability check
- `ai_user_configuration` - AI user status

## Database Objects Created

### Databases
- **SANDBOX_PDB** - Main sandbox pluggable database

### Tablespaces
- `USERS` - Default user tablespace (1GB)
- `APEX_DATA` - APEX application data (500MB)
- `APP_DATA` - Application data storage (2GB)

### Users

| Username | Level | Purpose | Privileges |
|----------|-------|---------|-----------|
| `sandbox` | minimal | Development | CONNECT, RESOURCE, CREATE SESSION |
| `sandbox_ai` | normal | AI/MCP Service | CONNECT, RESOURCE, SELECT_CATALOG, CREATE ANY |
| `demasy` | normal | Developer | CONNECT, RESOURCE, SELECT_CATALOG, All DDL |
| `demasy_ai` | all | Advanced AI/Admin | DBA, All privileges, GRANT ANY |
| `apex_app` | normal | APEX Schema | APEX data operations |

### Roles
- `APP_DEVELOPER` - Standard developer permissions
- `APP_ADMIN` - Application admin permissions
- `APEX_DEVELOPER` - APEX development permissions

## Usage

### During Docker Build

The Dockerfile automatically processes these definitions:

```bash
# Triggers the initialization sequence
COPY src/builder/scripts/oracle/admin/builtin-objects/ /usr/sandbox/app/oracle/admin/builtin-objects/
```

### Programmatically (Future)

A `database-init.sh` script would parse the YAML and execute all definitions:

```bash
#!/bin/bash
# Parse database-objects.yaml
# For each database:
#   - Create PDB
#   - Create tablespaces
#   - Create users with privileges
#   - Create roles
#   - Execute SQL scripts
database-init.sh /path/to/database-objects.yaml
```

### Manual Execution

To manually run the SQL scripts:

```bash
# Connect to SANDBOX_PDB as SYSTEM
sql system/password@//host:1521/SANDBOX_PDB

# Run post-initialization
@/usr/sandbox/app/oracle/admin/builtin-objects/post-pdb-init.sql

# Run AI features
@/usr/sandbox/app/oracle/admin/builtin-objects/enable-ai-features.sql
```

## Key Design Decisions

### 1. Declarative Configuration (YAML)

**Why?**
- Declarative is easier to read and maintain
- Version-controlled with Git
- Easy to diff and review changes
- Can generate multiple initialization formats

### 2. Privilege Levels

**Why?**
- Simple enough for most use cases
- Clear separation of concerns
- Easy to audit and manage

### 3. Separate SQL Scripts

**Why?**
- Modular and focused
- Can be run independently
- Easy to debug and troubleshoot
- Reusable across different environments

### 4. Post-Initialization Scripts

**Why?**
- Allows flexible customization
- Can be versioned and reviewed separately
- Easier to add new objects without modifying YAML

## Adding New Objects

### To add a new user:

```yaml
users:
  - username: newuser
    password: "${SANDBOX_DB_PASSWORD}"
    default_tablespace: "USERS"
    privileges:
      level: "normal"
      roles:
        - "CONNECT"
        - "RESOURCE"
```

### To add a new tablespace:

```yaml
tablespaces:
  - name: "NEW_SPACE"
    size: "1G"
    autoextend: true
    description: "New tablespace for feature X"
```

### To add custom SQL:

1. Create a new SQL file in this directory
2. Reference it in `database-objects.yaml`:
   ```yaml
   scripts:
     - path: "src/builder/scripts/oracle/admin/builtin-objects/new-feature.sql"
       description: "Initialize feature X"
       runAs: "system"
   ```

## Environment Variables

All environment variables are resolved at initialization time:

| Variable | Example | Used For |
|----------|---------|----------|
| `${SANDBOX_DB_PASSWORD}` | Demasy1986 | User passwords |
| `${ORACLE_BASE}` | /opt/oracle | Oracle home paths |
| `${SANDBOX_PDB}` | SANDBOX_PDB | PDB names |

## Validation & Monitoring

### Verify Objects Were Created

```sql
-- Check users
SELECT username, account_status FROM dba_users 
WHERE username IN ('SANDBOX', 'DEMASY_AI', 'APEX_APP');

-- Check tablespaces
SELECT tablespace_name, status, contents FROM dba_tablespaces;

-- Check privileges
SELECT * FROM dba_role_privs WHERE grantee = 'DEMASY_AI';

-- Check AI features
SELECT * FROM ai_features_status;
```

### Check Initialization Log

```bash
docker compose logs oracle-database | grep "Initialization\|ERROR"
```

## Troubleshooting

### Issue: Users not created after rebuild

**Solution:**
1. Check `.env` file has `ENV_DB_PASSWORD` set
2. Verify YAML syntax: `yamllint database-objects.yaml`
3. Check Docker build logs for SQL errors
4. Run manual initialization inside container

### Issue: AI features not available

**Solution:**
1. Confirm Oracle Database 26ai (check version)
2. Check `enable-ai-features.sql` execution logs
3. Verify Oracle Text installed: `SELECT * FROM registry$ WHERE comp_name = 'Oracle Text'`

### Issue: Privilege grant failures

**Solution:**
1. Ensure users exist before granting privileges
2. Check user account status: `SELECT username, account_status FROM dba_users`
3. Verify SQL syntax in YAML user definitions

## Integration with Docker Build

The files in this directory are:
1. Copied into the Docker image during `docker compose build`
2. Located at `/usr/sandbox/app/oracle/admin/builtin-objects/` in container
3. Referenced by database initialization scripts
4. Can be run manually via `sql` commands inside container

## Performance Considerations

- Initialization runs once during image build (~5-10 minutes total)
- Subsequent starts use existing volumes (no re-initialization)
- To rebuild: `docker compose build --no-cache`
- To clean: `docker volume rm demasylabs_oracle_vol`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-06-23 | Initial YAML-based configuration |
| | | Created post-pdb-init.sql |
| | | Created enable-ai-features.sql |

## Related Documentation

- [main README.md](../../../../../README.md) - Project overview
- [docker-setup-sequence.md](../../../../docs/docker-setup-sequence.md) - Build process
- [sandbox-brain.json](../../../brain.json) - Project knowledge base
- [database-connectivity.md](../../../../docs/database-connectivity.md) - Connection info

## Support

For issues or improvements:
1. Check the [troubleshooting guide](../../../../docs/troubleshooting.md)
2. Review [GitHub Issues](https://github.com/demasy/oracle-sandbox/issues)
3. Contact: founder@demasy.io
