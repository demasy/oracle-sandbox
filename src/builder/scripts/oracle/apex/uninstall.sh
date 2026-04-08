#!/bin/bash
################################################################################
# Uninstall Oracle APEX
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

log_warn "This will remove APEX from the database and clean up all files."
read -p "Are you sure you want to uninstall APEX? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Stop ORDS
log_info "Stopping ORDS..."
./apex-stop.sh 2>/dev/null || true

# Remove APEX from database
log_info "Removing APEX from database..."
docker exec oracle-al-database-26ai bash -c 'cd /tmp/apex-install/apex && echo "ALTER SESSION SET CONTAINER=FREEPDB1;
@apxremov.sql
EXIT" | sqlplus / as sysdba' > /tmp/apex_uninstall.log 2>&1

if grep -q "successfully completed" /tmp/apex_uninstall.log; then
    log_info "✓ APEX removed from database"
else
    log_warn "APEX removal may have issues. Check /tmp/apex_uninstall.log"
fi

# Clean up ORDS metadata
log_info "Cleaning ORDS metadata..."
docker exec oracle-al-database-26ai bash -c 'echo "ALTER SESSION SET CONTAINER=FREEPDB1;
DROP USER ORDS_METADATA CASCADE;
DROP USER ORDS_PUBLIC_USER CASCADE;
DROP USER DEMASY_DEV CASCADE;
EXIT" | sqlplus / as sysdba' > /dev/null 2>&1 || true

# Clean up files in containers
log_info "Cleaning up files..."
docker exec demasy-server rm -rf /tmp/apex-install /tmp/i /tmp/ords-config /tmp/ords.log /tmp/ords-access.log 2>/dev/null || true
docker exec oracle-al-database-26ai rm -rf /tmp/apex-install 2>/dev/null || true

# Clean up local downloads (optional)
read -p "Remove local downloads (/tmp/apex.zip, /tmp/ords.zip)? (yes/no): " CLEAN_DOWNLOADS
if [ "$CLEAN_DOWNLOADS" = "yes" ]; then
    rm -f /tmp/apex.zip /tmp/ords.zip /tmp/apex_install.log /tmp/apex_uninstall.log
    log_info "✓ Local downloads removed"
fi

echo ""
log_info "=================================================================="
log_info "    APEX Uninstallation Complete!"
log_info "=================================================================="
echo ""
echo "To reinstall APEX, run: ./apex-install.sh"
