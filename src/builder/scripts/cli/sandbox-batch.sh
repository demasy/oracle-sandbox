# ─── sandbox batch ─────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox batch <operation> --file <path>
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Provides: Batch processing framework for multiple operations
# ─────────────────────────────────────────────────────────────────────────────

# ─── Helper functions ──────────────────────────────────────────────────────────

# Validate batch file exists
_validate_batch_file() {
    local file="$1"
    [[ -z "$file" ]] && log_error "No file specified. Use: --file <path>" && return 1
    [[ ! -f "$file" ]] && log_error "File not found: $file" && return 1
    [[ ! -r "$file" ]] && log_error "File not readable: $file" && return 1
    return 0
}

# Execute a single sandbox command from batch
_execute_batch_command() {
    local cmd="$1"
    local dry_run="${2:-0}"
    
    [[ -z "$cmd" ]] && return 0
    
    # Log the command being executed
    log_info "Executing: $cmd"
    
    if [[ "$dry_run" == "1" ]]; then
        log_info "(DRY RUN - would execute above)"
        return 0
    fi
    
    # Execute the command and capture result
    local output
    output=$(eval "$cmd" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "✓ Command succeeded"
    else
        log_error "✗ Command failed with exit code: $exit_code"
        [[ -n "$output" ]] && log_info "debug" "Output: $output"
    fi
    
    return $exit_code
}

# Process batch file with connection additions (CSV format)
_batch_add_connections() {
    local file="$1"
    local dry_run="${2:-0}"
    local count=0 success=0 failed=0
    
    log_info "Processing connections batch from: $file"
    
    while IFS=',' read -r name user host port pdb password; do
        # Skip header
        [[ "$name" == "name" ]] && continue
        [[ -z "$name" ]] && continue
        
        ((count++))
        local cmd="sandbox conn add --name '$name' --user '$user'"
        [[ -n "$host" && "$host" != "-" ]] && cmd="$cmd --host '$host'"
        [[ -n "$port" && "$port" != "-" ]] && cmd="$cmd --port '$port'"
        [[ -n "$pdb" && "$pdb" != "-" ]] && cmd="$cmd --pdb '$pdb'"
        [[ -n "$password" && "$password" != "-" ]] && cmd="$cmd --pass '$password'"
        
        if _execute_batch_command "$cmd" "$dry_run"; then
            ((success++))
        else
            ((failed++))
        fi
    done < "$file"
    
    log_info "Batch summary: $count total, $success succeeded, $failed failed"
}

# Process batch file with general commands (commands are in 'cmd' column or entire line)
_batch_execute_commands() {
    local file="$1"
    local dry_run="${2:-0}"
    local count=0 success=0 failed=0 header_skip=0
    
    log_info "Processing command batch from: $file"
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Skip header if first line contains 'cmd' or 'command'
        if [[ $header_skip -eq 0 ]]; then
            [[ "$line" =~ cmd|command ]] && { header_skip=1; continue; }
        fi
        
        ((count++))
        local cmd="$line"
        
        # If line is CSV with cmd column, extract the command part
        if [[ "$line" == *","* ]] && [[ "$line" == *"="* ]]; then
            # Extract cmd value from CSV (e.g., "cmd=sandbox restart")
            cmd=$(echo "$line" | grep -oP '(?<=cmd=)[^,]+' | head -1)
            [[ -z "$cmd" ]] && cmd="$line"
        fi
        
        if _execute_batch_command "$cmd" "$dry_run"; then
            ((success++))
        else
            ((failed++))
        fi
    done < "$file"
    
    log_info "Batch summary: $count total, $success succeeded, $failed failed"
}

# Apply batch operations with rollback capability
_batch_apply_with_rollback() {
    local file="$1"
    local rollback_on_error="${2:-0}"
    local rollback_file="/tmp/sandbox_batch_rollback.sh"
    
    log_info "Applying batch with rollback capability"
    > "$rollback_file"  # Clear rollback file
    
    # Process commands and build rollback script as we go
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        
        local cmd="$line"
        
        if _execute_batch_command "$cmd" "0"; then
            # Add corresponding rollback command
            # Example: reverse "conn add" with "conn delete"
            if [[ "$cmd" == *"conn add"* ]]; then
                local conn_name=$(echo "$cmd" | grep -oP "(?<=--name ')[^']+" | head -1)
                echo "sandbox conn delete --name '$conn_name'" >> "$rollback_file"
            fi
        else
            if [[ "$rollback_on_error" == "1" ]]; then
                log_warning "Error detected. Rolling back previous operations..."
                if [[ -f "$rollback_file" ]] && [[ -s "$rollback_file" ]]; then
                    bash "$rollback_file"
                fi
                return 1
            fi
        fi
    done < "$file"
    
    log_success "Batch applied successfully. Rollback script at: $rollback_file"
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Parse parameters
_file=$(_parse_param_value "--file" $PARAMS)
_dry_run=0
_rollback=0
[[ "$PARAMS" =~ --dry-run ]] && _dry_run=1
[[ "$PARAMS" =~ --rollback ]] && _rollback=1

# Validate inputs
_validate_batch_file "$_file" || exit 1

# Log batch operation start
log_step "Starting batch operation: $RESOURCE"
[[ "$_dry_run" == "1" ]] && log_info "[dry-run] No changes will be made."

# Dispatch based on operation type
case "$RESOURCE" in
    apply-connections)
        _batch_add_connections "$_file" "$_dry_run"
        ;;
    apply-commands)
        _batch_execute_commands "$_file" "$_dry_run"
        ;;
    apply-with-rollback)
        _batch_apply_with_rollback "$_file" "$_rollback"
        ;;
    execute)
        # Generic command execution from batch file
        _batch_execute_commands "$_file" "$_dry_run"
        ;;
    *)
        log_error "Unknown batch operation: $RESOURCE"
        log_info "Use: apply-connections|apply-commands|apply-with-rollback|execute"
        exit 1
        ;;
esac

log_success "Batch operation completed"
