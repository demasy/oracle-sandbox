# ─── sandbox audit ────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox audit [list|show|rollback|export]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Provides: Audit logging, operation tracking, and rollback capability
# ─────────────────────────────────────────────────────────────────────────────

# Audit log configuration
AUDIT_LOG_DIR="${SANDBOX_LOG_DIR:-/tmp/sandbox_audit}"
AUDIT_LOG_FILE="$AUDIT_LOG_DIR/audit.log"
AUDIT_ACTIONS_DIR="$AUDIT_LOG_DIR/actions"

# Initialize audit system
_audit_init() {
    mkdir -p "$AUDIT_LOG_DIR" "$AUDIT_ACTIONS_DIR" 2>/dev/null
    [[ ! -f "$AUDIT_LOG_FILE" ]] && touch "$AUDIT_LOG_FILE"
}

# Log an operation to audit trail
_audit_log_operation() {
    local action="$1"
    local resource="$2"
    local operation="$3"
    local user="${4:-${USER:-sandbox}}"
    local status="${5:-success}"
    
    _audit_init
    
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S")
    local iso_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry_id="$(date +%s).$$"
    
    # Write to main audit log
    local log_entry="[$timestamp] [$entry_id] ACTION: $action | RESOURCE: $resource | OP: $operation | USER: $user | STATUS: $status"
    echo "$log_entry" >> "$AUDIT_LOG_FILE"
    
    # Write detailed action file for potential rollback
    local action_file="$AUDIT_ACTIONS_DIR/${entry_id}.action"
    cat > "$action_file" << EOF
{
  "id": "$entry_id",
  "timestamp": "$iso_timestamp",
  "action": "$action",
  "resource": "$resource",
  "operation": "$operation",
  "user": "$user",
  "status": "$status",
  "details": {},
  "rollback_cmd": ""
}
EOF
    
    return 0
}

# Retrieve audit log entries
_audit_list() {
    local limit="${1:-50}"
    local filter="${2:-}"
    
    _audit_init
    
    if [[ -z "$filter" ]]; then
        tail -n "$limit" "$AUDIT_LOG_FILE"
    else
        grep "$filter" "$AUDIT_LOG_FILE" | tail -n "$limit"
    fi
}

# Show detailed audit entry
_audit_show() {
    local entry_id="$1"
    
    [[ -z "$entry_id" ]] && _log "error" "Entry ID required" && return 1
    
    local action_file="$AUDIT_ACTIONS_DIR/${entry_id}.action"
    
    if [[ -f "$action_file" ]]; then
        cat "$action_file"
    else
        _log "error" "Audit entry not found: $entry_id"
        return 1
    fi
}

# Search audit logs by criteria
_audit_search() {
    local criteria="$1"
    local output_format="${2:-table}"
    
    _audit_init
    
    case "$output_format" in
        json)
            # Convert audit entries to JSON
            local count=0
            echo "{"
            echo '  "entries": ['
            
            grep "$criteria" "$AUDIT_LOG_FILE" | while read -r line; do
                ((count++))
                # Parse line and output as JSON
                local timestamp=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | head -1)
                local id=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | tail -1)
                local action=$(echo "$line" | grep -oP 'ACTION: \K[^|]+')
                
                echo "    {"
                echo "      \"id\": \"$id\","
                echo "      \"timestamp\": \"$timestamp\","
                echo "      \"action\": \"$action\""
                echo "    },"
            done | sed '$ s/,$//'
            
            echo "  ]"
            echo "}"
            ;;
        csv)
            echo "timestamp,id,action,resource,operation,user,status"
            grep "$criteria" "$AUDIT_LOG_FILE" | while read -r line; do
                local timestamp=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | head -1)
                local id=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | tail -1)
                local action=$(echo "$line" | grep -oP 'ACTION: \K[^|]+' | xargs)
                local resource=$(echo "$line" | grep -oP 'RESOURCE: \K[^|]+' | xargs)
                local operation=$(echo "$line" | grep -oP 'OP: \K[^|]+' | xargs)
                local user=$(echo "$line" | grep -oP 'USER: \K[^|]+' | xargs)
                local status=$(echo "$line" | grep -oP 'STATUS: \K[^ ]+')
                
                echo "$timestamp,$id,$action,$resource,$operation,$user,$status"
            done
            ;;
        *)
            # Table format
            echo ""
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${CYAN}                      AUDIT LOG SEARCH RESULTS${NC}"
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo ""
            
            grep "$criteria" "$AUDIT_LOG_FILE" | tail -20 | while read -r line; do
                echo -e "${WHITE}$line${NC}"
            done
            
            echo ""
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            echo ""
            ;;
    esac
}

# Export audit logs for compliance/archival
_audit_export() {
    local format="${1:-json}"
    local start_date="${2:-}"
    local end_date="${3:-}"
    
    _audit_init
    
    # Filter by date range if provided
    local grep_filter=""
    if [[ -n "$start_date" && -n "$end_date" ]]; then
        grep_filter="^\\[$start_date.*\\].*\\|^\\[$end_date.*\\]"
    fi
    
    case "$format" in
        json)
            echo "{"
            echo '  "export_timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")',"'
            echo '  "entries": ['
            
            cat "$AUDIT_LOG_FILE" | while read -r line; do
                [[ -z "$line" ]] && continue
                
                local timestamp=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | head -1)
                local id=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | tail -1)
                local action=$(echo "$line" | grep -oP 'ACTION: \K[^|]+' | xargs)
                local resource=$(echo "$line" | grep -oP 'RESOURCE: \K[^|]+' | xargs)
                local operation=$(echo "$line" | grep -oP 'OP: \K[^|]+' | xargs)
                local user=$(echo "$line" | grep -oP 'USER: \K[^|]+' | xargs)
                local status=$(echo "$line" | grep -oP 'STATUS: \K[^ ]+')
                
                echo "    {"
                echo "      \"timestamp\": \"$timestamp\","
                echo "      \"id\": \"$id\","
                echo "      \"action\": \"$action\","
                echo "      \"resource\": \"$resource\","
                echo "      \"operation\": \"$operation\","
                echo "      \"user\": \"$user\","
                echo "      \"status\": \"$status\""
                echo "    },"
            done | sed '$ s/,$//'
            
            echo "  ]"
            echo "}"
            ;;
        csv)
            echo "timestamp,id,action,resource,operation,user,status"
            cat "$AUDIT_LOG_FILE" | while read -r line; do
                [[ -z "$line" ]] && continue
                
                local timestamp=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | head -1)
                local id=$(echo "$line" | grep -oP '(?<=\[)[^\]]+(?=\])' | tail -1)
                local action=$(echo "$line" | grep -oP 'ACTION: \K[^|]+' | xargs)
                local resource=$(echo "$line" | grep -oP 'RESOURCE: \K[^|]+' | xargs)
                local operation=$(echo "$line" | grep -oP 'OP: \K[^|]+' | xargs)
                local user=$(echo "$line" | grep -oP 'USER: \K[^|]+' | xargs)
                local status=$(echo "$line" | grep -oP 'STATUS: \K[^ ]+')
                
                echo "\"$timestamp\",\"$id\",\"$action\",\"$resource\",\"$operation\",\"$user\",\"$status\""
            done
            ;;
    esac
}

# Rollback an operation using stored action files
_audit_rollback() {
    local entry_id="$1"
    
    [[ -z "$entry_id" ]] && _log "error" "Entry ID required for rollback" && return 1
    
    local action_file="$AUDIT_ACTIONS_DIR/${entry_id}.action"
    
    if [[ ! -f "$action_file" ]]; then
        _log "error" "Rollback file not found for entry: $entry_id"
        return 1
    fi
    
    # Extract rollback command from action file
    local rollback_cmd=$(grep -oP '(?<="rollback_cmd": ")[^"]+' "$action_file")
    
    if [[ -z "$rollback_cmd" ]]; then
        _log "warn" "No rollback command available for entry: $entry_id"
        return 1
    fi
    
    _log "info" "Executing rollback: $rollback_cmd"
    
    # Execute rollback command
    if eval "$rollback_cmd"; then
        _log "success" "Rollback completed successfully"
        _audit_log_operation "rollback" "system" "rollback_id=$entry_id" "${USER}" "success"
        return 0
    else
        _log "error" "Rollback failed"
        _audit_log_operation "rollback" "system" "rollback_id=$entry_id" "${USER}" "failed"
        return 1
    fi
}

# Show audit statistics
_audit_stats() {
    _audit_init
    
    local total_entries=$(wc -l < "$AUDIT_LOG_FILE")
    local success_count=$(grep -c "STATUS: success" "$AUDIT_LOG_FILE")
    local failed_count=$(grep -c "STATUS: failed" "$AUDIT_LOG_FILE")
    local unique_users=$(grep -oP 'USER: \K[^|]+' "$AUDIT_LOG_FILE" | sort -u | wc -l)
    local unique_actions=$(grep -oP 'ACTION: \K[^|]+' "$AUDIT_LOG_FILE" | sort -u | wc -l)
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                     AUDIT LOG STATISTICS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    printf "  %-30s: %d\n" "Total Entries" "$total_entries"
    printf "  %-30s: %d\n" "Successful Operations" "$success_count"
    printf "  %-30s: %d\n" "Failed Operations" "$failed_count"
    printf "  %-30s: %d\n" "Unique Users" "$unique_users"
    printf "  %-30s: %d\n" "Unique Actions" "$unique_actions"
    printf "  %-30s: %s\n" "Log Location" "$AUDIT_LOG_FILE"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Parse parameters
_search_criteria=$(_parse_param_value "--search" $PARAMS)
_export_format=$(_parse_param_value "--export" $PARAMS)
_limit=$(_parse_param_value "--limit" $PARAMS)

_log "info" "Audit operation: $RESOURCE"

case "$RESOURCE" in
    list)
        _audit_list "$_limit" "$_search_criteria"
        ;;
    show)
        [[ -z "$_search_criteria" ]] && _log "error" "Entry ID required" && exit 1
        _audit_show "$_search_criteria"
        ;;
    search)
        [[ -z "$_search_criteria" ]] && _log "error" "Search criteria required" && exit 1
        _audit_search "$_search_criteria" "$_export_format"
        ;;
    export)
        _audit_export "$_export_format"
        ;;
    stats)
        _audit_stats
        ;;
    rollback)
        [[ -z "$_search_criteria" ]] && _log "error" "Entry ID required" && exit 1
        _audit_rollback "$_search_criteria"
        ;;
    *)
        _log "error" "Unknown audit operation: $RESOURCE"
        _log "info" "Use: list|show|search|export|stats|rollback"
        exit 1
        ;;
esac
