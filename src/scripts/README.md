# Scripts Directory

Organized collection of scripts for Oracle Database 23ai management and operations.

## 📁 Directory Structure

```
src/scripts/
├── bin/                    # Compiled binaries and utilities
│   ├── backbone/          # Core system utilities
│   └── common/            # Common shared binaries
│
├── cli/                    # User-facing command-line tools
│   ├── sqlcl-connect.sh   # SQLcl database connection
│   └── sqlplus-connect.sh # SQL*Plus database connection
│
├── setup/                  # Installation and setup scripts
│   ├── docker-refresh.sh  # Docker environment refresh
│   └── npm-refresh.sh     # NPM dependencies refresh
│
├── oracle/                 # Oracle-specific scripts
│   ├── admin/             # Administrative tasks
│   │   └── healthcheck.sh # System health monitoring
│   │
│   ├── apex/              # Oracle APEX management
│   │   ├── install.sh    # APEX installation
│   │   ├── uninstall.sh  # APEX removal
│   │   ├── start.sh      # Start ORDS for APEX
│   │   ├── stop.sh       # Stop ORDS
│   │   └── README.md     # APEX documentation
│   │
│   ├── mcp/               # Model Context Protocol
│   │   ├── start.sh      # Start MCP server
│   │   ├── setup-connection.sh
│   │   ├── docs/         # MCP documentation
│   │   └── ...
│   │
│   └── database/          # Database operations (future)
│
├── utils/                  # Shared utilities (DRY principle)
│   ├── colors.sh          # Color definitions
│   ├── banner.sh          # Banner printing
│   └── logging.sh         # Logging functions
│
├── ci/                     # CI/CD scripts (future)
├── docker/                 # Docker utilities (future)
└── experimental/           # Experimental/archived scripts
    └── README.md          # Experimental scripts warning
```

## 🚀 Quick Start

### CLI Tools
```bash
# Connect with SQLcl — auto-login as system (uses DEMASYLABS_* env vars)
docker exec -it demasylabs-oracle-server sqlcl

# Connect with SQLcl — custom credentials / connection string (pass-through)
docker exec -it demasylabs-oracle-server sqlcl roketto/Roketto1986@//192.168.1.110:1521/ROKETTO_PDB
docker exec -it demasylabs-oracle-server sqlcl -version

# Connect with SQL*Plus — auto-login as system
docker exec -it demasylabs-oracle-server sqlplus

# Connect with SQL*Plus — custom credentials (pass-through)
docker exec -it demasylabs-oracle-server sqlplus roketto/Roketto1986@//192.168.1.110:1521/ROKETTO_PDB
```

### Admin Tools
```bash
# Run health check
docker exec -it demasy-server healthcheck
```

### APEX Management
```bash
# Install APEX
docker exec -it demasy-server install-apex

# Start APEX (ORDS)
docker exec -it demasy-server apex-start

# Stop APEX
docker exec -it demasy-server apex-stop
```

### MCP Server
```bash
# Start MCP server
docker exec -it demasy-server start-mcp
```

## 📝 Naming Conventions

### Files
- **Scripts**: `action-noun.sh` (e.g., `install.sh`, `start.sh`)
- **Utilities**: `noun.sh` (e.g., `colors.sh`, `logging.sh`)
- **Prefixes removed**: Context from directory name (no more `apex-*`, `mcp-*`)

### Directories
- **Lowercase**: All directory names
- **Hyphenated**: Multi-word directories (e.g., `oracle-admin`)
- **Flat structure**: Avoid deep nesting (max 3 levels)

## 🛠️ Development Guidelines

### Using Shared Utilities

```bash
#!/bin/bash
# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/banner.sh"

# Use logging functions
log_info "Starting process..."
log_success "Completed successfully!"
log_error "Something went wrong"

# Use banner
print_demasy_banner "Your Script Title"
```

### Adding New Scripts

1. **Choose correct location** based on purpose
2. **Use shared utilities** (colors, logging, banner)
3. **Add executable permission**: `chmod +x script.sh`
4. **Update Dockerfile** if needed for Docker integration
5. **Document in README** if it's a user-facing tool

## 📚 Documentation

- **APEX**: See `oracle/apex/README.md`
- **MCP**: See `oracle/mcp/docs/`
- **Experimental**: See `experimental/README.md`

## ⚠️ Important Notes

- **Don't modify** files in `experimental/` - they're archived
- **Use shared utilities** to avoid code duplication
- **Keep structure flat** - avoid deep nesting
- **Update Dockerfile** when adding new production scripts

## 🔗 Related Files

- `Dockerfile` - Script deployment configuration
- `.gitignore` - Excluded directories and files
- `docker-compose.yml` - Environment configuration

---

**Developed by Demasy Labs** 🚀  
Code with love ❤️ in Egypt
