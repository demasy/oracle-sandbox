# ─── sandbox install ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox install <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

case "$RESOURCE" in
    oracle|client)
        log_step "Installing Oracle Instant Client..."
        bash /usr/sandbox/app/system/install/install-client.sh
        ;;
    sqlcl)
        log_step "Installing SQLcl..."
        bash /usr/sandbox/app/system/install/install-sqlcl.sh
        ;;
    sqlplus)
        log_step "Installing SQL*Plus..."
        bash /usr/sandbox/app/system/install/install-sqlplus.sh
        ;;
    apex)
        log_step "Installing APEX + ORDS..."
        bash /usr/sandbox/app/oracle/apex/install.sh
        ;;
esac
