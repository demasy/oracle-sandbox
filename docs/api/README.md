# Management API Reference

The Oracle Sandbox includes a lightweight Node.js HTTP management server (`app.js`) that provides health monitoring and service introspection endpoints.

---

## Overview

| Property | Value |
|----------|-------|
| **Runtime** | Node.js 20 (native `node:http`) |
| **Default Port** | `3000` (override with `ENV_SERVER_PORT`) |
| **Default Host** | `127.0.0.1` |
| **Base URL** | `http://localhost:3000` |
| **Response Format** | JSON (`Content-Type: application/json; charset=utf-8`) |
| **No-cache** | All responses include `Cache-Control: no-store` |

---

## Endpoints

| Method | Path | Description | Status Codes |
|--------|------|-------------|--------------|
| `GET` | `/health` | System and database health check | `200`, `503` |
| `GET` | `/` | Service info and available endpoints | `200` |
| `*` | `/*` | All other paths | `404` |

---

## `GET /health`

Returns the current health of the management server and its database connectivity.

### Response: `200 OK` — Healthy

All required environment variables are set **and** the database connection probe succeeds.

```json
{
  "status": "healthy",
  "service": "oracle-sandbox-management",
  "uptimeSeconds": 3600,
  "checks": {
    "configuration": {
      "status": "pass",
      "missingEnv": []
    },
    "database": {
      "status": "pass"
    }
  }
}
```

### Response: `503 Service Unavailable` — Degraded

One or more checks failed (missing env vars, database unreachable, or module unavailable).

```json
{
  "status": "degraded",
  "service": "oracle-sandbox-management",
  "uptimeSeconds": 45,
  "checks": {
    "configuration": {
      "status": "fail",
      "missingEnv": ["SANDBOX_DB_HOST", "SANDBOX_DB_PORT"]
    },
    "database": {
      "status": "fail",
      "error": "ORA-12541: Cannot connect to Oracle..."
    }
  }
}
```

### `checks.database.status` values

| Value | Meaning |
|-------|---------|
| `pass` | `SELECT 1 FROM DUAL` succeeded |
| `fail` | Connection established but query failed |
| `unavailable` | `oracledb` module could not be loaded |
| `unconfigured` | One or more required env vars missing |
| `unknown` | Probe has not run yet (initial startup) |

### Database probe behavior

- The probe runs **once per 30 seconds** (TTL = `30 000 ms`). Subsequent requests within that window return the cached result.
- An initial non-blocking probe fires at server startup to warm the cache.
- Connection string format: `SANDBOX_DB_HOST:SANDBOX_DB_PORT/SANDBOX_DB_SERVICE`

### Required environment variables

| Variable | Purpose |
|----------|---------|
| `SANDBOX_DB_HOST` | Database hostname (e.g. `sandbox-oracle-database`) |
| `SANDBOX_DB_PORT` | Listener port (e.g. `1521`) |
| `SANDBOX_DB_SERVICE` | PDB service name (e.g. `FREEPDB1`) |
| `SANDBOX_DB_USER` | Database user for the health-check probe |
| `SANDBOX_DB_PASS` | Password for the probe user |

---

## `GET /`

Returns service identity and the health endpoint URL.

### Response: `200 OK`

```json
{
  "service": "oracle-sandbox-management",
  "health": "/health"
}
```

---

## Error responses

Any unmatched path returns:

```json
{"error": "not_found"}
```

Status code: `404 Not Found`

---

## curl examples

### Check health

```bash
curl -s http://localhost:3000/health | jq .
```

### Check health — exit with error if degraded

```bash
curl -sf http://localhost:3000/health > /dev/null && echo "OK" || echo "DEGRADED"
```

### Service info

```bash
curl -s http://localhost:3000/ | jq .
```

### One-liner status summary

```bash
curl -s http://localhost:3000/health | jq '.status, .checks.database.status'
```

---

## Docker health check

The Dockerfile configures Docker's built-in health check against this endpoint:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

Inspect health state from the host:

```bash
docker inspect sandbox-oracle-server --format '{{.State.Health.Status}}'
```

---

## Related

- [Service Management](../operations/service-management.md) — container start/stop and health monitoring
- [Monitoring & Logs](../operations/monitoring.md) — log access and resource monitoring
- [Troubleshooting](../operations/troubleshooting.md) — common issues
