# ─── sandbox restart ──────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox restart <resource>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# ─────────────────────────────────────────────────────────────────────────────

# Stop the service
log_info "Stopping ${RESOURCE}..."
ACTION=stop source /usr/sandbox/app/cli/sandbox-stop.sh || {
    log_error "Failed to stop ${RESOURCE}"
    exit 1
}

# Start the service
log_info "Starting ${RESOURCE}..."
ACTION=start source /usr/sandbox/app/cli/sandbox-start.sh || {
    log_error "Failed to start ${RESOURCE}"
    exit 1
}

log_info "Restart complete"
