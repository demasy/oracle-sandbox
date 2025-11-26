# Oracle APEX Installation Scripts

Production-ready scripts for Oracle APEX 24.2.0 and ORDS 25.3.1 on Oracle Database 23ai.

## 📁 Scripts Overview

| Script | Purpose |
|--------|---------|
| **apex-install-internal.sh** | Complete APEX + ORDS installation (runs inside container) |
| **apex-start.sh** | Start ORDS server (runs from host) |
| **apex-stop.sh** | Stop ORDS server (runs from host) |
| **apex-uninstall.sh** | Uninstall APEX and ORDS (runs from host) |

## 🚀 Quick Start

```bash
# Fresh installation
docker-compose up -d --build
docker exec demasy-server apex-install-internal.sh

# Access APEX
# URL: http://localhost:8080/ords/f?p=4550:1
# Workspace: INTERNAL | Username: ADMIN | Password: Demasy1986
```

## ✅ Installation Complete When You See

- ✓ APEX Version: 24.2.0 (VALID)
- ✓ All 5 accounts OPEN
- ✓ ORDS Running on port 8080
- ✓ HTTP 302 (APEX Builder), HTTP 200 (Static Images)

## 📦 What Gets Installed

- APEX 24.2.0 in `/opt/oracle/apex/` (1.1G)
- ORDS 25.3.1 in `/opt/oracle/ords/` (185M)
- Images in `/tmp/i/` (562M, 26,922 files)
- Schemas: APEX_240200, APEX_PUBLIC_USER, APEX_PUBLIC_ROUTER, ORDS_PUBLIC_USER, ORDS_METADATA

---
**Last Updated:** November 25, 2025
