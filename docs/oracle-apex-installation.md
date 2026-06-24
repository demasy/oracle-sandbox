# Oracle APEX Installation

Oracle Application Express (APEX) 24.2.0 is included as a low-code development platform for building web applications.

## Installation

Run the one-time installation command:

```bash
docker exec demasy-server install-apex
```

**Installation includes:**
- Oracle APEX 24.2.0 core components
- Oracle REST Data Services (ORDS) 25.3
- SQL Developer Web interface
- Static image serving configuration
- Workspace and admin user setup

> **Installation time:** Approximately 5-7 minutes

<br>

## Access Endpoints

After successful installation:

| Service | URL | 
|:---------:|:--------------------------------------------- |
| **Application Builder** | http://localhost:8080/ords/f?p=4550 | 
| **SQL Developer Web**   | http://localhost:8080/ords/sql-developer | 
| **APEX Administration** | http://localhost:8080/ords/apex_admin |

> Workspace: `INTERNAL`<br>Username: `ADMIN`<br>Password: See `.env` (`ENV_APEX_ADMIN_PASSWORD`) 

<br>

> **Security Note:** All passwords are configured in the `.env` file. Ensure you change all default passwords before deployment. Never commit `.env` to version control.

<br>

## APEX Management Commands

```bash
# Check ORDS status
docker exec demasy-server netstat -tulnp | grep:8080

# View ORDS logs in real-time 
docker exec demasy-server tail -f /tmp/ords.log

# Restart ORDS service
docker exec demasy-server stop-apex
docker exec demasy-server start-apex
```

## Available Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `install-apex` | One-time APEX + ORDS installation | `docker exec demasy-server install-apex` |
| `start-apex` | Start ORDS listener | `docker exec demasy-server start-apex` |
| `stop-apex` | Stop ORDS listener | `docker exec demasy-server stop-apex` |
| `uninstall-apex` | Remove APEX installation | `docker exec demasy-server uninstall-apex` |

## Troubleshooting APEX

### ORDS Not Starting

```bash
# Check for port conflicts
docker exec demasy-server netstat -tulnp | grep:8080

# View detailed logs 

```bash
docker exec demasy-server cat /tmp/ords.log
```

### Images Not Loading

```bash
# Verify images directory
docker exec demasy-server ls -la /tmp/i | wc -l
# Should show ~27000 files

# Restart ORDS if needed
docker exec demasy-server stop-apex && docker exec demasy-server start-apex
```

### Login Issues

- Verify you're using workspace: `INTERNAL` (case-sensitive)
- Ensure username is `ADMIN` (all uppercase)
- Check ORDS is running on port 8080
