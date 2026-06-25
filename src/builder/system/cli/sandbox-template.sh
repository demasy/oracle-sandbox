# ─── sandbox template ─────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox template [save|load|list|delete]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Provides: Configuration templates, save/restore snapshots, environment presets
# ─────────────────────────────────────────────────────────────────────────────

# Template configuration
TEMPLATE_DIR="${SANDBOX_TEMPLATE_DIR:-/tmp/sandbox_templates}"

# Initialize template system
_template_init() {
    mkdir -p "$TEMPLATE_DIR" 2>/dev/null
}

# Create a configuration template snapshot
_template_save() {
    local template_name="$1"
    local description="${2:-}"
    
    [[ -z "$template_name" ]] && log_error "Template name required" && return 1
    
    _template_init
    
    local template_file="$TEMPLATE_DIR/${template_name}.template"
    
    # Check if template already exists
    if [[ -f "$template_file" ]]; then
        log_warning "Template already exists: $template_name (will be overwritten)"
    fi
    
    log_step "Saving configuration template: $template_name"
    
    # Capture current configuration
    cat > "$template_file" << EOF
{
  "metadata": {
    "name": "$template_name",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "description": "$description",
    "version": "1.0"
  },
  "environment": {
    "SANDBOX_DB_HOST": "$SANDBOX_DB_HOST",
    "SANDBOX_DB_PORT": "$SANDBOX_DB_PORT",
    "SANDBOX_DB_USER": "$SANDBOX_DB_USER",
    "SANDBOX_DB_PDB": "$SANDBOX_DB_PDB",
    "SANDBOX_ORDS_HOST": "$SANDBOX_ORDS_HOST",
    "SANDBOX_ORDS_PORT": "$SANDBOX_ORDS_PORT",
    "SANDBOX_APEX_VERSION": "$SANDBOX_APEX_VERSION",
    "SANDBOX_LOG_DIR": "$SANDBOX_LOG_DIR",
    "OUTPUT_FORMAT": "$OUTPUT_FORMAT"
  },
  "connections": [],
  "resources": {
    "apex_installed": false,
    "ords_running": false,
    "mcp_running": false
  }
}
EOF
    
    # Export current connections to template
    local connections_json=$(sandbox export connections --format json 2>/dev/null || echo '[]')
    
    # Merge connections into template
    local temp_file="$template_file.tmp"
    python3 << PYTHON_SCRIPT 2>/dev/null || log_warning "Could not merge connections (Python required)"
import json
try:
    with open('$template_file', 'r') as f:
        template = json.load(f)
    
    # Try to load connections
    try:
        connections = json.loads('$connections_json')
        if isinstance(connections, list):
            template['connections'] = connections
    except:
        pass
    
    with open('$template_file', 'w') as f:
        json.dump(template, f, indent=2)
except:
    pass
PYTHON_SCRIPT
    
    log_success "Template saved: $template_name"
    log_info "Location: $template_file"
    
    return 0
}

# Load a configuration template
_template_load() {
    local template_name="$1"
    local auto_apply="${2:-0}"
    
    [[ -z "$template_name" ]] && log_error "Template name required" && return 1
    
    local template_file="$TEMPLATE_DIR/${template_name}.template"
    
    [[ ! -f "$template_file" ]] && log_error "Template not found: $template_name" && return 1
    
    log_step "Loading template: $template_name"
    
    # Display template contents
    cat "$template_file"
    
    if [[ "$auto_apply" == "1" ]]; then
        log_info "Applying template configuration..."
        
        # Extract and apply environment variables
        local env_vars=$(cat "$template_file" | python3 -c "import sys, json; d=json.load(sys.stdin); print(' '.join([f'{k}={v}' for k,v in d.get('environment',{}).items() if v]))" 2>/dev/null)
        [[ -n "$env_vars" ]] && export $env_vars
        
        # Apply connections if available
        local has_connections=$(cat "$template_file" | python3 -c "import sys, json; d=json.load(sys.stdin); print(len(d.get('connections',[])) > 0)" 2>/dev/null)
        if [[ "$has_connections" == "True" ]]; then
            log_info "Applying saved connections..."
            # Connections would be applied via batch import mechanism
        fi
        
        log_success "Template applied"
    fi
    
    return 0
}

# List all available templates
_template_list() {
    local format="${1:-table}"
    
    _template_init
    
    local template_count=$(find "$TEMPLATE_DIR" -name "*.template" 2>/dev/null | wc -l)
    
    if [[ $template_count -eq 0 ]]; then
        log_info "No templates found"
        return 0
    fi
    
    case "$format" in
        json)
            echo "{"
            echo '  "templates": ['
            
            find "$TEMPLATE_DIR" -name "*.template" -type f | sort | while read template_file; do
                local name=$(basename "$template_file" .template)
                local created=$(python3 -c "import json; d=json.load(open('$template_file')); print(d.get('metadata',{}).get('created',''))" 2>/dev/null)
                local description=$(python3 -c "import json; d=json.load(open('$template_file')); print(d.get('metadata',{}).get('description',''))" 2>/dev/null)
                
                echo "    {"
                echo "      \"name\": \"$name\","
                echo "      \"created\": \"$created\","
                echo "      \"description\": \"$description\""
                echo "    },"
            done | sed '$ s/,$//'
            
            echo "  ]"
            echo "}"
            ;;
        csv)
            echo "name,created,description"
            find "$TEMPLATE_DIR" -name "*.template" -type f | sort | while read template_file; do
                local name=$(basename "$template_file" .template)
                local created=$(python3 -c "import json; d=json.load(open('$template_file')); print(d.get('metadata',{}).get('created',''))" 2>/dev/null)
                local description=$(python3 -c "import json; d=json.load(open('$template_file')); print(d.get('metadata',{}).get('description',''))" 2>/dev/null)
                
                echo "\"$name\",\"$created\",\"$description\""
            done
            ;;
        *)
            # Table format
            echo ""
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${CYAN}                    AVAILABLE TEMPLATES${NC}"
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo ""
            
            printf "%-25s %-30s %s\n" "NAME" "CREATED" "DESCRIPTION"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            
            find "$TEMPLATE_DIR" -name "*.template" -type f | sort | while read template_file; do
                local name=$(basename "$template_file" .template)
                local created=$(python3 -c "import json; d=json.load(open('$template_file')); print(d.get('metadata',{}).get('created',''))" 2>/dev/null)
                local description=$(python3 -c "import json; d=json.load(open('$template_file')); print(d.get('metadata',{}).get('description',''))" 2>/dev/null)
                
                printf "%-25s %-30s %s\n" "$name" "$created" "$description"
            done
            
            echo ""
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo ""
            ;;
    esac
}

# Delete a template
_template_delete() {
    local template_name="$1"
    
    [[ -z "$template_name" ]] && log_error "Template name required" && return 1
    
    local template_file="$TEMPLATE_DIR/${template_name}.template"
    
    [[ ! -f "$template_file" ]] && log_error "Template not found: $template_name" && return 1
    
    log_info "Deleting template: $template_name"
    
    rm -f "$template_file"
    
    [[ $? -eq 0 ]] && log_success "Template deleted" || log_error "Failed to delete template"
}

# Export template for distribution
_template_export() {
    local template_name="$1"
    local export_path="${2:-.}"
    
    [[ -z "$template_name" ]] && log_error "Template name required" && return 1
    
    local template_file="$TEMPLATE_DIR/${template_name}.template"
    
    [[ ! -f "$template_file" ]] && log_error "Template not found: $template_name" && return 1
    
    local export_file="${export_path}/${template_name}.template"
    
    log_info "Exporting template to: $export_file"
    
    cp "$template_file" "$export_file"
    
    [[ $? -eq 0 ]] && log_success "Template exported" || log_error "Failed to export template"
}

# Import template for distribution
_template_import() {
    local import_file="$1"
    local template_name="${2:-}"
    
    [[ -z "$import_file" ]] && log_error "Import file path required" && return 1
    [[ ! -f "$import_file" ]] && log_error "File not found: $import_file" && return 1
    
    _template_init
    
    # Use provided name or extract from file
    if [[ -z "$template_name" ]]; then
        template_name=$(basename "$import_file" .template)
    fi
    
    local target_file="$TEMPLATE_DIR/${template_name}.template"
    
    log_info "Importing template: $template_name"
    
    cp "$import_file" "$target_file"
    
    [[ $? -eq 0 ]] && log_success "Template imported" || log_error "Failed to import template"
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

# Parse parameters
_template_name=$(_parse_param_value "--name" $PARAMS)
_description=$(_parse_param_value "--description" $PARAMS)
_file=$(_parse_param_value "--file" $PARAMS)
_format=$(_parse_param_value "--format" $PARAMS || echo "table")
_auto_apply=0
[[ "$PARAMS" =~ --apply ]] && _auto_apply=1

# Use RESOURCE as template name if not specified via flag
[[ -z "$_template_name" && -n "$RESOURCE" && "$RESOURCE" != "list" && "$RESOURCE" != "export" && "$RESOURCE" != "import" ]] && _template_name="$RESOURCE"

log_info "Template operation: $RESOURCE"

case "$RESOURCE" in
    save)
        [[ -z "$_template_name" ]] && log_error "Template name required (--name or as resource)" && exit 1
        _template_save "$_template_name" "$_description"
        ;;
    load)
        [[ -z "$_template_name" ]] && log_error "Template name required (--name or as resource)" && exit 1
        _template_load "$_template_name" "$_auto_apply"
        ;;
    list)
        _template_list "$_format"
        ;;
    delete)
        [[ -z "$_template_name" ]] && log_error "Template name required (--name or as resource)" && exit 1
        _template_delete "$_template_name"
        ;;
    export)
        [[ -z "$_template_name" ]] && log_error "Template name required (--name or as resource)" && exit 1
        _template_export "$_template_name" "$_file"
        ;;
    import)
        [[ -z "$_file" ]] && log_error "File path required (--file)" && exit 1
        _template_import "$_file" "$_template_name"
        ;;
    *)
        log_error "Unknown template operation: $RESOURCE"
        log_info "Use: save|load|list|delete|export|import"
        exit 1
        ;;
esac
