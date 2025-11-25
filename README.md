# 🚀 Oracle Database 23ai Free - Docker Development Kit

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Oracle](https://img.shields.io/badge/Oracle-23ai_Free-F80000?style=flat&logo=oracle&logoColor=white)
[![Database](https://img.shields.io/badge/Oracle%20DB-23ai-blue.svg)](https://www.oracle.com/database/free/)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org)
[![APEX](https://img.shields.io/badge/APEX-24.2-red.svg)](https://apex.oracle.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/demasy/oracle-database/pulls)

> **⚠️ FOR DEVELOPMENT & TRAINING ONLY - NOT FOR PRODUCTION USE**
> 
> **Complete containerized Oracle 23ai Free Edition with APEX & ORDS - Perfect for developers, DBAs, and learners!**

## Overview

A fully containerized Oracle Database 23ai **development and training environment** that combines enterprise database capabilities with modern development tools. This solution provides developers, DBAs, and learners with an isolated, reproducible workspace for Oracle Database development, testing, and hands-on learning.

> **⚠️ Important Notice:** This environment is designed exclusively for **development, testing, and training purposes**. It is **NOT recommended for production deployments**. For production use, please refer to [Oracle's official production deployment guidelines](https://www.oracle.com/database/).

### Key Features

- **Oracle Database 23ai Free** - Latest Oracle technology with AI-powered features
- **Oracle APEX 24.2.0** - Low-code application development platform
- **Oracle ORDS 25.3** - RESTful web services and SQL Developer Web
- **Oracle SQLcl 25.3** - Modern command-line SQL interface
- **Node.js Management Layer** - Health monitoring and API endpoints
- **Docker-based Architecture** - Consistent deployment across environments
- **Instant Client 23.7** - Oracle database connectivity libraries

### Use Cases

| Use Case | Description |
|----------|-------------|
| **Application Development** | Build and test Oracle-backed applications in an isolated environment |
| **Database Administration** | Practice DBA tasks, test procedures, and learn administration |
| **APEX Development** | Develop low-code applications with full APEX capabilities |
| **CI/CD Integration** | Automated testing pipelines with consistent database state |
| **Training & Education** | Hands-on Oracle Database learning without complex setup |
| **Proof of Concept** | Rapid prototyping and feature validation |

### Architecture Highlights

```
┌───────────────────────────────────────────────────────┐
│                   Docker Environment                  │
│                                                       │
│  ┌──────────────────┐         ┌──────────────────┐    │
│  │  Management      │         │  Oracle Database │    │
│  │  Server          │◄────────┤  23ai Free       │    │
│  │  (Node.js)       │         │  + APEX 24.2     │    │
│  │                  │         │  + ORDS 25.3     │    │
│  │  - Health Check  │         │                  │    │
│  │  - API Endpoints │         │  Ports:          │    │
│  │  - SQLcl Client  │         │  - 1521 (DB)     │    │
│  │                  │         │  - 5500 (EM)     │    │
│  │  Port: 3000      │         │  - 8080 (ORDS)   │    │
│  └──────────────────┘         └──────────────────┘    │
│      192.168.1.20                192.168.1.10         │
└───────────────────────────────────────────────────────┘
```

---

<br>

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Oracle APEX Setup](#oracle-apex-setup)
- [Database Connectivity](#database-connectivity)
- [Service Management](#service-management)
- [Monitoring & Logs](#monitoring--logs)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Change Log](#change-log)
- [Contributing](#contributing)
- [License](#license)

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Docker Engine** | 24.0.0+ | Latest stable |
| **Docker Compose** | v2.20.0+ | Latest stable |
| **RAM** | 4 GB | 8 GB or more |
| **Storage** | 10 GB | 20 GB or more |
| **CPU** | 2 cores | 4 cores or more |

### Required Ports

Ensure the following ports are available:

| Port | Service | Protocol |
|------|---------|----------|
| 1521 | Oracle Database Listener | TCP |
| 5500 | Enterprise Manager Express | HTTP |
| 3000 | Management API | HTTP |
| 8080 | Oracle ORDS/APEX | HTTP |

### Software Prerequisites

- Git for repository cloning
- Text editor for configuration files
- Modern web browser for APEX and EM access
- Basic understanding of Docker and containerization

### Network Requirements

- Internet connection for initial setup (downloading images)
- Subnet 192.168.1.0/24 available for container networking
- No firewall blocking Docker container communication

<br>

## Quick Start

### Step 1: Clone Repository

```bash
git clone https://github.com/demasy/oracle-database.git
cd oracle-database
```

### Step 2: Environment Configuration

#### Create Environment File

```bash
cp .env.example .env
chmod 600 .env
```

#### Configure Required Variables

Edit `.env` and set the following required parameters:

```bash
# Database Configuration (Required)
ORACLE_PWD=YourSecurePassword123!    # ⚠️ CHANGE THIS! Minimum 8 characters
DATABASE_NAME=DEMASY                 # Maximum 8 characters
TZ=Asia/Riyadh                       # Your timezone

# APEX Configuration (Required for APEX setup)
ENV_APEX_ADMIN_USERNAME=ADMIN
ENV_APEX_ADMIN_PASSWORD=YourAPEXPassword123  # ⚠️ CHANGE THIS!
ENV_APEX_EMAIL=your-email@example.com       # ⚠️ CHANGE THIS!
ENV_APEX_DEFAULT_WORKSPACE=INTERNAL
```

#### Optional Configuration

```bash
# Connection Pool Settings
DEMASYLABS_DB_POOL_MIN=1
DEMASYLABS_DB_POOL_MAX=5
DEMASYLABS_DB_POOL_INCREMENT=1

# Network Configuration
DEMASYLABS_DB_HOST=oracle-database-23ai
DEMASYLABS_DB_PORT=1521
DEMASYLABS_DB_SERVICE=FREE
```

> **Security Best Practices:**
> - Use strong passwords with mixed case, numbers, and symbols
> - Never commit `.env` files to version control
> - Restrict file permissions to owner only (`chmod 600`)
> - Rotate passwords regularly in production environments
> - Use different credentials for each environment

### Step 3: Build Services

Build the Docker images with a clean build:

```bash
docker-compose build --no-cache
```

**Build time:** Approximately 10-15 minutes (first build)

### Step 4: Start Services

#### Option A: Production Mode (Recommended)

Start all services in detached mode:

```bash
docker-compose up -d
```

#### Option B: Development Mode

Start with real-time logs for debugging:

```bash
docker-compose up
```

To stop, press `Ctrl+C` and run:
```bash
docker-compose down
```

#### Option C: Selective Services

Start only specific services:

```bash
# Database only
docker-compose up -d demasylabs-oracle-database

# Management server only
docker-compose up -d demasylabs-oracle-server
```

### Step 5: Verify Installation

#### 1. Check Container Status

```bash
docker ps --filter "name=oracle-database-23ai" --filter "name=demasy-server"
```

**Expected output:**
```
CONTAINER ID   IMAGE                    STATUS                    PORTS
abc123def456   oracle-database:23ai     Up 2 minutes (healthy)    0.0.0.0:1521->1521/tcp
def456ghi789   demasy-server:latest     Up 2 minutes (healthy)    0.0.0.0:3000->3000/tcp
```

#### 2. Wait for Database Initialization

Monitor database startup (takes 5-10 minutes on first run):

```bash
docker logs -f oracle-database-23ai
```

**Look for:** `DATABASE IS READY TO USE!`

#### 3. Verify Health Endpoints

Test the management server:

```bash
curl http://localhost:3000/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-25T12:00:00.000Z"
}
```

#### 4. Test Database Connection

Access the management container:

```bash
docker exec -it demasy-server bash
```

Connect to the database:

```bash
sqlcl
```

**Expected output:**
```
SQLcl: Release 25.3 Production
Connected to: Oracle Database 23ai Free
```

### Quick Start Summary

```bash
# 1. Clone and setup
git clone https://github.com/demasy/oracle-database.git
cd oracle-database
cp .env.example .env
# Edit .env with your configuration

# 2. Build and start
docker-compose build --no-cache
docker-compose up -d

# 3. Verify
docker ps
docker logs -f oracle-database-23ai  # Wait for "READY TO USE"
curl http://localhost:3000/health

# 4. Connect
docker exec -it demasy-server sqlcl
```

---

## Architecture

The environment consists of two main containerized services:

### Database Service (`demasylabs-oracle-database`)

| Component | Details |
|-----------|---------|
| Base Image | Oracle Free Database 23c |
| Container Name | `oracle-database-23ai` |
| Database Name | DEMASY |
| Exposed Ports | • 1521 (Database Listener)<br>• 5500 (Enterprise Manager Express) |
| Network | 192.168.1.10 |
| Resources | • CPU: 1 core<br>• Memory: 3GB |
| Health Check | Every 30s via SQL connectivity test |

### Management Server (`demasylabs-oracle-server`)

| Component | Details |
|-----------|---------|
| Base Image | Node.js 20.19.4 |
| Container Name | `demasy-server` |
| Exposed Port | 3000 (API & Health Check) |
| Network | 192.168.1.20 |
| Resources | • CPU: 1 core<br>• Memory: 512MB |
| Integrations | • Oracle SQLcl<br>• Oracle APEX<br>• Oracle Instant Client 23.7 |
| Connection Pool | • Min: 1<br>• Max: 5<br>• Increment: 1 |

---

## Service Management

### Container Operations

#### Database Service

##### Stop Database
```bash
docker stop oracle-database-23ai
```

##### Start Database
```bash
docker start oracle-database-23ai
```

##### Restart Database
```bash
docker restart oracle-database-23ai
```

##### Remove Database Container
```bash
docker rm -f oracle-database-23ai
```

##### Access Database Shell
```bash
docker exec -it oracle-database-23ai bash
```

##### View Database Logs
```bash
# View all logs
docker logs oracle-database-23ai

# Follow logs in real-time
docker logs -f oracle-database-23ai

# View last 100 lines
docker logs --tail 100 oracle-database-23ai

# View logs with timestamps
docker logs -t oracle-database-23ai
```

##### Monitor Database
```bash
# View container details
docker inspect oracle-database-23ai

# View resource usage
docker stats oracle-database-23ai

# Check container health
docker inspect --format='{{.State.Health.Status}}' oracle-database-23ai
```

##### Database Port Status
```bash
# Check if database port is listening
netstat -an | grep 1521

# Check Enterprise Manager Express port
netstat -an | grep 5500
```

##### Backup Database
```bash
# Create a backup of the container
docker commit oracle-database-23ai oracle-db-backup:$(date +%Y%m%d)
```

#### Management Server

##### Stop Server
```bash
docker stop demasy-server
```

##### Start Server
```bash
docker start demasy-server
```

##### Restart Server
```bash
docker restart demasy-server
```

##### Remove Container
```bash
docker rm -f demasy-server
```

##### Access Shell
```bash
docker exec -it demasy-server bash
```

##### View Logs
```bash
# View all logs
docker logs demasy-server

# Follow logs in real-time
docker logs -f demasy-server

# View last 100 lines
docker logs --tail 100 demasy-server
```

##### Check Container Status
```bash
# View container details
docker inspect demasy-server

# View resource usage
docker stats demasy-server
```

---

## Oracle APEX Setup

Oracle Application Express (APEX) 24.2.0 is included as a low-code development platform for building web applications.

### Installation

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

**Installation time:** Approximately 5-7 minutes

**Installation process:**
1. Creates required tablespaces (APEX, APEX_FILES)
2. Installs APEX core schema and metadata
3. Configures APEX REST APIs
4. Installs and configures ORDS
5. Creates ADMIN user in INTERNAL workspace
6. Starts ORDS listener on port 8080

### Access Endpoints

After successful installation:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Application Builder** | http://localhost:8080/ords/f?p=4550:1 | Workspace: `INTERNAL`<br>Username: `ADMIN`<br>Password: See `.env` (`ENV_APEX_ADMIN_PASSWORD`) |
| **SQL Developer Web** | http://localhost:8080/ords/sql-developer/ | Username: `ADMIN`<br>Password: See `.env` (`ENV_APEX_ADMIN_PASSWORD`) |
| **APEX Administration** | http://localhost:8080/ords/apex_admin | Username: `ADMIN`<br>Password: See `.env` (`ENV_APEX_ADMIN_PASSWORD`) |

> **Security Note:** All passwords are configured in the `.env` file. Ensure you change all default passwords before deployment. Never commit `.env` to version control.

### APEX Management Commands

```bash
# Check ORDS status
docker exec demasy-server netstat -tulnp | grep :8080

# View ORDS logs in real-time
docker exec demasy-server tail -f /tmp/ords.log

# Restart ORDS service
docker exec demasy-server stop-ords
docker exec demasy-server start-ords
```

### Available Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `install-apex` | One-time APEX + ORDS installation | `docker exec demasy-server install-apex` |
| `start-ords` | Start ORDS listener | `docker exec demasy-server start-ords` |
| `stop-ords` | Stop ORDS listener | `docker exec demasy-server stop-ords` |

### Troubleshooting APEX

#### ORDS Not Starting

```bash
# Check for port conflicts
docker exec demasy-server netstat -tulnp | grep :8080

# View detailed logs
docker exec demasy-server cat /tmp/ords.log
```

#### Images Not Loading

```bash
# Verify images directory
docker exec demasy-server ls -la /tmp/i | wc -l
# Should show ~27000 files

# Restart ORDS if needed
docker exec demasy-server stop-ords && docker exec demasy-server start-ords
```

#### Login Issues

- Verify you're using workspace: `INTERNAL` (case-sensitive)
- Ensure username is `ADMIN` (all uppercase)
- Check ORDS is running on port 8080

For comprehensive APEX documentation, see [APEX-GUIDE.md](APEX-GUIDE.md)

---

## Database Connectivity

### Connection Methods

#### Method 1: Oracle SQLcl (Recommended)

Modern command-line interface with enhanced features:

```bash
# From host machine (requires container access)
docker exec -it demasy-server sqlcl

# Or use the preconfigured alias
docker exec -it demasy-server oracle
```

**Features:**
- Auto-completion and command history
- Modern SQL formatting
- Built-in scripting capabilities
- No separate installation required

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
docker exec -it demasy-server bash -c "sql system/${ORACLE_PWD}@oracle-database-23ai:1521/FREE"

# Example - Connect as SYSDBA
docker exec -it demasy-server bash -c "sql sys/${ORACLE_PWD}@oracle-database-23ai:1521/FREE as sysdba"
```

#### Method 4: SQL*Plus (Traditional)

For compatibility with legacy scripts:

```bash
docker exec -it demasy-server sqlplus

# Or with connection string
docker exec -it oracle-database-23ai sqlplus / as sysdba
```

### Connection Parameters

| Parameter | Environment Variable | Default Value | Description |
|-----------|---------------------|---------------|-------------|
| **Hostname** | `DEMASYLABS_DB_HOST` | `oracle-database-23ai` | Database container name |
| **Port** | `DEMASYLABS_DB_PORT` | `1521` | Listener port |
| **Service Name** | `DEMASYLABS_DB_SERVICE` | `FREE` | Database service |
| **SID** | `DEMASYLABS_DB_SID` | `FREE` | System identifier |
| **PDB Name** | - | `FREEPDB1` | Pluggable database |
| **Admin User** | - | `SYS` / `SYSTEM` | Administrative accounts |
| **Admin Password** | `ORACLE_PWD` | *from .env* | Set during setup |

### Connection Pool Configuration

For Node.js applications using the management server:

| Setting | Environment Variable | Default | Description |
|---------|---------------------|---------|-------------|
| **Minimum Connections** | `DEMASYLABS_DB_POOL_MIN` | `1` | Minimum pool size |
| **Maximum Connections** | `DEMASYLABS_DB_POOL_MAX` | `5` | Maximum pool size |
| **Pool Increment** | `DEMASYLABS_DB_POOL_INCREMENT` | `1` | Growth increment |

### Connection String Formats

#### EZ Connect Format
```
hostname:port/service_name
oracle-database-23ai:1521/FREE
```

#### TNS Format
```
(DESCRIPTION=
  (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-database-23ai)(PORT=1521))
  (CONNECT_DATA=(SERVICE_NAME=FREE))
)
```

#### JDBC Format
```
jdbc:oracle:thin:@oracle-database-23ai:1521:FREE
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
docker exec -it demasy-server bash -c "sql sys/${ORACLE_PWD}@oracle-database-23ai:1521/FREE as sysdba"

# Connect to pluggable database
docker exec -it demasy-server bash -c "sql system/${ORACLE_PWD}@oracle-database-23ai:1521/FREEPDB1"

# Connect with specific schema
docker exec -it demasy-server bash -c "sql your_user/your_password@oracle-database-23ai:1521/FREE"
```

---

## Monitoring & Logs

### Health Monitoring

#### Automated Health Checks

Both containers implement automated health monitoring:

- **Check Interval:** Every 30 seconds
- **Timeout:** 5 seconds
- **Start Period:** 10 seconds
- **Retries:** 3 attempts before marking unhealthy

#### Health Check Methods

**Method 1: HTTP Endpoint**

```bash
curl http://localhost:3000/health
```

**Response (Healthy):**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-25T12:00:00.000Z",
  "uptime": 3600,
  "database": "connected"
}
```

**Method 2: Docker Inspect**

```bash
docker inspect --format='{{.State.Health.Status}}' demasy-server
docker inspect --format='{{.State.Health.Status}}' oracle-database-23ai
```

**Method 3: Built-in Command**

```bash
docker exec demasy-server healthcheck
```

**Expected output:**
```
Server is healthy.
```

### Log Management

#### Database Logs

**Configuration:**
- **Driver:** JSON file
- **Max Size:** 10MB per file
- **Max Files:** 3 (rotation)
- **Total Size:** ~30MB

**Access database logs:**

```bash
# View all logs
docker logs oracle-database-23ai

# Follow logs in real-time
docker logs -f oracle-database-23ai

# View last 100 lines
docker logs --tail 100 oracle-database-23ai

# View with timestamps
docker logs -t oracle-database-23ai

# Filter by time
docker logs --since 1h oracle-database-23ai
docker logs --since 2025-11-25T10:00:00 oracle-database-23ai
```

#### Management Server Logs

```bash
# View application logs
docker logs demasy-server

# Follow logs
docker logs -f demasy-server

# View with grep filter
docker logs demasy-server 2>&1 | grep ERROR
```

#### Application Logs Volume

Persistent logs are stored in the `demasylabs_logs` volume:

```bash
# Inspect volume
docker volume inspect demasylabs_logs

# Access logs from host
docker run --rm -v demasylabs_logs:/logs alpine ls -la /logs
```

#### APEX/ORDS Logs

```bash
# ORDS server logs
docker exec demasy-server tail -f /tmp/ords.log

# APEX installation logs
docker exec demasy-server tail -f /tmp/apex_install.log

# ORDS configuration logs
docker exec demasy-server cat /tmp/ords_install.log
```

### Resource Monitoring

#### Real-time Resource Usage

```bash
# Monitor all containers
docker stats

# Monitor specific container
docker stats oracle-database-23ai

# One-time snapshot
docker stats --no-stream
```

**Output includes:**
- CPU usage percentage
- Memory usage and limit
- Memory percentage
- Network I/O
- Block I/O
- Process count

#### Container Details

```bash
# Full container inspection
docker inspect oracle-database-23ai

# Get specific information
docker inspect --format='{{.State.Status}}' oracle-database-23ai
docker inspect --format='{{.NetworkSettings.IPAddress}}' oracle-database-23ai
```

### Performance Monitoring

#### Database Performance

```bash
# Connect to database
docker exec -it oracle-database-23ai sqlplus / as sysdba

# Run performance queries
SELECT * FROM V$SESSION WHERE USERNAME IS NOT NULL;
SELECT * FROM V$SQL WHERE ELAPSED_TIME > 1000000;
SELECT * FROM V$SYSTEM_EVENT;
```

#### Process Monitoring

```bash
# List running processes in container
docker exec demasy-server ps aux

# Check ORDS process
docker exec demasy-server netstat -tulnp | grep :8080

# Monitor Java processes
docker exec demasy-server jps -v
```

### Alert Configuration

#### Email Notifications (Optional)

Configure Docker to send alerts for container events:

```yaml
# docker-compose.yml
services:
  demasylabs-oracle-database:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "production"
```

#### Log Aggregation

For production environments, consider integrating with:
- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Grafana + Prometheus**
- **Splunk**
- **DataDog**

---

## Configuration Reference

### Network Configuration

| Component | Value | Description |
|-----------|-------|-------------|
| **Network Name** | `demasylabs_network` | Custom Docker bridge network |
| **Subnet** | `192.168.1.0/24` | Network CIDR |
| **Database IP** | `192.168.1.10` | Static IP for database container |
| **Server IP** | `192.168.1.20` | Static IP for management server |
| **Gateway** | `192.168.1.1` | Network gateway |

### Environment Variables Reference

#### Database Configuration

```bash
# Core Settings
ORACLE_PWD=                    # Required: Database system password (⚠️ CHANGE THIS!)
DATABASE_NAME=DEMASY           # Database name (max 8 chars)
TZ=Asia/Riyadh                # Timezone

# Connection Settings
DEMASYLABS_DB_HOST=oracle-database-23ai
DEMASYLABS_DB_PORT=1521
DEMASYLABS_DB_SERVICE=FREE
DEMASYLABS_DB_SID=FREE
DEMASYLABS_DB_USER=system
DEMASYLABS_DB_PASSWORD=${ORACLE_PWD}
```

#### APEX Configuration

```bash
ENV_APEX_ADMIN_USERNAME=ADMIN
ENV_APEX_ADMIN_PASSWORD=        # Required: APEX admin password (⚠️ CHANGE THIS!)
ENV_APEX_EMAIL=                 # Required: Your email address (⚠️ CHANGE THIS!)
ENV_APEX_DEFAULT_WORKSPACE=INTERNAL
ENV_APEX_HOME=/opt/oracle/apex
ENV_APEX_IMAGES_DIR=/tmp/i
```

#### Connection Pool

```bash
DEMASYLABS_DB_POOL_MIN=1
DEMASYLABS_DB_POOL_MAX=5
DEMASYLABS_DB_POOL_INCREMENT=1
```

#### ORDS Configuration

```bash
ENV_ORDS_PORT=8080
ENV_ORDS_HOME=/opt/oracle/ords
ENV_ORDS_CONFIG=/opt/oracle/ords/config
ENV_ORDS_JDBC_MIN_LIMIT=3
ENV_ORDS_JDBC_MAX_LIMIT=20
```

### Container Resource Limits

#### Database Container

```yaml
resources:
  limits:
    cpus: '1'
    memory: 3GB
  reservations:
    cpus: '0.5'
    memory: 2GB
```

#### Management Server

```yaml
resources:
  limits:
    cpus: '1'
    memory: 512MB
  reservations:
    cpus: '0.25'
    memory: 256MB
```

### Volume Mounts

| Volume | Mount Point | Purpose |
|--------|-------------|---------|
| `demasylabs_logs` | `/home/oracle/logs` | Application logs |
| Database datafiles | `/opt/oracle/oradata` | Database files (internal) |
| APEX images | `/tmp/i` | APEX static assets |
| ORDS config | `/opt/oracle/ords/config` | ORDS configuration |

---

## Troubleshooting

### Common Issues

#### Port Already in Use

**Symptom:** Container fails to start with port binding error

**Solution:**
```bash
# Check what's using the port
lsof -i :1521
netstat -an | grep 1521

# Stop conflicting service or change port in docker-compose.yml
```

#### Database Initialization Timeout

**Symptom:** Database takes longer than 10 minutes to initialize

**Solution:**
```bash
# Increase timeout in healthcheck
# Check available resources
docker system df
docker system prune  # Free up space

# Monitor initialization
docker logs -f oracle-database-23ai
```

#### APEX Installation Fails

**Symptom:** `install-apex` command returns errors

**Solution:**
```bash
# Check database is running
docker exec -it oracle-database-23ai sqlplus / as sysdba

# Review installation logs
docker exec demasy-server cat /tmp/apex_install.log

# Verify connectivity
docker exec demasy-server ping oracle-database-23ai
```

#### Connection Refused

**Symptom:** Cannot connect to database

**Solution:**
```bash
# Verify database is healthy
docker ps --filter "name=oracle-database-23ai"

# Check listener status
docker exec oracle-database-23ai lsnrctl status

# Verify network connectivity
docker exec demasy-server ping oracle-database-23ai

# Check firewall rules
sudo iptables -L
```

#### Images Not Loading in APEX

**Symptom:** APEX UI shows missing images

**Solution:**
```bash
# Verify images directory
docker exec demasy-server ls -la /tmp/i | wc -l

# Should show ~27000 files
# If empty, reinstall APEX or restart ORDS

docker exec demasy-server stop-ords
docker exec demasy-server start-ords
```

### Getting Help

1. **Check Logs:** Always start with container logs
2. **Verify Configuration:** Double-check `.env` file
3. **Resource Check:** Ensure sufficient CPU/memory
4. **Network Test:** Verify container connectivity
5. **GitHub Issues:** Open an issue with logs and configuration

### Diagnostic Commands

```bash
# System information
docker version
docker-compose version
docker info

# Container diagnostics
docker ps -a
docker inspect <container_id>
docker logs <container_id>

# Network diagnostics
docker network ls
docker network inspect demasylabs_network

# Volume diagnostics
docker volume ls
docker volume inspect demasylabs_logs

# Resource usage
docker stats --no-stream
df -h
free -m
```

### Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/oracle-database.git

# Add upstream remote
git remote add upstream https://github.com/demasy/oracle-database.git

# Create feature branch
git checkout -b feature/your-feature

# Make changes and test
docker-compose build
docker-compose up -d

# Submit PR
git push origin feature/your-feature
```

### Reporting Issues

When reporting issues, please include:
- Environment details (OS, Docker version)
- Complete error messages and logs
- Steps to reproduce
- Expected vs actual behavior
- Relevant configuration files (sanitized)

---

## Change Log

| Version | Date | Type | Description |
|---------|------|------|-------------|

---

## Contributors

| Author | GitHub & LinkedIn account |
| :-  | :---- |
| Ahmed El-Demasy (Original Author) | <a href="https://github.com/demasy">Github</a> & <a href="https://www.linkedin.com/in/demasy">LinkedIn</a> |
<br>

 ### Contributing to the Oracle Database Free on Docker.
We welcome you to join and contribute to the Oracle FNDLOAD Scripts. If you are interested in helping, please don’t hesitate to contact on e-mail: founder@demasy.io

<br>

###### Suggestions & Issues
> If you find any issues or have a great idea in mind, please create an issue on <a href="https://github.com/demasy/oracle-database/issues">GitHub</a>.


<br>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

</br>

<!--
![Made with love in Egypt](https://madewithlove.now.sh/in?heart=true&template=for-the-badge)
-->
<p align="center">
Code with love ❤️ in Egypt for the Oracle development community.
</p>
