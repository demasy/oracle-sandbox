# 🛠 Oracle Database Development Environment

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Oracle](https://img.shields.io/badge/Oracle-F80000?style=flat&logo=oracle&logoColor=white)
[![Database](https://img.shields.io/badge/Oracle%20DB-23c-blue.svg)](https://www.oracle.com/database/free/)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/demasy/oracle-database/pulls)

<div align="center">
  <h3>🚀 Explore, Learn, and Build with Oracle Database 23c</h3>
  <p><i>A modern containerized environment for database development and learning</i></p>
</div>

<br>

This development environment combines Oracle Database 23c Free Edition with modern tooling for an optimal learning and development experience:

**Core Components:**
- 📦 **Oracle Database 23c** - Latest features and capabilities
- 🔧 **Node.js Management Server** - Modern API and monitoring
- 🐳 **Docker Containers** - Consistent and portable setup
- ⚡ **SQLcl Integration** - Advanced database interaction tools

**Perfect For:**
- � **Development** - Rapid prototyping and application development
- 🔬 **Testing** - Isolated environment for feature testing
- � **Learning** - Hands-on database administration practice
- 🏫 **Training** - Structured workshops and courses
- 🧪 **Research** - Database feature exploration and testing

Designed and maintained by [Demasy](https://github.com/demasy) to provide a consistent, reproducible database workspace across any development machine.

<br>

## 📋 Prerequisites

### Required
- Docker Engine 24.0.0+
- Docker Compose v2.20.0+
- 4GB RAM, 10GB storage
- Ports: 1521 (DB), 5500 (EM), 3000 (API)

### Recommended
- SQLcl for database operations
- Container orchestration experience
- Basic Oracle Database knowledge

<br>

## 🚀 Quick Start Guide

### 📥 Installation

##### Clone Repository
```bash
git clone https://github.com/demasy/oracle-database.git
cd oracle-database
```

### ⚙️ Configuration

##### Set Up Environment
```bash
# Create configuration file from template
cp .env.example .env
chmod 600 .env        # Set secure file permissions
```

##### Configure Database
```bash
# Required Settings
ORACLE_PWD=your_secure_password      # Database admin (SYS/SYSTEM) password
DATABASE_NAME=DEMASY                 # Your database name (max 8 chars)

# Regional Settings
TZ=Asia/Riyadh                      # Container timezone
```

##### Optional Settings
```bash
# Connection Pool (defaults shown)
DEMASYLABS_DB_POOL_MIN=1            # Minimum connections
DEMASYLABS_DB_POOL_MAX=5            # Maximum connections
DEMASYLABS_DB_POOL_INCREMENT=1      # Growth increment

# Network Settings (defaults shown)
DEMASYLABS_DB_PORT=1521             # Database listener port
DEMASYLABS_DB_SERVICE=FREE          # Service name
```

> 🔒 **Security Notes:**
> - Use a strong password (min. 8 chars, mixed case, numbers, symbols)
> - Never commit `.env` to version control
> - Keep file permissions restricted to owner only
> - Change default passwords after first login

### 🏗 Build Process

##### Build Docker Services
```bash
# Clean build without cache
docker-compose build --no-cache
```

### 🌟 Launch

##### Start Services

###### Option 1: Launch All Services
```bash
# Start in interactive mode (with logs)
docker compose up

# Or in detached mode (background)
docker compose up -d
```

###### Option 2: Start Database Only
```bash
# Start database in background
docker compose up -d demasylabs-oracle-database

# View initialization progress
docker logs -f oracle-database-23ai
```

###### Option 3: Start Management Server Only
```bash
# Start server in background
docker compose up -d demasylabs-oracle-server

# View server logs
docker logs -f demasy-server
```

###### Option 4: Development Mode
```bash
# Start database in background, server in foreground
docker compose up -d demasylabs-oracle-database
docker compose up demasylabs-oracle-server
```

### ✅ Verification

##### Check Database Status
```bash
# Wait for database initialization (approx. 5-10 minutes)
docker logs -f oracle-database-23ai
```

##### Verify Server Health
```bash
# HTTP endpoint health check
curl http://localhost:3000/health

# Expected response:
# {"status":"healthy","timestamp":"YYYY-MM-DD HH:mm:ss"}
```

##### Test Database Connection
```bash
# Connect to management server
docker exec -it demasy-server bash

# Run SQLcl connection test
sqlcl
```

<br>

## 🎯 Features

- Oracle Free Database 23c
- Node.js-based management server
- Oracle SQLcl integration
- Automated health monitoring
- Connection pooling
- Custom networking
- Resource management
- Persistent logging

<br>

### 🔐 Environment Setup

```bash
# Copy template and edit
cp .env.example .env

# Required Settings
ORACLE_PWD=your_secure_password     # Database system password
TZ=Asia/Riyadh                      # Timezone
DATABASE_NAME=DEMASY                # Database name

# Connection Settings (preconfigured)
DEMASYLABS_DB_HOST=oracle-database-23ai
DEMASYLABS_DB_PORT=1521
DEMASYLABS_DB_SERVICE=FREE
DEMASYLABS_DB_POOL_MAX=5
```

> 🔒 **Security**: Never commit `.env` file to version control

## 🏗 Architecture

The environment consists of two main containerized services:

### Database Service
`demasylabs-oracle-database`

| Component | Details |
|-----------|---------|
| Base Image | Oracle Free Database 23c |
| Container Name | `oracle-database-23ai` |
| Database Name | DEMASY |
| Exposed Ports | • 1521 (Database Listener)<br>• 5500 (Enterprise Manager Express) |
| Network | 192.168.1.10 |
| Resources | • CPU: 1 core<br>• Memory: 3GB |
| Health Check | Every 30s via SQL connectivity test |

### Management Server
`demasylabs-oracle-server`

| Component | Details |
|-----------|---------|
| Base Image | Node.js 20.19.4 |
| Container Name | `demasy-server` |
| Exposed Port | 3000 (API & Health Check) |
| Network | 192.168.1.20 |
| Resources | • CPU: 1 core<br>• Memory: 512MB |
| Integrations | • Oracle SQLcl<br>• Oracle APEX<br>• Oracle Instant Client 23.7 |
| Connection Pool | • Min: 1<br>• Max: 5<br>• Increment: 1 |

## ⚙️ Service Management

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

## 🎨 Oracle APEX

This environment includes **Oracle APEX 24.2.0** (Application Express) - Oracle's low-code development platform.

### Quick APEX Setup

#### Option 1: From Container (Recommended)
```bash
# Install APEX (one-time, takes 5-7 minutes)
docker exec demasy-server apex-install

# Start APEX/ORDS
docker exec demasy-server apex-start

# Stop APEX/ORDS
docker exec demasy-server apex-stop

# Uninstall APEX
docker exec demasy-server apex-uninstall
```

#### Option 2: From Host
```bash
# Navigate to APEX scripts directory
cd src/scripts/oracle/database/dev/apex

# Install APEX (one-time, takes 5-7 minutes)
./apex-install.sh

# Start APEX/ORDS
./apex-start.sh

# Stop APEX/ORDS
./apex-stop.sh

# Uninstall APEX
./apex-uninstall.sh
```

### Access APEX

After installation, access these URLs:

**APEX App Builder:**
- URL: http://localhost:8080/ords/apex
- Workspace: DEMASY_LABS
- Username: DEMASY_ADMIN
- Password: DemasyApex1986!

**SQL Developer Web:**
- URL: http://localhost:8080/ords/demasy_dev/_sdw/
- Username: DEMASY_DEV
- Password: DemasyApex1986!

### APEX Management

```bash
# View ORDS logs
docker exec demasy-server tail -f /tmp/ords.log

# Check ORDS status
docker exec demasy-server pgrep -f ords.war

# Restart ORDS (from container)
docker exec demasy-server apex-stop
docker exec demasy-server apex-start

# Or from host
cd src/scripts/oracle/database/dev/apex
./apex-stop.sh && ./apex-start.sh
```

### Available APEX Commands in Container

Once the container is built, these commands are available:
```bash
docker exec demasy-server apex-install    # Install APEX
docker exec demasy-server apex-start      # Start ORDS
docker exec demasy-server apex-stop       # Stop ORDS
docker exec demasy-server apex-uninstall  # Uninstall APEX
```

📖 **Full Guide:** See [APEX-GUIDE.md](APEX-GUIDE.md) for complete documentation

<br>

## 🔌 Database Connectivity

### Connection Methods

#### 1. SQL*Plus (Traditional)
```sql
sqlplus / as sysdba
```

#### 2. Oracle SQLcl (Modern CLI)
Multiple connection options available:

##### a. Using Preconfigured Aliases (Recommended)
```bash
# From management server container
sqlcl     # Primary connection command
oracle    # Alternative alias
```

##### b. Using Direct SQL Command
```bash
sql       # Uses symlink in /usr/local/bin
```

##### c. Using Custom Connection String
```bash
sql ${username}/${password}@localhost:1521/FREE as sysdba
```

### Connection Parameters

| Parameter | Environment Variable | Default Value |
|-----------|---------------------|---------------|
| Host | DEMASYLABS_DB_HOST | oracle-database-23ai |
| Port | DEMASYLABS_DB_PORT | 1521 |
| Service | DEMASYLABS_DB_SERVICE | FREE |
| SID | DEMASYLABS_DB_SID | FREE |
| User | DEMASYLABS_DB_USER | system |
| Password | ORACLE_PWD | *from .env* |

### Connection Pool Settings

| Parameter | Value | Environment Variable |
|-----------|-------|---------------------|
| Minimum Size | 1 | DEMASYLABS_DB_POOL_MIN |
| Maximum Size | 5 | DEMASYLABS_DB_POOL_MAX |
| Increment | 1 | DEMASYLABS_DB_POOL_INCREMENT |
- Hostname: localhost (or 192.168.1.10)
- Port: 1521
- Service Name: FREE
- SID: FREE
- Default User: system
- Database Name: DEMASY

## Monitoring and Logs
- Database logs are managed with JSON file driver
  - Max size: 10MB per file
  - Max files: 3
- Application logs are stored in the `demasylabs_logs` volume
- Health checks run every 30 seconds for both services

### Health Check
You can check the server's health status in two ways:

1. Using HTTP endpoint:
```bash
curl http://localhost:3000/health
```
or open in your browser:
- http://localhost:3000/health

2. Using command line:
```bash
# Connect to the server container
docker exec -it demasy-server bash

# Run health check
healthcheck
```
Expected output if healthy:
```
Server is healthy.
```

Note: The health check runs automatically every 30 seconds as part of the container's health monitoring.

## Network Configuration
- Custom network: `demasylabs_network`
- Subnet: 192.168.1.0/24
- Database IP: 192.168.1.10
- Server IP: 192.168.1.20

<br>

## 👤 Author

**Ahmed El Demasy**
- GitHub: [@demasy](https://github.com/demasy)

<div align="center">

Built with ❤️ by [Demasy](https://github.com/demasy)

</div>

