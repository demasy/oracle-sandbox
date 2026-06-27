# ─── sandbox parameter parsing library ────────────────────────────────────────
# Reusable functions for parsing CLI parameters and displaying help
# Sourced by action scripts (sandbox-start.sh, sandbox-install.sh, etc.)
# ─────────────────────────────────────────────────────────────────────────────

# Parse a flag that requires a value (e.g., --name <value> or -n <value>)
# Usage: _parse_flag_with_value "<flag>" "<value>" "VARIABLE_NAME" ["optional"]
# Sets: ${VARIABLE_NAME}="<value>", returns 0 on success, 1 if missing required value
# Note: <flag> is only used for error messages; <value> is what gets stored
_parse_flag_with_value() {
    local flag="$1"
    local value="$2"
    local var_name="$3"
    local optional="$4"
    
    # If value is empty/missing
    if [[ -z "$value" ]]; then
        # If this is an optional parameter, allow it
        if [[ "$optional" == "optional" ]]; then
            printf -v "$var_name" '%s' ""
            return 0
        fi
        # Otherwise fail - required parameter missing
        log_error "Flag '${flag}' requires a value"
        return 1
    fi

    # Store the value in the variable
    printf -v "$var_name" '%s' "$value"
    return 0
}

# Parse a standalone flag (no value required, e.g., -d or --default)
# Usage: parse_flag_standalone "current_flag" "short_flag" "long_flag" "param_name"
# Returns: Sets ${param_name}_FLAG to "true", returns 0 if matched
_parse_flag_standalone() {
    local current_flag="$1"
    local short_flag="$2"
    local long_flag="$3"
    local param_name="$4"
    
    if [[ "$current_flag" == "$short_flag" || "$current_flag" == "$long_flag" ]]; then
        printf -v "${param_name}_FLAG" '%s' "true"
        return 0
    fi
    return 1
}

# Validate that a required parameter was provided
# Usage: _require_param_flag "VARIABLE_NAME" "--flag-name" "command_context"
# Returns: 0 if value exists, 1 if missing (logs error)
_require_param_flag() {
    local value="$1"
    local flag_name="$2"
    local context="$3"
    
    if [[ -z "$value" ]]; then
        log_error "Missing required parameter: ${flag_name}"
        echo -e "  ${YELLOW}Usage:${NC} ${CYAN}${context} ${flag_name} <value>${NC}"
        return 1
    fi
    return 0
}

# Display parameter help in consistent format
# Usage: _show_param_help "<flag_spec>" "<value_spec>" "<description>"
# Example: _show_param_help "--name|-n" "<name>" "Connection name"
_show_param_help() {
    local flag_spec="$1"
    local value_spec="$2"
    local desc="$3"
    
    printf "    ${CYAN}%-20s${NC} ${CYAN}%-15s${NC} %-45s\n" "$flag_spec" "$value_spec" "$desc"
}

# Check if dry-run mode is enabled and log appropriate message
# Usage: if_dry_run "command_description" "actual_command"
# Returns: 0 if dry-run (log and return), 1 if should execute
_if_dry_run() {
    local cmd_desc="$1"
    local actual_cmd="$2"
    
    if [[ "${SANDBOX_DRY_RUN:-0}" == "1" ]]; then
        log_info "[dry-run] Would run: $actual_cmd"
        return 0  # Executed (dry-run)
    fi
    return 1  # Should execute normally
}

# Get parameter value from environment or set default
# Usage: get_param "PARAM_NAME" "default_value"
_get_param() {
    local param_name="$1"
    local default_value="$2"
    local param_value="${!param_name}"

    if [[ -z "$param_value" ]]; then
        echo "$default_value"
    else
        echo "$param_value"
    fi
}

# Build a case statement for parameter parsing
# Extracts all positional arguments into an associative array
# Usage: _parse_params "connection" "verbose" < into array PARSED_PARAMS
_parse_simple_params() {
    local -n params_array=$1
    shift
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--conn|--connection)
                params_array[connection]="${2:-}"
                shift 2
                ;;
            -d|--default)
                params_array[default]="true"
                shift
                ;;
            -v|--verbose)
                params_array[verbose]="true"
                shift
                ;;
            -q|--quiet)
                params_array[quiet]="true"
                shift
                ;;
            *)
                params_array[unknown]="${params_array[unknown]:-} $1"
                shift
                ;;
        esac
    done
}

# Display standard parameter error with suggestions
# Usage: _show_param_error "action_name" "resource_name" "param_name"
_show_param_error() {
    local action="$1"
    local resource="$2"
    local param_name="$3"
    
    echo ""
    log_error "Unknown parameter '${param_name}' for sandbox $action $resource"
    echo ""
}

# Parse --format flag for output formatting
# Usage: _parse_output_format $PARAMS
# Sets: OUTPUT_FORMAT="json|csv|table" (defaults to "table")
_parse_output_format() {
    OUTPUT_FORMAT="table"  # Default
    
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--format" || "$1" == "-f" || "$1" == "--export" ]]; then
            if [[ -z "${2:-}" ]]; then
                log_error "--format/--export requires a format (json|csv|table)"
                return 1
            fi
            case "${2}" in
                json|csv|table)
                    OUTPUT_FORMAT="${2}"
                    ;;
                *)
                    log_error "Unknown format: ${2} (use json|csv|table)"
                    return 1
                    ;;
            esac
            return 0
        fi
        shift
    done
    return 0
}

# Parse a single flag value from PARAMS string
# Usage: _parse_param_value "--name" $PARAMS
# Returns: The value after the flag, or empty string if not found
_parse_param_value() {
    local flag="$1"
    shift  # Remove flag from args, rest is PARAMS
    
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "$flag" ]]; then
            echo "${2:-}"
            return 0
        fi
        shift
    done
    return 1
}

# Validate output format is set correctly
# Usage: _require_format_flag
_require_format_flag() {
    if [[ -z "${OUTPUT_FORMAT:-}" ]]; then
        OUTPUT_FORMAT="table"
    fi
    
    case "$OUTPUT_FORMAT" in
        json|csv|table)
            return 0
            ;;
        *)
            log_error "Invalid output format: $OUTPUT_FORMAT"
            return 1
            ;;
    esac
}

# Show format options in help text
# Usage: _show_format_help
_show_format_help() {
    echo -e "  ${YELLOW}Output Formats:${NC}"
    _show_param_help "-f" "--format json" "Output as JSON (machine-readable)"
    _show_param_help "" "--format csv" "Output as CSV (spreadsheet-compatible)"
    _show_param_help "" "--format table" "Output as table (human-readable, default)"
}

# Validate a connection name: only [a-zA-Z0-9_-], max 64 chars
# Usage: _validate_conn_name "$NAME" "--name"
_validate_conn_name() {
    local value="$1"
    local flag="${2:---name}"
    if [[ -z "$value" ]]; then
        log_error "${flag} value cannot be empty"
        return 1
    fi
    if [[ ${#value} -gt 64 ]]; then
        log_error "${flag} value too long (max 64 chars): '${value}'"
        return 1
    fi
    if [[ ! "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "${flag} contains invalid characters: '${value}'"
        echo -e "  ${YELLOW}Allowed:${NC} letters, digits, hyphens, underscores only"
        return 1
    fi
    return 0
}
