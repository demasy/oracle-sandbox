# ─── sandbox install ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox install <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    oracle|client)
        log_step "Installing Oracle Instant Client..."
        bash /usr/demasy/scripts/oracle/admin/install-client.sh
        ;;
    sqlcl)
        log_step "Installing SQLcl..."
        bash /usr/demasy/scripts/oracle/admin/install-sqlcl.sh
        ;;
    sqlplus)
        log_step "Installing SQL*Plus..."
        bash /usr/demasy/scripts/oracle/admin/install-sqlplus.sh
        ;;
    apex)
        log_step "Installing APEX + ORDS..."
        bash /usr/demasy/scripts/oracle/apex/install.sh
        ;;
esac
