# Oracle Database Docker Environment

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
![Oracle](https://img.shields.io/badge/Oracle-F80000?style=flat&logo=oracle&logoColor=white)
![Node.js](https://img.shields.io/badge/node.js-6DA55F?style=flat&logo=node.js&logoColor=white)

A production-ready Oracle Database environment with a Node.js-based management server, fully containerized using Docker.

## 🎯 Features

- Oracle Free Database 23c
- Node.js-based management server
- Oracle SQLcl and APEX integration
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

### Environment Configuration
Create a `.env` file in the project root:
```bash
# Required
ORACLE_PWD=your_secure_password  # Database system password

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

## 🚀 Quick Start

1. **Clone the Repository**
   ```bash
   git clone https://github.com/demasy/oracle-database.git
   cd oracle-database
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your secure password
   ```

3. **Build Services**
   ```bash
   docker-compose build --no-cache
   ```

4. **Launch Environment**
   ```bash
   # Interactive mode
   docker compose up

   # Or in detached mode
   docker compose up -d
   ```

5. **Verify Health**
   ```bash
   curl http://localhost:3000/health
   ```

## ⚙️ Service Management

### Container Operations

#### Database Service
```bash
# Lifecycle Management
docker stop oracle-database-23ai    # Stop the database
docker start oracle-database-23ai   # Start the database
docker restart oracle-database-23ai # Restart the database
docker rm -f oracle-database-23ai   # Remove the container

# Access & Monitoring
docker exec -it oracle-database-23ai bash  # Shell access
docker logs oracle-database-23ai    # View logs
docker logs -f oracle-database-23ai # Follow logs
```

#### Management Server
```bash
# Lifecycle Management
docker stop demasy-server    # Stop the server
docker start demasy-server   # Start the server
docker restart demasy-server # Restart the server
docker rm -f demasy-server   # Remove the container

# Access & Monitoring
docker exec -it demasy-server bash  # Shell access
docker logs demasy-server    # View logs
docker logs -f demasy-server # Follow logs
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

