# Oracle Sandbox Documentation

Welcome to the Oracle Sandbox documentation. Use the sections below to find guides by topic.

---

## General

| Document | Description |
|----------|-------------|
| [Quick Reference](./quick-reference.md) | One-page cheat sheet — commands, ports, URLs, connection strings |
| [FAQ](./faq.md) | Common questions about setup, database, APEX, MCP, and performance |

---

## CLI

| Document | Description |
|----------|-------------|
| [User Guide](./cli/user-guide.md) ⭐ | Complete reference for all `sandbox` commands, aliases, flags, and workflows |
| [Testing Guide](./cli/testing.md) | Test procedures, performance monitoring, and CI/CD integration |
| [Testing Framework](./cli/phase-7-testing.md) | Comprehensive testing framework details |

---

## API & Integrations

| Document | Description |
|----------|-------------|
| [Management API](./api/README.md) | REST health and status endpoints (`/health`, `/`) exposed by the Node.js server |
| [MCP Integration Guide](./mcp/README.md) ⭐ | Connect AI assistants (Claude, Copilot) directly to Oracle via the SQLcl MCP server |

---

## Database

| Document | Description |
|----------|-------------|
| [APEX Installation](./database/apex-installation.md) | APEX + ORDS setup, endpoints, and management commands |
| [Database Connectivity](./database/connectivity.md) | SQLcl, SQL*Plus, connection string formats |
| [ORDS REST API](./database/ords-rest-api.md) | ORDS endpoints, auto-REST, custom modules, and curl examples |
| [External Access](./database/external-access.md) | Connecting from host tools (SQL Developer, DBeaver, DataGrip) |

---

## Operations

| Document | Description |
|----------|-------------|
| [Configuration Reference](./operations/configuration-reference.md) | All `ENV_*` variables, resource limits, volumes, and port mapping |
| [Startup Configuration](./operations/startup-configuration.md) | APEX auto-install, startup timeouts, and boot behavior |
| [Service Management](./operations/service-management.md) | Container start/stop/restart, health checks, and diagnostics |
| [Monitoring & Logs](./operations/monitoring.md) | Health checks, log management, and resource monitoring |
| [Troubleshooting](./operations/troubleshooting.md) | Common issues and solutions |
| [Deployment Guide](./operations/deployment-guide.md) | Build, deploy, and operate the sandbox environment |
| [Tools Reference](./operations/tools-reference.md) | Built-in scripts and utilities reference |
| [Docker Publishing](./operations/docker-publishing.md) | Docker image publishing and versioning |

---

## Security

| Document | Description |
|----------|-------------|
| [Security Guide](./security/security.md) | Security best practices for this environment |
| [Security Audit](./security/security-audit.md) | Security assessment and findings |
| [Production Hardening](./security/production-hardening.md) | Enterprise hardening checklist |
