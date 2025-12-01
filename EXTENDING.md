# Extending the Oracle Sandbox Base Image

The published base image (`demasy/oracle-sandbox:base`) includes all the infrastructure and scripts but **does not contain Oracle components** due to licensing restrictions.

## Quick Start

### Option 1: Use Our Complete Dockerfile Locally

```bash
git clone https://github.com/demasy/oracle-sandbox.git
cd oracle-sandbox
cp .env.example .env
# Edit .env with your Oracle download URLs
docker-compose build
docker-compose up -d
```

### Option 2: Extend the Base Image

Create your own `Dockerfile`:

```dockerfile
FROM demasy/oracle-sandbox:base

# Download Oracle Instant Client from GitHub Release
RUN mkdir -p /opt/oracle && \
    curl -L -f \
      "https://github.com/demasy/oracle-sandbox/releases/download/oracle-ic-23.7/instantclient-basic-linux-x64-23.7.0.24.10.zip" \
      -o /tmp/ic.zip && \
    unzip -qo /tmp/ic.zip -d /tmp && \
    mv /tmp/libs/oracle/clients/instantclient_23_7 /opt/oracle/instantclient && \
    rm -rf /tmp/ic.zip /tmp/libs

# Add your Oracle SQLcl (download from oracle.com first)
COPY ./sqlcl-25.3.0.322.2257.zip /tmp/
RUN unzip -qo /tmp/sqlcl-25.3.0.322.2257.zip -d /opt/oracle && \
    rm /tmp/sqlcl-25.3.0.322.2257.zip

# Add your Oracle APEX (download from oracle.com first)
COPY ./apex_24.2.zip /tmp/
RUN unzip -qo /tmp/apex_24.2.zip -d /opt/oracle && \
    rm /tmp/apex_24.2.zip

# Add your Oracle ORDS (download from oracle.com first)
COPY ./ords-25.3.1.365.2133.zip /tmp/
RUN unzip -qo /tmp/ords-25.3.1.365.2133.zip -d /opt/oracle/ords && \
    rm /tmp/ords-25.3.1.365.2133.zip

# Configure Oracle environment
ENV ORACLE_HOME=/opt/oracle/instantclient \
    LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH \
    PATH=/opt/oracle/instantclient:/opt/oracle/sqlcl/bin:$PATH

# The rest is already configured in the base image!
```

Then build:

```bash
docker build -t my-oracle-sandbox .
```

## What's Included in the Base Image

✅ **System Dependencies**:
- Node.js 20 LTS
- curl, unzip, vim, nano, git
- Network tools (ping, telnet, tcpdump, netstat)
- Monitoring tools (htop, lsof, jq)
- libaio1 (required for Oracle Instant Client)

✅ **Management Scripts**:
- `/usr/local/bin/sqlcl` - SQLcl connection helper
- `/usr/local/bin/sqlplus` - SQL*Plus connection helper  
- `/usr/local/bin/install-apex` - APEX installation script
- `/usr/local/bin/start-apex` - Start ORDS server
- `/usr/local/bin/stop-apex` - Stop ORDS server
- `/usr/local/bin/healthcheck` - System health verification

✅ **Directory Structure**:
- `/usr/demasy/app` - Management server application
- `/usr/demasy/scripts` - All utility and CLI scripts
- `/opt/oracle/instantclient` - (empty, ready for Instant Client)
- `/opt/oracle/apex` - (empty, ready for APEX)
- `/opt/oracle/ords` - (empty, ready for ORDS)

✅ **Environment Variables**:
- `DEMASYLABS_DB_HOST`, `DEMASYLABS_DB_PORT`, `DEMASYLABS_DB_SERVICE`
- Pre-configured for Oracle Database 26ai connection
- See `.env.example` for complete list

## Download Oracle Components

Before extending the image, download these from Oracle:

1. **Oracle Instant Client** (23.7+)
   - https://www.oracle.com/database/technologies/instant-client/downloads.html
   - Get: `instantclient-basic-linux.x64-23.7.0.24.10.zip`
   - **OR** use our GitHub Release: `oracle-ic-23.7`

2. **SQLcl** (25.3+)
   - https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/
   - Get: `sqlcl-25.3.0.322.2257.zip`

3. **Oracle APEX** (24.2+)
   - https://www.oracle.com/tools/downloads/apex-downloads/
   - Get: `apex_24.2.zip`

4. **Oracle ORDS** (25.3+)
   - https://www.oracle.com/database/technologies/appdev/rest-data-services-downloads.html
   - Get: `ords-25.3.1.365.2133.zip`

## Available Tags

- `base` - Latest base image
- `v1.0.1-base` - Versioned base image
- `latest` - ⚠️ NOT AVAILABLE (Oracle licensing)

## Image Sizes

- **Base image**: ~500 MB (Node.js + system deps + scripts)
- **With Oracle components**: ~1.2 GB (includes IC + SQLcl + APEX + ORDS)

## Platform Support

The base image supports:
- ✅ `linux/amd64` (x86_64)
- ✅ `linux/arm64` (aarch64)

Oracle components must match your platform.

## Example docker-compose.yml

```yaml
services:
  oracle-server:
    image: demasy/oracle-sandbox:base
    container_name: oracle-management
    volumes:
      - ./oracle-components:/oracle-components:ro
    environment:
      - DEMASYLABS_DB_HOST=oracle-database
      - DEMASYLABS_DB_SERVICE=FREEPDB1
    ports:
      - "3000:3000"
      - "8080:8080"
    command: >
      bash -c "
        cd /opt/oracle &&
        unzip -qo /oracle-components/instantclient.zip -d . &&
        unzip -qo /oracle-components/sqlcl.zip -d . &&
        unzip -qo /oracle-components/apex.zip -d . &&
        unzip -qo /oracle-components/ords.zip -d ./ords &&
        export LD_LIBRARY_PATH=/opt/oracle/instantclient &&
        node /usr/demasy/app/app.js
      "

  oracle-database:
    image: container-registry.oracle.com/database/free:latest
    container_name: oracle-database
    environment:
      - ORACLE_PWD=YourPassword123
    ports:
      - "1521:1521"
    volumes:
      - oracle-data:/opt/oracle/oradata

volumes:
  oracle-data:
```

## Questions?

- **Why no Oracle components?** Oracle's license terms prohibit redistribution
- **Can I share my extended image?** Only if you comply with Oracle's terms
- **Is this production-ready?** No, for development/training only

## Support

- 📖 Documentation: https://github.com/demasy/oracle-sandbox
- 🐛 Issues: https://github.com/demasy/oracle-sandbox/issues
- 💬 Discussions: https://github.com/demasy/oracle-sandbox/discussions

---

**Maintained by**: Ahmed El-Demasy (@demasy)  
**License**: MIT (base image and scripts), Oracle components subject to Oracle's terms
