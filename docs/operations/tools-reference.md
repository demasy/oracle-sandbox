# Oracle Sandbox Tools Reference Guide

**Complete inventory of tools, libraries, and utilities for the Demasy Oracle Sandbox.**

Last Updated: 2026-06-22  
Total Tools: 44 | Free: 38 (86%) | Paid: 6 (14%)

---

## Table of Contents

1. [Database & Core Tools](#database--core-tools-)
2. [Performance & Monitoring](#performance--monitoring-)
3. [Testing & Quality](#testing--quality-)
4. [Performance Testing & Load](#performance-testing--load-)
5. [API & Connectivity Testing](#api--connectivity-testing-)
6. [Security & Vulnerability Scanning](#security--vulnerability-scanning-)
7. [Containerization & Orchestration](#containerization--orchestration-)
8. [CI/CD & Automation](#cicd--automation-)
9. [Database Migration & Versioning](#database-migration--versioning-)
10. [Development Tools & IDEs](#development-tools--ides-)
11. [Observability & Tracing](#observability--tracing-)
12. [Documentation & Reporting](#documentation--reporting-)

---

## **DATABASE & CORE TOOLS** 📊

Essential tools for Oracle database management and SQL development.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 1 | **Oracle Database Free** | Primary RDBMS engine (Oracle AI DB 26ai) | Oracle Free License | FREE |
| 2 | **SQLcl** | Command-line SQL client & scripting | Free Download | FREE |
| 3 | **SQL*Plus** | Interactive SQL & PL/SQL execution | Included with Oracle | FREE |
| 4 | **SQL Developer** | IDE for SQL/PL/SQL development | Always Free | FREE |
| 5 | **Oracle Enterprise Manager Express** | Web-based DB admin UI (not available in Free Edition) | Included with Oracle | FREE |
| 6 | **RMAN** | Database backup & recovery management | Included with Oracle | FREE |
| 7 | **Data Pump** | High-speed data export/import | Included with Oracle | FREE |
| 8 | **v$ & dba_* Views** | Performance & configuration data dictionary views | Included with Oracle | FREE |

### Setup & Usage

**Oracle Database Free**
```bash
docker pull container-registry.oracle.com/database/free:latest
docker run -d -e ORACLE_PWD=YourPassword oracle/database:free
```

**SQLcl Installation**
```bash
# Download from Oracle
# Located in: libs/oracle/SQLcl/

# Usage
sql /nolog
SQL> connect sys/password@localhost:1521/FREEPDB1 as sysdba
```

**SQL Developer**
- Download from [oracle.com/sqldev](https://www.oracle.com/sqldev)
- Pre-configured connection templates in sandbox

---

## **PERFORMANCE & MONITORING** 📈

Tools for database monitoring, diagnostics, and performance tuning.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 9 | **SQL Trace + TKPROF** | Query execution analysis & explain plans | Included with Oracle | FREE |
| 10 | **AWR Reports** | Oracle built-in performance diagnostics | Included with Oracle | FREE |
| 11 | **APEX Monitoring Dashboard** | Custom performance metrics UI (to build) | N/A (custom) | FREE |
| 12 | **Grafana** | Time-series metrics visualization & dashboards | AGPL-3.0 | FREE |
| 13 | **Prometheus** | Metrics collection & time-series database | Apache 2.0 | FREE |
| 14 | **Portainer** | Docker container management UI | Zlib/Edge-free | FREE |
| 15 | **Log Viewer / Log Aggregator** | Centralized log analysis (custom or ELK) | Varies | FREE |

### Setup & Usage

**SQL Trace**
```sql
ALTER SESSION SET SQL_TRACE = TRUE;
-- Run your query
ALTER SESSION SET SQL_TRACE = FALSE;
-- Trace file location: $ORACLE_BASE/diag/rdbms/*/*/trace/
```

**TKPROF Analysis**
```bash
tkprof trace_file.trc output_file.txt
```

**APEX Monitoring Dashboard**
- Location: Sandbox APEX instance
- Port: 8080
- Query files: `src/builder/scripts/oracle/admin/`

**Grafana Setup**
```bash
docker run -d -p 3000:3000 grafana/grafana
# Add Prometheus data source
# Import dashboards for Oracle metrics
```

---

## **TESTING & QUALITY** ✅

Tools for code quality, unit testing, and code analysis.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 16 | **utPLSQL** | PL/SQL unit testing framework | Apache 2.0 | FREE |
| 17 | **tSQLt** | SQL Server unit testing (alternative) | MIT | FREE |
| 18 | **Quest CodeTester** | Enterprise PL/SQL testing platform | Commercial | $$$ |
| 19 | **Shellcheck** | Bash script linting & validation | GPL-3.0 | FREE |
| 20 | **SQLFormat** | SQL code formatting & standardization | MIT | FREE |
| 21 | **SonarQube** | Code quality analysis & technical debt | AGPL-3.0 / Commercial | FREE (Community) / $$ (Enterprise) |
| 22 | **PL/SQL CodeInspector** | Static analysis for PL/SQL code | Included with SQL Developer | FREE |

### Installation & Usage

**utPLSQL Installation**
```sql
-- Download and extract
@utPLSQL/install.sql

-- Create test package
CREATE PACKAGE ut_user_tests AS
  PROCEDURE test_create_user;
END;

-- Run tests
BEGIN
  ut.run();
END;
/
```

**Shellcheck Installation**
```bash
brew install shellcheck
shellcheck src/builder/scripts/**/*.sh
```

**SQLFormat Installation**
```bash
pip install sqlformat
sqlformat --reindent --use_spaces=2 your_file.sql
```

**SonarQube Community**
```bash
docker run -d -p 9000:9000 sonarqube:community
# Access: http://localhost:9000
# Default: admin/admin
```

---

## **PERFORMANCE TESTING & LOAD** ⚡

Tools for load testing and performance benchmarking.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 23 | **Apache Benchmark (ab)** | Simple HTTP load testing tool | Apache 2.0 | FREE |
| 24 | **Artillery** | Advanced load & performance testing | MPL-2.0 | FREE |

### Setup & Usage

**Apache Benchmark**
```bash
ab -n 1000 -c 10 http://localhost:8080/api/users
# -n: total requests
# -c: concurrent requests
```

**Artillery Installation**
```bash
npm install -g artillery
artillery quick --count 100 --num 10 http://localhost:3000/health
```

---

## **API & CONNECTIVITY TESTING** 🔗

Tools for REST API testing and HTTP connectivity validation.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 25 | **curl** | Command-line HTTP client & API testing | MIT | FREE |
| 26 | **Postman CLI** | Advanced API testing & automation | Apache 2.0 (CLI) | FREE (CLI) / $$ (Cloud) |
| 27 | **Postman Desktop** | GUI-based API testing & documentation | Commercial | FREE (Essentials) / $$ (Pro) |

### Usage Examples

**curl**
```bash
# GET request
curl http://localhost:8080/ords/demo/users

# POST request with JSON
curl -X POST http://localhost:8080/ords/demo/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com"}'

# With authentication
curl -u username:password http://localhost:8080/api/secure
```

**Postman CLI**
```bash
npm install -g postman
postman login
postman collection run my_collection.json
```

---

## **SECURITY & VULNERABILITY SCANNING** 🔒

Tools for security scanning and vulnerability detection.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 28 | **Trivy** | Container & dependency vulnerability scanning | Apache 2.0 | FREE |
| 29 | **OWASP Scan** | Web application security scanning | Apache 2.0 | FREE |

### Setup & Usage

**Trivy Installation**
```bash
brew install trivy
trivy image oracle/database:free
trivy fs ./
```

**OWASP ZAP Scan**
```bash
docker run -t owasp/zap2docker-stable zap-baseline.py -t http://localhost:8080
```

### Results Location
```
logs/security-reports/
├── demasy-server-scan_*.json
├── demasy-server-scan_*.html
├── oracle-db-scan_*.sarif
└── oracle-db-scan_*.html
```

---

## **CONTAINERIZATION & ORCHESTRATION** 🐳

Tools for container management and multi-container orchestration.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 30 | **Docker** | Container runtime & image management | Moby/Docker CE | FREE |
| 31 | **Docker Compose** | Multi-container orchestration | Apache 2.0 | FREE |

### Configuration

**Main Compose File**
```yaml
# Location: docker-compose.yml
services:
  sandbox-oracle-database:
    image: container-registry.oracle.com/database/free:latest
    ports:
      - "127.0.0.1:1521:1521"
  
  sandbox-oracle-server:
    image: demasylabs-oracle-sandbox:latest
    ports:
      - "127.0.0.1:3000:3000"
      - "127.0.0.1:8080:8080"
```

**Usage**
```bash
docker-compose up -d                # Start all services
docker-compose down                 # Stop all services
docker-compose logs -f              # View logs
docker-compose ps                   # Status
```

---

## **CI/CD & AUTOMATION** 🔄

Tools for continuous integration and automation workflows.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 32 | **Git Hooks** | Pre-commit validation & automation | Built-in | FREE |
| 33 | **Liquibase** | Database change management & versioning | AGPL-3.0 / Commercial | FREE (Community) / $$ (Pro) |
| 34 | **Jenkins** | CI/CD pipeline orchestration | MIT | FREE |

### Git Hooks Setup

**Pre-commit Hook** (`.git/hooks/pre-commit`)
```bash
#!/bin/bash

# Run Shellcheck on all shell scripts
find src/builder/scripts -name "*.sh" -exec shellcheck {} \;
if [ $? -ne 0 ]; then
  echo "Shellcheck failed. Commit aborted."
  exit 1
fi

# Run SQLFormat check
for sql_file in $(git diff --cached --name-only | grep '\.sql$'); do
  sqlformat --check "$sql_file" || exit 1
done

exit 0
```

**Make executable**
```bash
chmod +x .git/hooks/pre-commit
```

### Liquibase Setup

**Community Edition**
```bash
docker run -v $(pwd):/liquibase/changelog \
  liquibase/liquibase \
  --changeLogFile=changelog.xml update
```

---

## **DATABASE MIGRATION & VERSIONING** 📦

Tools for schema versioning and automated migrations.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 35 | **Liquibase** | Schema versioning & automated deployments | AGPL-3.0 / Commercial | FREE (Community) / $$ (Pro) |
| 36 | **Backup Automation** | Point-in-time recovery scripts (custom) | N/A (custom) | FREE |

### Backup Script Example

**Location:** `builder/scripts/backup.sh`
```bash
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

expdp username/password@oracle_service \
  DUMPFILE=$BACKUP_DIR/dump.dmp \
  LOGFILE=$BACKUP_DIR/export.log
```

---

## **DEVELOPMENT TOOLS & IDEs** 💻

Integrated development environments for SQL and application development.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 37 | **SQL Developer** | Oracle IDE for SQL/PL/SQL development | Always Free | FREE |
| 38 | **VS Code** | Multi-language editor | MIT | FREE |
| 39 | **DataGrip** | JetBrains database IDE | Commercial | $$ (Annual License) |
| 40 | **JetBrains IntelliJ** | Full-featured Java IDE | Commercial | $$ (Annual License) |

### Recommended VS Code Extensions

```json
{
  "recommendations": [
    "Oracle.oracle-devtools",
    "ms-mssql.mssql",
    "erd-vscode.erd-vscode",
    "cweijan.dbfs",
    "ms-azuretools.vscode-docker"
  ]
}
```

### SQL Developer Configuration

**Connection Setup**
1. Tools → Connections
2. New Connection
3. Connection Name: `SandboxOracle`
4. Username: `sys`
5. Password: `YourPassword`
6. Hostname: `localhost`
7. Port: `1521`
8. Service Name: `FREEPDB1`

---

## **OBSERVABILITY & TRACING** 🔍

Tools for distributed tracing and system observability.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 41 | **OpenTelemetry** | Distributed tracing & observability framework | Apache 2.0 | FREE |
| 42 | **Jaeger** | Distributed tracing backend | Apache 2.0 | FREE |

### Setup (Optional - Advanced)

**Jaeger Deployment**
```bash
docker run -d \
  -p 6831:6831/udp \
  -p 16686:16686 \
  jaegertracing/all-in-one
# Access UI: http://localhost:16686
```

**Note**: Only recommended for teaching microservices architecture.

---

## **DOCUMENTATION & REPORTING** 📄

Tools for automatic documentation generation and reporting.

| # | Tool | Purpose | License | Cost |
|---|------|---------|---------|------|
| 43 | **Documentation Generator (SQLDoc)** | Auto-generate schema documentation (custom) | N/A (custom) | FREE |
| 44 | **AWR Report Generator** | Performance reporting & trending (custom) | N/A (custom) | FREE |

### AWR Reports

**Generate AWR Report**
```sql
BEGIN
  DBMS_WORKLOAD_REPOSITORY.create_snapshot(
    flush_level => DBMS_WORKLOAD_REPOSITORY.FLUSH_ALL
  );
END;
/

-- Generate HTML report (as SYS)
@$ORACLE_HOME/rdbms/admin/awrrpt.sql
```

### Schema Documentation Script

**Location:** `builder/scripts/generate-schema-docs.sql`
```sql
-- Generates HTML documentation of all tables, columns, and constraints
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF

SPOOL schema_documentation.html
SELECT '<html><body><h1>Database Schema Documentation</h1>' FROM dual;
SELECT '<table border="1">' || CHR(10) ||
       '<tr><th>Table</th><th>Columns</th><th>Indexes</th></tr>' FROM dual;

SELECT '<tr><td>' || table_name || '</td><td>' ||
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) ||
       '</td><td></td></tr>' FROM user_tab_columns
GROUP BY table_name;

SELECT '</table></body></html>' FROM dual;
SPOOL OFF
```

---

## **Summary by Category**

| Category | Free Tools | Paid Tools | Total |
|----------|-----------|-----------|-------|
| Database & Core | 8 | 0 | 8 |
| Performance & Monitoring | 7 | 0 | 7 |
| Testing & Quality | 6 | 1 | 7 |
| Performance Testing & Load | 2 | 0 | 2 |
| API & Connectivity | 2 | 1 | 3 |
| Security & Vulnerability | 2 | 0 | 2 |
| Containerization & Orchestration | 2 | 0 | 2 |
| CI/CD & Automation | 2 | 1 | 3 |
| Database Migration | 1 | 1 | 2 |
| Development Tools & IDEs | 2 | 2 | 4 |
| Observability & Tracing | 2 | 0 | 2 |
| Documentation & Reporting | 2 | 0 | 2 |
| **TOTALS** | **38 FREE** | **6 PAID** | **44 TOOLS** |

---

## **Implementation Roadmap (All FREE)**

### **Week 1: Foundation**
```
✅ Oracle Database Free
✅ SQLcl, SQL Developer
✅ Shellcheck, SQLFormat, Git Hooks
✅ utPLSQL setup
✅ SQL admin monitoring queries
```

### **Week 2: Monitoring & Testing**
```
✅ APEX Performance Dashboard
✅ Apache Benchmark, Artillery
✅ TKPROF guide + examples
✅ utPLSQL test examples
```

### **Week 3: Advanced**
```
✅ Grafana + Prometheus (optional)
✅ SonarQube Community
✅ Backup automation
✅ OpenTelemetry basics (if teaching microservices)
```

### **Week 4+: Polish**
```
✅ Portainer (optional)
✅ Documentation generator
✅ AWR trending reports
✅ CI/CD with GitHub Actions
```

---

## **Quick Reference by Use Case**

### **Learning Oracle Database**
```
Core:        Oracle DB Free, SQLcl, SQL Developer, TKPROF, AWR
Monitoring:  APEX Dashboard, SQL Trace, v$ Views
Testing:     utPLSQL
Docs:        Oracle documentation, brain.json
```

### **Performance Tuning**
```
Analysis:    TKPROF, AWR Reports, SQL Trace, Execution Plans
Monitoring:  Grafana, Prometheus, APEX Dashboard
Testing:     Apache Benchmark, Artillery
```

### **Development Best Practices**
```
Quality:     Shellcheck, SQLFormat, SonarQube Community
Testing:     utPLSQL, tSQLt
Version Control: Git Hooks, Liquibase
```

### **API Development**
```
Testing:     curl, Postman, Artillery
Security:    OWASP Scan, Trivy
Documentation: Postman docs feature
```

### **Infrastructure & DevOps**
```
Containers:  Docker, Docker Compose, Portainer
CI/CD:       Git Hooks, Jenkins
Backup:      RMAN, Data Pump, Backup Automation
Security:    Trivy, OWASP Scan
```

### **Security & Compliance**
```
Scanning:    Trivy, OWASP Scan
Testing:     utPLSQL (code quality)
Monitoring:  AWR, EM Express
```

---

## **Additional Resources**

- [Oracle Documentation](https://docs.oracle.com/)
- [APEX Documentation](https://apex.oracle.com/en/learn/documentation)
- [SQLcl User Guide](https://www.oracle.com/database/technologies/appdev/sqlcl.html)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [utPLSQL GitHub](https://github.com/utplsql/utPLSQL)

---

## **License Legend**

- ✅ = FREE & Open Source
- 🔵 = FREE with paid tiers available
- 💰 = PAID/Licensed
- 📦 = Included with Oracle

---

**Last Updated:** 2026-06-22  
**Total Investment:** $0 (All recommended tools are free)
