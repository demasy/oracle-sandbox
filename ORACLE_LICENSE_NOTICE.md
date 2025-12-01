# Oracle Licensing and Distribution Notice

## Important Information About Pre-built Docker Images

**⚠️ Pre-built Docker images for this project are NOT available on Docker Hub or GitHub Container Registry.**

### Why?

Oracle's software components (SQLcl, APEX, ORDS, SQL*Plus, Instant Client) require:

1. **License Agreement Acceptance**: Users must explicitly accept Oracle's license terms before downloading
2. **Manual Download**: Automated downloads from Oracle's servers are restricted and require authentication
3. **Redistribution Restrictions**: Oracle's license terms prohibit redistribution of their software components

### What This Means

- ✅ **Source code** is freely available and open source (MIT License)
- ❌ **Pre-built images** cannot be automatically published to container registries
- ✅ **You can build** images locally after downloading Oracle components yourself

## How to Build Locally

### Step 1: Clone the Repository
```bash
git clone https://github.com/demasy/oracle-sandbox.git
cd oracle-sandbox
```

### Step 2: Download Oracle Components

Visit Oracle's website and download the following:

1. **Oracle Instant Client** (23.7 or later)
   - URL: https://www.oracle.com/database/technologies/instant-client/downloads.html
   - File: `instantclient-basic-linux.x64-23.7.0.24.10.zip`

2. **SQLcl** (25.3 or later)
   - URL: https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/
   - File: `sqlcl-25.3.0.322.2257.zip`

3. **Oracle APEX** (24.2 or later)
   - URL: https://www.oracle.com/tools/downloads/apex-downloads/
   - File: `apex_24.2.zip`

4. **Oracle REST Data Services (ORDS)** (25.3 or later)
   - URL: https://www.oracle.com/database/technologies/appdev/rest-data-services-downloads.html
   - File: `ords-25.3.1.365.2133.zip`

5. **SQL*Plus** (optional, 23.7 or later)
   - URL: https://www.oracle.com/database/technologies/instant-client/downloads.html
   - File: `instantclient-sqlplus-linux.x64-23.7.0.24.10.zip`

### Step 3: Configure Environment

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Update `.env` with your download URLs or local file paths:
   ```bash
   ENV_SRC_ORACLE_SQLCL=file:///path/to/sqlcl-25.3.0.322.2257.zip
   ENV_SRC_ORACLE_APEX=file:///path/to/apex_24.2.zip
   ENV_SRC_ORACLE_ORDS=file:///path/to/ords-25.3.1.365.2133.zip
   ```

### Step 4: Build Images

```bash
docker-compose build
```

### Step 5: Start Services

```bash
docker-compose up -d
```

## Alternative: Manual Installation in Running Container

If you prefer, you can:

1. Start containers without Oracle components
2. Download Oracle files manually
3. Copy them into the running containers
4. Install them interactively

See the main README.md for detailed instructions.

## Oracle Instant Client GitHub Release

We provide **Oracle Instant Client only** via GitHub Releases (`oracle-ic-23.7`) because:
- It's required for Docker builds
- It has a more permissive redistribution policy for basic client libraries
- Other components (APEX, ORDS, SQLcl) have stricter terms

## Questions?

- **Can I share my built images?** Only if you comply with Oracle's license terms
- **Can I use this commercially?** Check Oracle's licensing for each component
- **Is there a workaround?** No, Oracle's terms must be respected

## Legal Disclaimer

This project respects Oracle's intellectual property rights and licensing terms. Users are responsible for ensuring their use complies with all applicable Oracle licenses.

---

**Project**: Oracle Sandbox  
**License**: MIT (for source code only, not Oracle components)  
**Maintainer**: Ahmed El-Demasy (@demasy)  
**Last Updated**: December 1, 2025
