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

### Software Prerequisites

- **[Git](https://git-scm.com/)** - Version control system for repository cloning
- **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** - Container platform (includes Docker Engine and Docker Compose)
- **[Oracle APEX](https://apex.oracle.com/)** - Low-code development platform (included in container)
- Text editor for configuration files
- Modern web browser for APEX and Enterprise Manager access

### Network Requirements

- Internet connection for initial setup (downloading images)
- Subnet 192.168.1.0/24 available for container networking
- No firewall blocking Docker container communication

<br>

# Architecture

The environment consists of two primary containerized services:

## Database Service (`demasylabs-oracle-database`)

| Component | Details |
|-----------|---------|
| Base Image | Oracle AI Database 26ai Free Edition |
| Container Name | `oracle-database-26ai` |
| Database Name | DEMASY |
| Exposed Ports | • 1521 (Database Listener)<br>• 5500 (Enterprise Manager Express) |
| Network | 192.168.1.10 |
| Resources | • CPU: 1 core<br>• Memory: 3GB |
| Health Check | Every 30s via SQL connectivity test |

<br>

## Management Server (`demasylabs-oracle-server`)

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
<br>

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

## 📋 Version Information

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

## 🖥️ Platform Compatibility

| Platform | Architecture | SQL*Plus | SQLcl | APEX | Status |
|----------|-------------|----------|-------|------|--------|
| **Linux (Ubuntu/Debian)** | AMD64 (x86_64) | ✅ | ✅ | ✅ | Fully Supported |
| **Linux (Ubuntu/Debian)** | ARM64 (aarch64) | ⚠️ Fallback | ✅ | ✅ | Supported |
| **macOS (Intel)** | AMD64 (x86_64) | ✅ | ✅ | ✅ | Fully Supported |
| **macOS (Apple Silicon)** | ARM64 (M1/M2/M3) | ⚠️ Fallback | ✅ | ✅ | Supported |
| **Windows (WSL2)** | AMD64 (x86_64) | ✅ | ✅ | ✅ | Supported |

> ⚠️ **Note:** SQL*Plus is not natively available on ARM64. SQLcl is automatically used as a fallback.

<br>

## Scripts Organization

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
DEMASYLABS_DB_HOST=oracle-database-26ai
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
docker ps --filter "name=oracle-database-26ai" --filter "name=demasy-server"
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
docker logs -f oracle-database-26ai
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
docker logs -f oracle-database-26ai  # Wait for "READY TO USE"
curl http://localhost:3000/health

# 4. Connect
docker exec -it demasy-server sqlcl
```


## Service Management

### Container Operations

#### Database Service

##### Stop Database
```bash
docker stop oracle-database-26ai
```

##### Start Database
```bash
docker start oracle-database-26ai
```

##### Restart Database
```bash
docker restart oracle-database-26ai
```

##### Remove Database Container
```bash
docker rm -f oracle-database-26ai
```

##### Access Database Shell
```bash
docker exec -it oracle-database-26ai bash
```

##### View Database Logs
```bash
# View all logs
docker logs oracle-database-26ai

# Follow logs in real-time
docker logs -f oracle-database-26ai

# View last 100 lines
docker logs --tail 100 oracle-database-26ai

# View logs with timestamps
docker logs -t oracle-database-26ai
```

##### Monitor Database
```bash
# View container details
docker inspect oracle-database-26ai

# View resource usage
docker stats oracle-database-26ai

# Check container health
docker inspect --format='{{.State.Health.Status}}' oracle-database-26ai
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
docker commit oracle-database-26ai oracle-db-backup:$(date +%Y%m%d)
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
docker exec -it demasy-server bash -c "sql system/${ORACLE_PWD}@oracle-database-26ai:1521/FREE"

# Example - Connect as SYSDBA
docker exec -it demasy-server bash -c "sql sys/${ORACLE_PWD}@oracle-database-26ai:1521/FREE as sysdba"
```

#### Method 4: SQL*Plus (Traditional)

For compatibility with legacy scripts:

```bash
docker exec -it demasy-server sqlplus

# Or with connection string
docker exec -it oracle-database-26ai sqlplus / as sysdba
```

### Connection Parameters

| Parameter | Environment Variable | Default Value | Description |
|-----------|---------------------|---------------|-------------|
| **Hostname** | `DEMASYLABS_DB_HOST` | `oracle-database-26ai` | Database container name |
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
oracle-database-26ai:1521/FREE
```

#### TNS Format
```
(DESCRIPTION=
  (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-database-26ai)(PORT=1521))
  (CONNECT_DATA=(SERVICE_NAME=FREE))
)
```

#### JDBC Format
```
jdbc:oracle:thin:@oracle-database-26ai:1521:FREE
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
docker exec -it demasy-server bash -c "sql sys/${ORACLE_PWD}@oracle-database-26ai:1521/FREE as sysdba"

# Connect to pluggable database
docker exec -it demasy-server bash -c "sql system/${ORACLE_PWD}@oracle-database-26ai:1521/FREEPDB1"

# Connect with specific schema
docker exec -it demasy-server bash -c "sql your_user/your_password@oracle-database-26ai:1521/FREE"
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
docker inspect --format='{{.State.Health.Status}}' oracle-database-26ai
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
docker logs oracle-database-26ai

# Follow logs in real-time
docker logs -f oracle-database-26ai

# View last 100 lines
docker logs --tail 100 oracle-database-26ai

# View with timestamps
docker logs -t oracle-database-26ai

# Filter by time
docker logs --since 1h oracle-database-26ai
docker logs --since 2025-11-25T10:00:00 oracle-database-26ai
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
docker stats oracle-database-26ai

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
docker inspect oracle-database-26ai

# Get specific information
docker inspect --format='{{.State.Status}}' oracle-database-26ai
docker inspect --format='{{.NetworkSettings.IPAddress}}' oracle-database-26ai
```

### Performance Monitoring

#### Database Performance

```bash
# Connect to database
docker exec -it oracle-database-26ai sqlplus / as sysdba

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
DEMASYLABS_DB_HOST=oracle-database-26ai
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
docker logs -f oracle-database-26ai
```

#### APEX Installation Fails

**Symptom:** `install-apex` command returns errors

**Solution:**
```bash
# Check database is running
docker exec -it oracle-database-26ai sqlplus / as sysdba

# Review installation logs
docker exec demasy-server cat /tmp/apex_install.log

# Verify connectivity
docker exec demasy-server ping oracle-database-26ai
```

#### Connection Refused

**Symptom:** Cannot connect to database

**Solution:**
```bash
# Verify database is healthy
docker ps --filter "name=oracle-database-26ai"

# Check listener status
docker exec oracle-database-26ai lsnrctl status

# Verify network connectivity
docker exec demasy-server ping oracle-database-26ai

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

## 🔒 Security Considerations

### Development Environment Only
> ⚠️ **WARNING:** This project is designed for **development, testing, and training purposes only**. It is **NOT hardened for production use**.

### Security Best Practices

#### ✅ Password Security
- Use strong passwords (minimum 12 characters)
- Mix uppercase, lowercase, numbers, and symbols
- Never commit `.env` files to version control
- Rotate passwords regularly
- Use different passwords for each environment

#### ✅ File Permissions
```bash
# Secure your .env file
chmod 600 .env

# Verify permissions
ls -la .env
# Should show: -rw------- (owner read/write only)
```

#### ✅ Network Security
- Run containers on isolated networks
- Use Docker's internal networking for container communication
- Expose only necessary ports to host
- Consider using firewall rules for additional protection

#### ✅ Container Security
- Regularly update base images
- Scan images for vulnerabilities (automated with Trivy)
- Review SBOM (Software Bill of Materials)
- Remove unused containers and images

#### ✅ Database Security
- Change default passwords immediately
- Use least privilege principle for user accounts
- Enable audit logging for production
- Regular backup of important data

### Security Scanning

This project includes automated security scanning:

```bash
# Run Trivy security scan locally
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image demasy/oracle-database:latest

# Generate SBOM
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  anchore/syft demasy/oracle-database:latest
```

### Vulnerability Reporting

If you discover a security vulnerability, please:
1. **DO NOT** open a public issue
2. Email: founder@demasy.io with details
3. Include steps to reproduce
4. Allow time for fix before public disclosure

---

## 🎯 Best Practices

### Docker Best Practices

#### ✅ Resource Management
```yaml
# Set appropriate resource limits
resources:
  limits:
    cpus: '2'
    memory: 4GB
  reservations:
    cpus: '1'
    memory: 2GB
```

#### ✅ Volume Management
```bash
# Regular volume cleanup
docker volume prune

# Backup important volumes
docker run --rm -v demasylabs_oracle_vol:/data \
  -v $(pwd):/backup alpine tar czf /backup/oracle-backup.tar.gz /data
```

#### ✅ Image Management
```bash
# Remove unused images
docker image prune -a

# Check disk usage
docker system df

# Complete cleanup (careful!)
docker system prune -a --volumes
```

### Development Workflow

#### ✅ Branch Strategy
```bash
# Feature development
git checkout -b feature/your-feature
git commit -m "feat: add new feature"
git push origin feature/your-feature

# Bug fixes
git checkout -b fix/bug-description
git commit -m "fix: resolve issue"
git push origin fix/bug-description
```

#### ✅ Commit Message Convention
```bash
# Format: <type>(<scope>): <subject>

feat: add new APEX sample application
fix: resolve connection timeout issue
docs: update installation guide
style: format CLI scripts with consistent branding
refactor: reorganize scripts directory structure
test: add health check validation
chore: update dependencies
```

### Performance Optimization

#### ✅ Docker Build Optimization
```dockerfile
# Use multi-stage builds
# Order layers from least to most frequently changing
# Leverage build cache
# Minimize layer count
# Clean up in same layer
```

#### ✅ Database Performance
```sql
-- Monitor active sessions
SELECT username, status, COUNT(*) 
FROM v$session 
WHERE username IS NOT NULL 
GROUP BY username, status;

-- Check table spaces
SELECT tablespace_name, 
       ROUND(used_space * 8192 / 1024 / 1024, 2) AS used_mb,
       ROUND(tablespace_size * 8192 / 1024 / 1024, 2) AS total_mb
FROM dba_tablespace_usage_metrics;
```

---

## 🗺️ Roadmap

### Current Release: v1.0 Foundation (95% Complete)

| Feature | Status | Version |
|---------|--------|--------|
| Docker Infrastructure | ✅ Complete | v1.0 |
| Oracle AI Database 26ai | ✅ Complete | v1.0 |
| APEX 24.2 + ORDS 25.3 | ✅ Complete | v1.0 |
| SQLcl & SQL*Plus | ✅ Complete | v1.0 |
| Health Monitoring | ✅ Complete | v1.0 |
| CI/CD Workflows | ✅ Complete | v1.0 |
| Comprehensive Docs | ✅ Complete | v1.0 |

### Upcoming Features

| Feature | Status | Target Version |
|---------|--------|---------------|
| APEX Sample Applications | 📋 Planned | v1.1 |
| APEX Workspace Templates | 📋 Planned | v1.1 |
| MCP Integration | 📋 Planned | v1.2 |
| VS Code Dev Container | 📋 Planned | v1.2 |
| Database Backup Scripts | 📋 Planned | v1.2 |
| Sample Schemas (HR, OE) | 📋 Planned | v1.2 |
| Full ARM64 Optimization | 📋 Planned | v1.3 |
| Kubernetes Support | 📋 Planned | v2.0 |
| Terraform Modules | 📋 Planned | v2.0 |

---

## 📊 Performance Benchmarks

| Metric | Value | Notes |
|--------|-------|-------|
| **Docker Image Size** | ~2.5 GB | Multi-stage optimized |
| **Build Time (first)** | 10-15 min | Includes downloads |
| **Build Time (cached)** | 2-3 min | With layer caching |
| **Startup Time (DB)** | 5-10 min | First initialization |
| **Startup Time (subsequent)** | 30-60 sec | From existing data |
| **APEX Install Time** | 5-7 min | One-time setup |
| **Memory Usage (DB)** | ~2-3 GB | Runtime |
| **Memory Usage (Server)** | ~256 MB | Runtime |

---

## 🎓 Learning Resources

### Official Documentation
- [Oracle AI Database 26ai Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/)
- [Oracle APEX Documentation](https://docs.oracle.com/en/database/oracle/apex/)
- [Oracle ORDS Documentation](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/)
- [Oracle SQLcl Documentation](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/)

### Tutorials & Guides
- [APEX Interactive Reports](https://apex.oracle.com/en/learn/tutorials/)
- [REST API Development with ORDS](https://www.oracle.com/database/technologies/appdev/rest.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Community
- [Oracle APEX Community](https://apex.oracle.com/community)
- [Oracle Developer Community](https://community.oracle.com/)
- [Stack Overflow - Oracle](https://stackoverflow.com/questions/tagged/oracle)

---

## 📈 Project Statistics

![GitHub repo size](https://img.shields.io/github/repo-size/demasy/oracle-database)
![GitHub code size](https://img.shields.io/github/languages/code-size/demasy/oracle-database)
![Lines of code](https://img.shields.io/tokei/lines/github/demasy/oracle-database)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/demasy/oracle-database)
![GitHub last commit](https://img.shields.io/github/last-commit/demasy/oracle-database)

---

## 🏆 Acknowledgments

### Technology Partners
- **Oracle Corporation** - For Oracle AI Database 26ai, APEX, ORDS, and SQLcl
- **Docker Inc.** - For containerization platform
- **Node.js Foundation** - For JavaScript runtime
- **GitHub** - For hosting and CI/CD infrastructure

### Inspiration & References
- Oracle's official Docker images
- Community feedback and contributions
- Best practices from DevOps community

---

## 📜 Change Log

### v1.0.0 - Foundation Release (December 2025) - 95% Complete

**Added:**
- ✅ Complete Docker infrastructure with multi-stage builds
- ✅ Oracle AI Database 26ai Free Edition integration
- ✅ APEX 24.2.0 automated installation
- ✅ ORDS 25.3.1 configuration
- ✅ SQLcl 25.3 & SQL*Plus clients
- ✅ Node.js 20.19.4 management server
- ✅ Health monitoring and diagnostics
- ✅ GitHub Actions CI/CD workflows
- ✅ Security scanning with Trivy
- ✅ Comprehensive documentation
- ✅ Multi-architecture support (AMD64/ARM64)
- ✅ Custom Docker networking
- ✅ Environment-based configuration
- ✅ CLI connection scripts with branding
- ✅ Organized scripts structure

**Changed:**
- Renamed connect.sh to sqlcl-connect.sh for clarity
- Updated APEX commands (start-apex/stop-apex)
- Reorganized scripts directory structure
- Enhanced README documentation

**Fixed:**
- Docker build issues on ARM64
- APEX installation script improvements
- Health check reliability

---

### Previous Versions

| Version | Date | Type | Description |
|---------|------|------|-------------|

---

## 🤝 Community & Contributing

We welcome you to join and contribute to the Oracle Database project! Whether you're a developer, DBA, educator, or enthusiast - there's a place for you in our community.

<div align="center">

| 💬 **Discussions** | 🐛 **Issues** | 🎯 **Pull Requests** | 📧 **Contact** |
|:---:|:---:|:---:|:---:|
| [Join Discussion](https://github.com/demasy/oracle-database/discussions) | [Report Bug](https://github.com/demasy/oracle-database/issues/new) | [Submit PR](https://github.com/demasy/oracle-database/pulls) | [Email Us](mailto:founder@demasy.io) |

</div>

### 🌟 Ways to Contribute

**Code Contributions:**
- 🔧 Fix bugs and issues
- ✨ Add new features
- 📝 Improve documentation
- 🧪 Write tests
- 🎨 Enhance scripts

**Non-Code Contributions:**
- 📖 Write tutorials
- 🎥 Create videos
- 💡 Suggest features
- ❓ Answer questions
- 📢 Share the project

### 🚀 Quick Start for Contributors

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/oracle-database.git
cd oracle-database

# 2. Create branch
git checkout -b feature/your-feature

# 3. Make changes and test
docker-compose build --no-cache
docker-compose up -d

# 4. Commit and push
git commit -m "feat: your feature description"
git push origin feature/your-feature

# 5. Create Pull Request on GitHub
```

### 📋 Contribution Guidelines

**Commit Convention:**
```bash
feat: add new feature
fix: resolve bug
docs: update documentation
style: format code
refactor: restructure code
test: add tests
chore: update dependencies
```

**Pull Request Checklist:**
- ✅ One feature/fix per PR
- ✅ Update documentation
- ✅ Test your changes
- ✅ Follow code style
- ✅ Respond to feedback

---

## 🏆 Contributors

### Core Team

<table>
<tr>
<td align="center">
<a href="https://github.com/demasy">
<img src="https://github.com/demasy.png" width="100px;" alt="Ahmed El-Demasy"/><br />
<sub><b>Ahmed El-Demasy</b></sub>
</a><br />
<sub>Creator & Maintainer</sub><br />
<a href="https://github.com/demasy">GitHub</a> •
<a href="https://www.linkedin.com/in/demasy">LinkedIn</a><br />
<sub>Oracle ACE | Solutions Architect</sub>
</td>
</tr>
</table>

### All Contributors

Thanks to everyone who contributes to this project! 🎉

> Want to see your name here? [Start contributing today](#-ways-to-contribute)!

---

### 💬 Get Help & Support

**Having Issues?**
1. 📖 Check [Documentation](#overview)
2. 🔍 Search [existing issues](https://github.com/demasy/oracle-database/issues)
3. 💬 Start a [discussion](https://github.com/demasy/oracle-database/discussions)
4. 🐛 [Report a bug](https://github.com/demasy/oracle-database/issues/new)

**Direct Contact:**
- 📧 Email: founder@demasy.io
- 💼 LinkedIn: [Ahmed El-Demasy](https://www.linkedin.com/in/demasy)
- 🌐 Website: [www.demasy.io](https://www.demasy.io)

---

### 🎯 Good First Issues

New to the project? Look for [`good first issue`](https://github.com/demasy/oracle-database/labels/good%20first%20issue) labels!

---

### 📜 Code of Conduct

We are committed to providing a welcoming environment for all contributors.

**Our Standards:**
- ✅ Use welcoming and inclusive language
- ✅ Respect differing viewpoints
- ✅ Accept constructive criticism gracefully
- ✅ Focus on what's best for the community
- ✅ Show empathy towards others

**Unacceptable:**
- ❌ Harassment or discrimination
- ❌ Trolling or insulting comments
- ❌ Personal or political attacks
- ❌ Publishing private information
- ❌ Unprofessional conduct

Report issues to: founder@demasy.io

---

## 💖 Support the Project

- ⭐ **Star the repo** on GitHub
- 🔀 **Fork it** and customize
- 📢 **Share it** with others
- 💬 **Give feedback**
- 🐛 **Report bugs**
- 💡 **Suggest features**
- 💻 **Contribute code**

<div align="center">

### ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=demasy/oracle-database&type=Date)](https://star-history.com/#demasy/oracle-database&Date)

</div>


## 🙏 Acknowledgments

- **Oracle Corporation** - Database technology
- **Docker Community** - Containerization platform
- **GitHub** - Hosting & CI/CD
- **All Contributors** - Community support
- **Users** - Valuable feedback
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
