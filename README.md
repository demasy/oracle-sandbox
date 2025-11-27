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

**Command Aliases:**

| Command Alias | Target Script | Purpose |
|-------|--------------|----------|
| `sqlcl` | `/usr/demasy/scripts/cli/sqlcl-connect.sh` | Connect via SQLcl |
| `sqlplus` | `/usr/demasy/scripts/cli/sqlplus-connect.sh` | Connect via SQL*Plus |
| `oracle` | `/usr/demasy/scripts/cli/sqlcl-connect.sh` | Alias for SQLcl |
| `healthcheck` | `/usr/demasy/scripts/oracle/admin/healthcheck.sh` | Run health check |
| `install-apex` | `/usr/demasy/scripts/oracle/apex/install.sh` | Install APEX |
| `uninstall-apex` | `/usr/demasy/scripts/oracle/apex/uninstall.sh` | Remove APEX |
| `start-apex` | `/usr/demasy/scripts/oracle/apex/start.sh` | Start ORDS |
| `stop-apex` | `/usr/demasy/scripts/oracle/apex/stop.sh` | Stop ORDS |

> 📝 **Note:** All scripts are organized using best practices with a flat structure (max three levels). For detailed documentation, see `src/scripts/README.md`.

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

**Expected output: 
```
SQLcl: Release 25.3 Production on Thu Nov 13 11:13:11 1986

Copyright (c) 1982, 2025, Oracle.  All rights reserved.

Last Successful login time: Thu Nov 13 1986 13:29:04 +03:00

Connected to:
Oracle AI Database 26ai Free Release 23.26.0.0.0 - Develop, Learn, and Run for Free
Version 23.26.0.0.0
SQL>
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
