# Getting Started

This guide walks you through the first-time setup for Oracle Sandbox: cloning the repository, securing your environment file, starting the containers, verifying the services, and accessing the CLI.

Oracle Sandbox is intended for local development, testing, evaluation, and training. It is not a production-hardened environment.

## Before You Start

Make sure your machine has the following tools installed:

| Requirement | Minimum |
|-------------|---------|
| Operating system | Linux, macOS, or Windows with WSL2 |
| Docker Engine / Docker Desktop | Docker 24.0 or later |
| Docker Compose | Compose v2.20 or later |
| Git | Any current version |
| Memory | 6 GB minimum, 12 GB recommended |
| Disk space | 15 GB minimum, 25 GB recommended |

The first startup downloads Oracle and project images, so an internet connection is required.

## Default Local Ports

Oracle Sandbox binds published services to `127.0.0.1` by default.

| Port | Service |
|------|---------|
| `1521` | Oracle Database listener |
| `3000` | Management server and health API |
| `8080` | APEX and ORDS |
| `3001` | MCP server |

If one of these ports is already in use, update the matching value in `.env` before starting the containers.

## Quick Setup

```bash
# 1. Clone the repository
git clone https://github.com/demasy/oracle-sandbox.git
cd oracle-sandbox

# 2. Configure credentials (required - do not skip)
cp .env.example .env
# Edit .env and set ENV_DB_PASSWORD and ENV_APEX_ADMIN_PASSWORD

# 3. Build the Docker images
docker compose build --no-cache
```

## 1. Clone the Repository

```bash
git clone https://github.com/demasy/oracle-sandbox.git
cd oracle-sandbox
```

## 2. Create and Secure `.env`

Copy the example environment file:

```bash
cp .env.example .env
chmod 600 .env
```

Open `.env` in your editor and change all placeholder credentials before starting the containers.

Required values to review:

```bash
ENV_DB_PASSWORD=CHANGE_ME_SECURE_PASSWORD
ENV_APEX_ADMIN_PASSWORD=CHANGE_ME_SECURE_PASSWORD
ENV_APEX_ADMIN_EMAIL=your.email@example.com
ENV_APEX_EMAIL=your.email@example.com
```

Use strong passwords with at least 12 characters, mixed case letters, numbers, and symbols.

Do not commit `.env` to version control.

## 3. Build the Images

Use Docker Compose from the repository root:

```bash
docker compose build --no-cache
```

If your environment still uses the legacy Compose command, use:

```bash
docker-compose build --no-cache
```

## 4. Start Oracle Sandbox

Start all services in the background:

```bash
docker compose up -d
```

First startup can take several minutes while Oracle Database initializes.

Watch the database logs until the database reports that it is ready:

```bash
docker compose logs -f sandbox-oracle-database
```

Look for:

```text
DATABASE IS READY TO USE!
```

## 5. Verify the Environment

Check that both containers are running:

```bash
docker compose ps
```

Check the management server health endpoint:

```bash
curl http://localhost:3000/health
```

The response should report a healthy service with passing configuration checks.

## 6. Access the CLI

The `sandbox` CLI runs inside the management container.

Enter the container:

```bash
docker compose exec -it sandbox-oracle-server bash
```

Then run:

```bash
sandbox status all
sandbox help
```

Useful first commands:

```bash
sandbox status database
sandbox status apex
sandbox run sqlcl
sandbox logs all
```

## 7. Connect to the Database

From inside the management container, start SQLcl:

```bash
sandbox run sqlcl
```

You can also connect from local database tools using:

| Field | Value |
|-------|-------|
| Host | `localhost` |
| Port | `1521` |
| Service | `FREEPDB1` |
| User | `system` |
| Password | The value of `ENV_DB_PASSWORD` in `.env` |

EZ Connect format:

```text
system/<your-password>@localhost:1521/FREEPDB1
```

## 8. Access APEX and ORDS

If APEX and ORDS are enabled for automatic installation, wait for installation to complete during startup.

You can also install APEX and ORDS manually from inside the management container:

```bash
sandbox install apex
sandbox start apex
```

Common URLs:

| Service | URL |
|---------|-----|
| APEX Application Builder | `http://localhost:8080/ords/f?p=4550:1` |
| APEX Administration | `http://localhost:8080/ords/apex_admin` |
| SQL Developer Web | `http://localhost:8080/ords/sandbox/_sdw/` |
| ORDS root | `http://localhost:8080/ords/` |
| Health check | `http://localhost:3000/health` |

APEX administrator credentials are configured in `.env`:

| Credential | Source |
|------------|--------|
| Username | `ENV_APEX_ADMIN_USERNAME` |
| Password | `ENV_APEX_ADMIN_PASSWORD` |
| Email | `ENV_APEX_ADMIN_EMAIL` |

## 9. Stop or Restart

Stop the environment:

```bash
docker compose down
```

Start it again:

```bash
docker compose up -d
```

Restart a service:

```bash
docker compose restart sandbox-oracle-server
docker compose restart sandbox-oracle-database
```

## 10. Troubleshooting

If startup fails or a service is unhealthy, start with these checks:

```bash
docker compose ps
docker compose logs sandbox-oracle-database
docker compose logs sandbox-oracle-server
curl http://localhost:3000/health
```

Common issues:

| Issue | What to Check |
|-------|---------------|
| Port conflict | Make sure ports `1521`, `3000`, `8080`, and `3001` are available or update `.env`. |
| Database still starting | First startup can take 5-10 minutes or longer on slower machines. |
| APEX unavailable | Check ORDS status with `sandbox status apex` inside the management container. |
| Authentication failure | Confirm `.env` passwords match the credentials you are using. |
| Build download failure | Confirm internet access and retry the build. |

## Next Steps

- Read the [CLI Reference](cli-reference) for all `sandbox` commands.
- Review [Security and Hardening](security-and-hardening) before using real data.
- Use [Database Connectivity](database-connectivity) to connect external tools.
- Explore [APEX Installation](apex-installation) for APEX and ORDS details.
- See [Troubleshooting](troubleshooting) for common setup and runtime issues.
