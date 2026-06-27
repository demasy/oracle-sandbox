# ORDS REST API & APEX

Oracle REST Data Services (ORDS) 26.1.2 is installed alongside APEX 26.1.0 and serves all web traffic on port `8080`. This page covers available endpoints, authentication, REST-enabling schemas, and curl examples.

---

## Quick reference

| URL | Purpose |
|-----|---------|
| `http://localhost:8080/ords/` | ORDS REST root |
| `http://localhost:8080/ords/f?p=4550:1` | APEX Application Builder |
| `http://localhost:8080/ords/apex_admin` | APEX Administration Console |
| `http://localhost:8080/ords/sandbox/_sdw/` | SQL Developer Web — SANDBOX workspace |
| `http://localhost:8080/ords/sql-developer/` | SQL Developer Web root |
| `http://localhost:8080/i/` | APEX static images (CSS, JS, icons) |

All URLs are available from the host machine once ORDS is running (`sb start apex`).

---

## Starting ORDS

```bash
# Start APEX + ORDS
sb start apex

# Verify ORDS is listening
curl -s http://localhost:8080/ords/ | jq '.links[0]'

# Check from the host
docker compose exec -T sandbox-oracle-server sb status
```

---

## APEX Application Builder

```
http://localhost:8080/ords/f?p=4550:1
```

| Credential | Value |
|------------|-------|
| Workspace | `SANDBOX` |
| Username | `ADMIN` (set via `ENV_APEX_ADMIN_USERNAME`) |
| Password | *(set via `ENV_APEX_ADMIN_PASSWORD` in `.env`)* |

---

## APEX Administration Console

```
http://localhost:8080/ords/apex_admin
```

Log in with the `INTERNAL` workspace admin credentials to manage workspaces, users, and system settings.

---

## SQL Developer Web

Browser-based SQL editor included with ORDS — no desktop install needed.

```bash
# Open SQL Developer Web for the SANDBOX workspace
open http://localhost:8080/ords/sandbox/_sdw/
```

Connect with any database user that has been REST-enabled for the workspace.

---

## REST-enabling a schema

ORDS exposes an Oracle schema as a REST endpoint via `ORDS_ADMIN.ENABLE_SCHEMA`. The SANDBOX schema is REST-enabled automatically during APEX installation.

### Enable a schema via SQL

Connect to the target PDB (e.g. `FREEPDB1`) and run:

```sql
BEGIN
    ORDS_ADMIN.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'MY_SCHEMA',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'my-schema',
        p_auto_rest_auth      => FALSE
    );
    COMMIT;
END;
/
```

The schema is now accessible at:

```
http://localhost:8080/ords/my-schema/
```

### Grant required privilege

```sql
GRANT INHERIT PRIVILEGES ON USER MY_SCHEMA TO ORDS_METADATA;
```

### Verify enablement

```bash
curl -s http://localhost:8080/ords/my-schema/ | jq '.items'
```

---

## Auto-REST endpoints

When a table or view is REST-enabled via ORDS, four standard endpoints are created automatically.

Enable a table:

```sql
BEGIN
    ORDS.ENABLE_OBJECT(
        p_enabled        => TRUE,
        p_schema         => 'SANDBOX',
        p_object         => 'EMPLOYEES',
        p_object_type    => 'TABLE',
        p_object_alias   => 'employees',
        p_auto_rest_auth => FALSE
    );
    COMMIT;
END;
/
```

### GET — query rows

```bash
# All rows (default limit: 25)
curl -s "http://localhost:8080/ords/sandbox/employees/" | jq '.items'

# Filter with q parameter (Oracle REST query-by-example)
curl -s "http://localhost:8080/ords/sandbox/employees/?q={\"department_id\":10}" | jq '.items'

# Pagination
curl -s "http://localhost:8080/ords/sandbox/employees/?offset=0&limit=10" | jq '.'
```

### GET — single row by primary key

```bash
curl -s "http://localhost:8080/ords/sandbox/employees/101" | jq '.'
```

### POST — insert a row

```bash
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"employee_id": 999, "first_name": "Ada", "last_name": "Lovelace", "email": "ada@example.com"}' \
  "http://localhost:8080/ords/sandbox/employees/"
```

### PUT — update a row

```bash
curl -s -X PUT \
  -H "Content-Type: application/json" \
  -d '{"first_name": "Ada", "last_name": "Lovelace", "email": "ada.updated@example.com"}' \
  "http://localhost:8080/ords/sandbox/employees/999"
```

### DELETE — delete a row

```bash
curl -s -X DELETE "http://localhost:8080/ords/sandbox/employees/999"
```

---

## Custom REST modules

Create custom endpoints with `ORDS.DEFINE_MODULE` for full control over URL patterns, HTTP methods, and PL/SQL handlers.

```sql
BEGIN
    -- Define the module
    ORDS.DEFINE_MODULE(
        p_module_name    => 'api.v1',
        p_base_path      => '/api/v1/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED'
    );

    -- Define a template (URL pattern)
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'api.v1',
        p_pattern        => 'status'
    );

    -- Define a GET handler
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'api.v1',
        p_pattern        => 'status',
        p_method         => 'GET',
        p_source_type    => ORDS.SOURCE_TYPE_QUERY,
        p_source         => 'SELECT ''OK'' AS status, SYSDATE AS timestamp FROM DUAL'
    );

    COMMIT;
END;
/
```

Call the custom endpoint:

```bash
curl -s "http://localhost:8080/ords/sandbox/api/v1/status" | jq '.'
```

---

## Authentication

By default, REST-enabled objects with `p_auto_rest_auth => FALSE` are publicly accessible. To protect endpoints with HTTP Basic Auth:

```sql
-- Enable auth on the module
ORDS.DEFINE_MODULE(
    p_module_name    => 'api.secure',
    p_base_path      => '/api/secure/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED'
);
```

Add ORDS credentials in APEX Admin → RESTful Services → Privileges.

Call a protected endpoint:

```bash
curl -s -u admin:password \
  "http://localhost:8080/ords/sandbox/api/secure/data" | jq '.'
```

---

## ORDS pool configuration

Connection pool settings are controlled via environment variables in `.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `ENV_ORDS_JDBC_MIN_LIMIT` | `3` | Minimum pool connections |
| `ENV_ORDS_JDBC_MAX_LIMIT` | `20` | Maximum pool connections |
| `ENV_ORDS_JDBC_INITIAL_LIMIT` | `3` | Connections created at startup |
| `ENV_ORDS_STATEMENT_TIMEOUT` | `900` | SQL statement timeout (seconds) |

Configuration file inside the container:

```
/opt/oracle/ords/config/databases/default/pool.xml
```

Global ORDS settings (REST SQL enabled, Database API enabled):

```
/opt/oracle/ords/config/global/settings.xml
```

---

## CLI shortcuts

```bash
# Install APEX + ORDS (first time)
sb install apex

# Start ORDS
sb start apex

# Stop ORDS
sb stop apex

# View ORDS logs
sb logs apex

# Full status
sb status
```

---

## Troubleshooting

**`curl` returns connection refused on port 8080**

ORDS is not running. Start it:

```bash
sb start apex
# or
docker compose exec sandbox-oracle-server sb start apex
```

**404 on `/ords/sandbox/`**

The SANDBOX schema may not be REST-enabled yet. Run the `ORDS_ADMIN.ENABLE_SCHEMA` block from the [REST-enabling a schema](#rest-enabling-a-schema) section above, connected to `FREEPDB1`.

**APEX images not loading (broken CSS/JS)**

The `/i/` path serves static assets from `/tmp/i` inside the container. If APEX was reinstalled, restart ORDS to pick up the new image path:

```bash
sb stop apex && sb start apex
```

**`ORA-01403: no data found` on REST endpoint**

The queried row does not exist. Verify with:

```bash
docker compose exec -T sandbox-oracle-server bash -c \
  "echo 'SELECT COUNT(*) FROM sandbox.employees; EXIT' | sql -name sandbox-sandbox-conn"
```

---

## Related

- [APEX Installation](./apex-installation.md) — full installation steps and configuration
- [Database Connectivity](./connectivity.md) — SQLcl and SQL*Plus connection methods
- [MCP Integration](../mcp/README.md) — AI-powered SQL via Model Context Protocol
- [Configuration Reference](../operations/configuration-reference.md) — all `ENV_*` variables
