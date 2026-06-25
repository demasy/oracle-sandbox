# ─── sandbox diff ─────────────────────────────────────────────────────────────
# Sourced by sandbox.sh — handles: sandbox diff [resource] <file1> <file2> [--format]
# Variables inherited: ACTION, RESOURCE, PARAMS, logging/color functions
# Purpose: Compare two JSON state exports and show differences
# ─────────────────────────────────────────────────────────────────────────────

# ── Helpers ───────────────────────────────────────────────────────────────────

# Parse JSON and extract keys for comparison
_diff_parse_json() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Validate JSON
    if ! jq empty "$file" 2>/dev/null; then
        log_error "Invalid JSON: $file"
        return 1
    fi
    
    cat "$file"
}

# Simple diff display
_diff_display_text() {
    local file1="$1" file2="$2"
    
    echo ""
    echo -e "  ${CYAN}Comparing:${NC}"
    echo -e "    ${YELLOW}File 1:${NC} $file1"
    echo -e "    ${YELLOW}File 2:${NC} $file2"
    echo ""
    
    # Try unified diff if available
    if command -v diff &>/dev/null; then
        diff -u <(jq -S '.' "$file1" 2>/dev/null) <(jq -S '.' "$file2" 2>/dev/null) | \
            sed "s/^-/${RED}-${NC}/g; s/^+/${GREEN}+${NC}/g; s/^@/${CYAN}@${NC}/g" || true
    else
        log_warn "diff utility not found; showing side-by-side comparison"
        echo "File 1 contents:"
        cat "$file1"
        echo ""
        echo "File 2 contents:"
        cat "$file2"
    fi
    echo ""
}

# JSON diff with structured output
_diff_display_json() {
    local file1="$1" file2="$2"
    
    cat <<EOF
{
  "comparison": {
    "file1": "$(basename "$file1")",
    "file2": "$(basename "$file2")",
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "file1_data": $(cat "$file1"),
    "file2_data": $(cat "$file2")
  }
}
EOF
}

# ── Main dispatch ─────────────────────────────────────────────────────────────

case "$RESOURCE" in
    state|config|connections)
        # Parse parameters: sandbox diff state file1 file2 [--format json|text]
        _format="text"
        _file1=""
        _file2=""
        
        set -- $PARAMS
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --format)
                    [[ -z "${2:-}" ]] && { log_error "--format requires a value"; exit 1; }
                    _format="$2"; shift 2 ;;
                *)
                    if [[ -z "$_file1" ]]; then
                        _file1="$1"
                    elif [[ -z "$_file2" ]]; then
                        _file2="$1"
                    else
                        log_error "Unexpected argument: $1"
                        exit 1
                    fi
                    shift ;;
            esac
        done
        
        # Validate files provided
        if [[ -z "$_file1" ]] || [[ -z "$_file2" ]]; then
            log_error "sandbox diff $RESOURCE requires two files"
            echo ""
            echo -e "  ${YELLOW}Usage:${NC}"
            echo -e "    sandbox diff $RESOURCE <file1> <file2> [--format json|text]"
            echo ""
            echo -e "  ${YELLOW}Examples:${NC}"
            echo -e "    sandbox diff state before.json after.json"
            echo -e "    sandbox diff state before.json after.json --format json"
            echo ""
            exit 1
        fi
        
        # Validate files exist
        _diff_parse_json "$_file1" >/dev/null || exit 1
        _diff_parse_json "$_file2" >/dev/null || exit 1
        
        # Display diff in requested format
        case "$_format" in
            json)
                log_info "Comparing $RESOURCE as JSON"
                _diff_display_json "$_file1" "$_file2" ;;
            text|*)
                log_info "Comparing $RESOURCE"
                _diff_display_text "$_file1" "$_file2" ;;
        esac
        ;;
    *)
        log_error "Unknown diff resource: $RESOURCE"
        echo ""
        echo -e "  ${YELLOW}Available resources:${NC}"
        echo -e "    ${CYAN}state${NC}       Compare sandbox state exports"
        echo -e "    ${CYAN}config${NC}      Compare configuration exports"
        echo -e "    ${CYAN}connections${NC} Compare connection exports"
        echo ""
        exit 1
        ;;
esac
