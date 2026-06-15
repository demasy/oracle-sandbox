# ─── sandbox restart ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox restart <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

ACTION=stop  source /usr/sandbox/app/cli/sandbox-stop.sh
log_info "Restarting..."
ACTION=start source /usr/sandbox/app/cli/sandbox-start.sh
