# 🚀 Oracle AI Database 26ai Free - Docker Development Environment

<div align="center">

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Oracle](https://img.shields.io/badge/Oracle-26ai_Free-F80000?style=flat&logo=oracle&logoColor=white)
[![Database](https://img.shields.io/badge/Oracle%20AI%20DB-26ai-blue.svg)](https://www.oracle.com/database/free/)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org)
[![APEX](https://img.shields.io/badge/APEX-24.2-red.svg)](https://apex.oracle.com)
[![ORDS](https://img.shields.io/badge/ORDS-25.3-success.svg)](https://www.oracle.com/database/technologies/appdev/rest.html)
[![SQLcl](https://img.shields.io/badge/SQLcl-25.3-blueviolet.svg)](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/)
[![Made with Love](https://img.shields.io/badge/Made%20with-%E2%9D%A4%EF%B8%8F-red.svg)](https://github.com/demasy)

</div>

<br>

> **⚠️ DEVELOPMENT AND TRAINING ENVIRONMENT ONLY**
> 
> **Enterprise-grade containerized Oracle AI Database 26ai Free Edition with integrated APEX & ORDS. Purpose-built for professional developers, database administrators, and technical education.**

<br>

# Overview

A professionally architected, fully containerized Oracle AI Database 26ai **development and training environment** that seamlessly integrates enterprise-grade database capabilities with modern development tooling. This solution delivers a robust, isolated, and reproducible workspace for Oracle Database development, comprehensive testing, and professional training programs.

> **⚠️ Important Notice:** This environment has been specifically engineered for **development, testing, and educational purposes**. It is **not hardened or optimized for production deployments**. Organizations seeking production-ready solutions should consult [Oracle's official production deployment guidelines](https://www.oracle.com/database/) and engage with Oracle's enterprise support channels.

<br>

# 📑 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Oracle APEX Setup](#oracle-apex-setup)
- [Database Connectivity](#database-connectivity)
- [Service Management](#service-management)
- [Monitoring & Logs](#monitoring--logs)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Change Log](#-change-log)
- [Community & Contributing](#-community--contributing)
- [Code of Conduct](#-code-of-conduct)
- [Contributors](#-contributors)
- [Support](#-support-the-project)
- [License](#license)

<br>

## ✨ What's Included

#### 🗄️ **Oracle Database**
- **Oracle AI Database 26ai Free** - Latest release with AI capabilities
- **Pluggable Database (FREEPDB1)** - Multi-tenant architecture

#### 🛠️ **SQL Development Tools**
- **Oracle SQLcl 25.3** - Modern command-line interface
- **SQL*Plus** - Traditional SQL client
- **SQL Developer Web** - Browser-based SQL IDE

#### 🎨 **Low-Code Platform**
- **Oracle APEX 24.2.0** - Enterprise application development
- **Oracle ORDS 25.3** - RESTful web services

#### 🐳 **Docker Environment**
- **Docker Compose** - One-command deployment
- **Multi-architecture** - AMD64 & ARM64 support
- **Health Monitoring** - Built-in diagnostics

<br>

## Use Cases

| Use Case | Description |
|----------|-------------|
| **Professional Training & Education** | Comprehensive learning environment for Oracle Database administration, SQL development, and APEX application development with hands-on practical experience |
| **Proof of Concept (POC)** | Rapid prototyping and technical validation platform for evaluating Oracle AI Database 26ai features and enterprise solutions |
| **APEX Application Development** | Full-stack low-code development environment with Oracle APEX 24.2.0, ORDS 25.3, and integrated database services for building enterprise applications |
| **Technology Discovery** | Explore and evaluate the latest Oracle AI Database 26ai capabilities, new features, and enhancements in an isolated sandbox environment |
| **Community & Open Source** | Accessible development platform enabling collaborative projects, community contributions, and knowledge sharing |
| **Isolated Development Environment** | Containerized Oracle database instances providing consistent, reproducible development environments without impacting local system configuration |

<br>

# 📦 Prerequisites

### Software Prerequisites

1. **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** - Container platform (includes Docker Engine and Docker Compose)
2. **[Git](https://git-scm.com/)** - Version control system for repository cloning
3. **Modern web browser** - For accessing APEX and Enterprise Manager (Chrome, Firefox, Edge, or Safari)
4. **Text editor** - For configuration file editing (VS Code, Sublime Text, or similar)

### Network Requirements

1. **Internet connection** - Required for initial setup and Docker image downloads
2. **Available subnet** - 192.168.1.0/24 for container networking
3. **Firewall configuration** - Allow Docker container communication
4. **Port availability** - Ensure ports 1521, 5500, 3000, and 8080 are not in use

> **Note:** Oracle APEX 24.2.0 is pre-installed in the container - no separate installation required.

<br>

### System Requirements

| Component | Minimum Specification |
|-----------|----------------------|
| **Docker Engine** | 24.0.0 or later |
| **Docker Compose** | v2.20.0 or later |
| **RAM** | 8 GB |
| **Storage** | 20 GB available disk space |
| **CPU** | 2 cores (x86_64 or ARM64) |
| **Operating System** | Linux, macOS, or Windows with WSL2 |

### Required Ports

Ensure the following ports are available:

| Port | Service | Protocol |
|------|---------|----------|
| 1521 | Oracle Database Listener | TCP |
| 5500 | Enterprise Manager Express | HTTP |
| 3000 | Management API | HTTP |
| 8080 | Oracle ORDS/APEX | HTTP |

<br>

# Architecture
The environment consists of two primary containerized services:

<br>

#### Docker Architecture Diagram

```
┌───────────────────────────────────────────────────────┐
│                   Docker Environment                  │
│                                                       │
│  ┌──────────────────┐         ┌──────────────────┐    │
│  │  Management      │         │  Oracle AI       │    │
│  │  Server          │◄────────┤  Database 26ai   │    │
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

<br>

#### Database Service (`demasylabs-oracle-database`)

| Component | Details |
|-----------|---------|
| Base Image | Oracle AI Database 26ai Free Edition |
| Container Name | `oracle-al-database-26ai` |
| Database Name | DEMASY |
| Exposed Ports | • 1521 (Database Listener)<br>• 5500 (Enterprise Manager Express) |
| Network | 192.168.1.10 |
| Resources | • CPU: 1 core<br>• Memory: 3GB |
| Health Check | Every 30s via SQL connectivity test |

<br>

#### Management Server (`demasylabs-oracle-server`)

| Component | Details |
|-----------|---------|
| Base Image | Node.js 20.19.4 |
| Container Name | `demasy-server` |
| Exposed Port | 3000 (API & Health Check) |
| Network | 192.168.1.20 |
| Resources | • CPU: 1 core<br>• Memory: 512MB |
| Integrations | • Oracle SQLcl<br>• Oracle APEX<br>• Oracle Instant Client 23.7 |
| Connection Pool | • Min: 1<br>• Max: 5<br>• Increment: 1 |


<br>

#### 📋 Version Information

| Component | Version | Release Date | Status |
|-----------|---------|--------------|--------|
| Oracle AI Database | 26ai Free | 2025 | ✅ Production-Ready |
| Oracle APEX | 24.2.0 | October 2024 | ✅ Current Release |
| Oracle ORDS | 25.3.1 | November 2024 | ✅ Current Release |
| Oracle SQLcl | 25.3 | November 2024 | ✅ Current Release |
| Oracle Instant Client | 23.7 | 2024 | ✅ Stable |
| Node.js | 20.19.4 LTS | 2024 | ✅ Long-Term Support |
| Docker Engine | 24.0.0+ | - | ✅ Required |
| Docker Compose | v2.20.0+ | - | ✅ Required |

<br>

#### 🖥️ Platform Compatibility

| Platform | Architecture | SQL*Plus | SQLcl | APEX | Status |
|----------|-------------|----------|-------|------|--------|
| **Linux (Ubuntu/Debian)** | AMD64 (x86_64) | ✅ | ✅ | ✅ | Fully Supported |
| **Linux (Ubuntu/Debian)** | ARM64 (aarch64) | ⚠️ Fallback | ✅ | ✅ | Supported |
| **macOS (Intel)** | AMD64 (x86_64) | ✅ | ✅ | ✅ | Fully Supported |
| **macOS (Apple Silicon)** | ARM64 (M1/M2/M3) | ⚠️ Fallback | ✅ | ✅ | Supported |
| **Windows (WSL2)** | AMD64 (x86_64) | ✅ | ✅ | ✅ | Supported |

> ⚠️ **Note:** SQL*Plus is not natively available on ARM64. SQLcl is automatically used as a fallback.

<br>

## Scripts

All scripts are organized in a structured directory layout for better maintainability:

**Container Path Structure:**
```
/usr/demasy/scripts/
├── cli/                    # User-facing CLI tools
│   ├── sqlcl-connect.sh   # SQLcl database connection
│   └── sqlplus-connect.sh # SQL*Plus connection
│
├── oracle/
│   ├── admin/             # Administrative tools
│   │   └── healthcheck.sh # System health monitoring
│   │
│   ├── apex/              # APEX management
│   │   ├── install.sh    # APEX + ORDS installation
│   │   ├── uninstall.sh  # APEX removal
│   │   ├── start.sh      # Start ORDS
│   │   └── stop.sh       # Stop ORDS

```

<br>

**Available Command Aliases:**

| Alias | Target Script | Purpose |
|-------|--------------|----------|
| `sqlcl` | `/usr/demasy/scripts/cli/sqlcl-connect.sh` | Connect via SQLcl |
| `sqlplus` | `/usr/demasy/scripts/cli/sqlplus-connect.sh` | Connect via SQL*Plus |
| `oracle` | `/usr/demasy/scripts/cli/sqlcl-connect.sh` | Alias for SQLcl |
| `healthcheck` | `/usr/demasy/scripts/oracle/admin/healthcheck.sh` | Run health check |
| `install-apex` | `/usr/demasy/scripts/oracle/apex/install.sh` | Install APEX |
| `uninstall-apex` | `/usr/demasy/scripts/oracle/apex/uninstall.sh` | Remove APEX |
| `start-apex` | `/usr/demasy/scripts/oracle/apex/start.sh` | Start ORDS |
| `stop-apex` | `/usr/demasy/scripts/oracle/apex/stop.sh` | Stop ORDS |

> 📝 **Note:** All scripts are organized using best practices with flat structure (max 3 levels), DRY principle with shared utilities, and clear naming conventions. For detailed documentation, see `src/scripts/README.md`.

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
# Absolutely Required - Container Won't Start Without These
ENV_DB_PASSWORD=YourSecurePassword123!
ENV_DB_SID=FREE
ENV_DB_SERVICE=FREEPDB1
ENV_DB_CHARACTERSET=AL32UTF8
ENV_NETWORK_SUBNET=192.168.1.0/24
ENV_NETWORK_GATEWAY=192.168.1.1
ENV_IP_DB_SERVER=192.168.1.110
ENV_IP_APP_SERVER=192.168.1.120
ENV_DB_PORT_LISTENER=1521
ENV_SERVER_PORT=3000
ENV_DB_POOL_MIN=1
ENV_DB_POOL_MAX=5
ENV_DB_POOL_INCREMENT=1
ENV_DB_USER=system
ENV_DB_CLIENT=/opt/oracle/instantclient
ENV_DB_CPU_LIMIT=2
ENV_DB_MEMORY_LIMIT=4g
ENV_SERVER_CPU_LIMIT=3.0
ENV_SERVER_MEMORY_LIMIT=3g
ENV_SRC_ORACLE_SQLCL=https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip
ENV_SRC_ORACLE_SQLPLUS=https://download.oracle.com/otn_software/linux/instantclient/2390000/instantclient-sqlplus-linux.arm64-23.9.0.25.07.zip
ENV_SRC_ORACLE_APEX=https://download.oracle.com/otn_software/apex/apex-latest.zip
ENV_SRC_ORACLE_ORDS=https://download.oracle.com/otn_software/java/ords/ords-latest.zip

# Required Only If Using APEX
ENV_APEX_ADMIN_PASSWORD=YourAPEXPassword123
ENV_APEX_ADMIN_USERNAME=ADMIN
ENV_APEX_EMAIL=your-email@example.com
ENV_APEX_DEFAULT_WORKSPACE=INTERNAL
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
docker ps --filter "name=oracle-al-database-26ai" --filter "name=demasy-server"
```

**Expected output:**
```
CONTAINER ID   IMAGE                    STATUS                    PORTS
abc123def456   oracle-database:26ai     Up 2 minutes (healthy)    0.0.0.0:1521->1521/tcp
def456ghi789   demasy-server:latest     Up 2 minutes (healthy)    0.0.0.0:3000->3000/tcp
```

#### 2. Wait for Database Initialization

Monitor database startup (takes 5-10 minutes on first run):

```bash
docker logs -f oracle-al-database-26ai
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
Connected to: Oracle AI Database 26ai Free
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
docker logs -f oracle-al-database-26ai  # Wait for "READY TO USE"
curl http://localhost:3000/health

# 4. Connect
docker exec -it demasy-server sqlcl
```


## Service Management

### Container Operations

#### Database Service

##### Stop Database
```bash
docker stop oracle-al-database-26ai
```

##### Start Database
```bash
docker start oracle-al-database-26ai
```

##### Restart Database
```bash
docker restart oracle-al-database-26ai
```

##### Remove Database Container
```bash
docker rm -f oracle-al-database-26ai
```

##### Access Database Shell
```bash
docker exec -it oracle-al-database-26ai bash
```

##### View Database Logs
```bash
# View all logs
docker logs oracle-al-database-26ai

# Follow logs in real-time
docker logs -f oracle-al-database-26ai

# View last 100 lines
docker logs --tail 100 oracle-al-database-26ai

# View logs with timestamps
docker logs -t oracle-al-database-26ai
```

##### Monitor Database
```bash
# View container details
docker inspect oracle-al-database-26ai

# View resource usage
docker stats oracle-al-database-26ai

# Check container health
docker inspect --format='{{.State.Health.Status}}' oracle-al-database-26ai
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
docker commit oracle-al-database-26ai oracle-db-backup:$(date +%Y%m%d)
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

## Oracle APEX Installation

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

### Access Endpoints

After successful installation:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Application Builder** | http://localhost:8080/ords/f?p=4550:1 | Workspace: `INTERNAL`<br>Username: `ADMIN`<br>Password: See `.env` (`ENV_APEX_ADMIN_PASSWORD`) |
| **SQL Developer Web** | http://localhost:8080/ords/sql-developer | Username: `ADMIN`<br>Password: See `.env` (`ENV_APEX_ADMIN_PASSWORD`) |
| **APEX Administration** | http://localhost:8080/ords/apex_admin | Username: `ADMIN`<br>Password: See `.env` (`ENV_APEX_ADMIN_PASSWORD`) |

> **Security Note:** All passwords are configured in the `.env` file. Ensure you change all default passwords before deployment. Never commit `.env` to version control.

### APEX Management Commands

```bash
# Check ORDS status
docker exec demasy-server netstat -tulnp | grep :8080

# View ORDS logs in real-time
docker exec demasy-server tail -f /tmp/ords.log

# Restart ORDS service
docker exec demasy-server stop-apex
docker exec demasy-server start-apex
```

### Available Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `install-apex` | One-time APEX + ORDS installation | `docker exec demasy-server install-apex` |
| `start-apex` | Start ORDS listener | `docker exec demasy-server start-apex` |
| `stop-apex` | Stop ORDS listener | `docker exec demasy-server stop-apex` |
| `uninstall-apex` | Remove APEX installation | `docker exec demasy-server uninstall-apex` |

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
docker exec demasy-server stop-apex && docker exec demasy-server start-apex
```

#### Login Issues

- Verify you're using workspace: `INTERNAL` (case-sensitive)
- Ensure username is `ADMIN` (all uppercase)
- Check ORDS is running on port 8080

For comprehensive APEX documentation, see [APEX-GUIDE.md](APEX-GUIDE.md)

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

### Connection Parameters

| Parameter | Environment Variable | Default Value | Description |
|-----------|---------------------|---------------|-------------|
| **Hostname** | `DEMASYLABS_DB_HOST` | `oracle-al-database-26ai` | Database container name |
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
docker inspect --format='{{.State.Health.Status}}' oracle-al-database-26ai
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
docker logs oracle-al-database-26ai

# Follow logs in real-time
docker logs -f oracle-al-database-26ai

# View last 100 lines
docker logs --tail 100 oracle-al-database-26ai

# View with timestamps
docker logs -t oracle-al-database-26ai

# Filter by time
docker logs --since 1h oracle-al-database-26ai
docker logs --since 2025-11-25T10:00:00 oracle-al-database-26ai
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
docker stats oracle-al-database-26ai

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
docker inspect oracle-al-database-26ai

# Get specific information
docker inspect --format='{{.State.Status}}' oracle-al-database-26ai
docker inspect --format='{{.NetworkSettings.IPAddress}}' oracle-al-database-26ai
```

### Performance Monitoring

#### Database Performance

```bash
# Connect to database
docker exec -it oracle-al-database-26ai sqlplus / as sysdba

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
DEMASYLABS_DB_HOST=oracle-al-database-26ai
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
docker logs -f oracle-al-database-26ai
```

#### APEX Installation Fails

**Symptom:** `install-apex` command returns errors

**Solution:**
```bash
# Check database is running
docker exec -it oracle-al-database-26ai sqlplus / as sysdba

# Review installation logs
docker exec demasy-server cat /tmp/apex_install.log

# Verify connectivity
docker exec demasy-server ping oracle-al-database-26ai
```

#### Connection Refused

**Symptom:** Cannot connect to database

**Solution:**
```bash
# Verify database is healthy
docker ps --filter "name=oracle-al-database-26ai"

# Check listener status
docker exec oracle-al-database-26ai lsnrctl status

# Verify network connectivity
docker exec demasy-server ping oracle-al-database-26ai

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

docker exec demasy-server stop-apex
docker exec demasy-server start-apex
```

<br>

## 📜 Change Log

| Version | Date | Type | Description |
|---------|------|------|-------------|
|v1.0.0|01-DEC-2025| Release |Foundation Release (December 2025)|


<br>

## Contributors


| Author | GitHub & LinkedIn account |
| :-  | :---- |
| <div align="center"> <img src="https://github.com/demasy.png" width="100px;" alt="Ahmed El-Demasy"/> <br> **Ahmed El-Demasy** (Creator & Maintainer) <br> Oracle Solutions Architect <br> Oracle ACE </div> | <div align="center"> <a href="https://github.com/demasy">Github</a> & <a href="https://www.linkedin.com/in/demasy">LinkedIn</a> </div> |

<br>

### Contributing to the Oracle AI Database 26ai Free - Docker Development Environment. 
We welcome you to join and contribute to the Oracle AI Database 26ai Free - Docker Development Environment. If you are interested in helping, please don’t hesitate to contact us at founder@demasy.io

<br>

###### Suggestions & Issues
> If you find any issue or have a great idea in mind, please create an issue on <a href="https://github.com/demasy/oracle-database/issues">GitHub</a>.

<br>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

</br>

</br>

<!--
![Made with love in Egypt](https://madewithlove.now.sh/in?heart=true&template=for-the-badge)
-->
<p align="center">
Code with love ❤️ in Egypt for the Oracle development community.
</p>
