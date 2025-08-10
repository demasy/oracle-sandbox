# Oracle Database Lab Environment

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
![Oracle](https://img.shields.io/badge/Oracle-F80000?style=flat&logo=oracle&logoColor=white)
[![Database](https://img.shields.io/badge/Database-23c-blue.svg)](https://www.oracle.com/database/free/)

> Welcome to Demasy Labs' Oracle Database Development Environment – your gateway to hands-on database exploration and learning.

A streamlined development environment featuring Oracle Database 23c Free Edition, engineered for educational purposes and practical experimentation. This containerized solution combines Oracle's latest free database offering with an intuitive Node.js management interface, providing a comprehensive platform for:

- 🎓 **Learning**: Ideal for database administration and development tutorials
- 🔬 **Experimentation**: Perfect sandbox for testing database features and concepts
- 💻 **Development**: Complete environment for application prototyping and testing
- 🛠 **Training**: Structured setup for database workshops and courses

Built and maintained by Demasy Labs, this environment ensures a consistent, reproducible database workspace across any development machine.

## 🎯 Features

- Oracle Free Database 23c
- Node.js-based management server
- Oracle SQLcl integration
- Automated health monitoring
- Connection pooling
- Custom networking
- Resource management
- Persistent logging

## 📋 Prerequisites

- Docker Engine 24.0.0+
- Docker Compose v2.20.0+
- 4GB+ available memory
- 10GB+ free disk space

### 🔐 Environment Configuration

The environment configuration is managed through a `.env` file in the project root directory. This file contains all necessary settings for both the database and management server.

#### Required Variables
```bash
# Oracle Database Credentials
ORACLE_PWD=your_secure_password     # System/SYS password (required)

# Time Zone Configuration
TZ=Asia/Riyadh                      # Container timezone

# Database Configuration
DATABASE_NAME=DEMASY                # Oracle database name
```

#### Optional Variables (Preconfigured)
```bash
# Database Connection Settings
DEMASYLABS_DB_HOST=oracle-database-23ai
DEMASYLABS_DB_PORT=1521
DEMASYLABS_DB_SERVICE=FREE
DEMASYLABS_DB_SID=FREE
DEMASYLABS_DB_USER=system

# Connection Pool Configuration
DEMASYLABS_DB_POOL_MIN=1           # Minimum connections
DEMASYLABS_DB_POOL_MAX=5           # Maximum connections
DEMASYLABS_DB_POOL_INCREMENT=1     # Connection increment

# Oracle Client Configuration
DEMASYLABS_DB_CLIENT=/opt/oracle/instantclient
```

#### Security Notes
- Store sensitive credentials securely
- Never commit `.env` file to version control
- Use strong passwords for database accounts
- Keep environment files restricted (600 permissions)

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

## 🚀 Quick Start Guide

### 📥 Installation

##### Clone Repository
```bash
git clone https://github.com/demasy/oracle-database.git
cd oracle-database
```

### ⚙️ Configuration

##### Set Up Environment File
```bash
# Copy example environment file
cp .env.example .env

# Edit .env file with your settings
# Required variables:
# ORACLE_PWD=your_secure_password
```

### 🏗 Build Process

##### Build Docker Services
```bash
# Clean build without cache
docker-compose build --no-cache
```

### 🌟 Launch

##### Start Services
```bash
# Option 1: Interactive Mode (view logs in terminal)
docker compose up

# Option 2: Detached Mode (run in background)
docker compose up -d
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

