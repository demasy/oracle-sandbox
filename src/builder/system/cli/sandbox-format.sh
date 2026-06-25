# ─── sandbox output formatting library ────────────────────────────────────────
# Reusable functions for structured output in JSON, CSV, and table formats
# Sourced by action scripts that need formatted output
# Usage: Declare associative array, call _format_output "json"|"csv"|"table"
# ─────────────────────────────────────────────────────────────────────────────

# Format a key-value associative array as JSON
# Usage: declare -A data; data[key]="value"; _format_json data
_format_json() {
    local -n array_ref=$1
    local first=true
    
    printf "{\n"
    for key in "${!array_ref[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            printf ",\n"
        fi
        # Escape special JSON characters
        local value="${array_ref[$key]}"
        value="${value//\\/\\\\}"  # Escape backslashes
        value="${value//\"/\\\"}"  # Escape quotes
        value="${value//$'\n'/\\n}"  # Escape newlines
        printf "  \"$key\": \"$value\""
    done
    printf "\n}\n"
}

# Format a key-value associative array as CSV
# Usage: declare -A data; data[key]="value"; _format_csv data
_format_csv() {
    local -n array_ref=$1
    local first=true
    
    for key in "${!array_ref[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            printf ","
        fi
        # Escape CSV special characters (quote if contains comma/quote/newline)
        local value="${array_ref[$key]}"
        if [[ "$value" =~ [,\"\$] || "$value" == *$'\n'* ]]; then
            value="${value//\"/\"\"}"  # Escape quotes
            printf "\"%s\"" "$value"
        else
            printf "%s" "$value"
        fi
    done
    printf "\n"
}

# Format a key-value associative array as table
# Usage: declare -A data; data[key]="value"; _format_table data
_format_table() {
    local -n array_ref=$1
    local max_key_len=0
    
    # Find max key length for alignment
    for key in "${!array_ref[@]}"; do
        local len=${#key}
        if ((len > max_key_len)); then
            max_key_len=$len
        fi
    done
    
    # Add padding
    ((max_key_len += 2))
    
    # Output table
    for key in "${!array_ref[@]}"; do
        printf "%-${max_key_len}s: %s\n" "$key" "${array_ref[$key]}"
    done
}

# Format a list as JSON array
# Usage: _format_json_list "item1" "item2" "item3"
_format_json_list() {
    printf "[\n"
    local first=true
    for item in "$@"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            printf ",\n"
        fi
        # Escape special JSON characters
        local value="$item"
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        value="${value//$'\n'/\\n}"
        printf "  \"%s\"" "$value"
    done
    printf "\n]\n"
}

# Format a list as CSV
# Usage: _format_csv_list "item1" "item2" "item3"
_format_csv_list() {
    local first=true
    for item in "$@"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            printf ","
        fi
        # Escape CSV special characters
        local value="$item"
        if [[ "$value" =~ [,\"\$] || "$value" == *$'\n'* ]]; then
            value="${value//\"/\"\"}"
            printf "\"%s\"" "$value"
        else
            printf "%s" "$value"
        fi
    done
    printf "\n"
}

# Format a list as table
# Usage: _format_table_list "item1" "item2" "item3"
_format_table_list() {
    printf "  Items:\n"
    for item in "$@"; do
        printf "    • %s\n" "$item"
    done
}

# Format a simple status message as JSON
# Usage: _format_status_json "database" "ok" "Database is running"
_format_status_json() {
    local component="$1"
    local status="$2"
    local message="$3"
    
    local status_code="0"
    if [[ "$status" == "ok" || "$status" == "OK" ]]; then
        status_code="0"
    elif [[ "$status" == "warn" || "$status" == "WARNING" ]]; then
        status_code="1"
    else
        status_code="2"
    fi
    
    printf "{\n"
    printf "  \"component\": \"%s\",\n" "$component"
    printf "  \"status\": \"%s\",\n" "$status"
    printf "  \"code\": %d,\n" "$status_code"
    printf "  \"message\": \"%s\"\n" "$message"
    printf "}\n"
}

# Format a simple status message as CSV
# Usage: _format_status_csv "database" "ok" "Database is running"
_format_status_csv() {
    local component="$1"
    local status="$2"
    local message="$3"
    
    local status_code="0"
    if [[ "$status" == "ok" || "$status" == "OK" ]]; then
        status_code="0"
    elif [[ "$status" == "warn" || "$status" == "WARNING" ]]; then
        status_code="1"
    else
        status_code="2"
    fi
    
    printf "%s,%s,%d,%s\n" "$component" "$status" "$status_code" "$message"
}

# Format a simple status message as table
# Usage: _format_status_table "database" "ok" "Database is running"
_format_status_table() {
    local component="$1"
    local status="$2"
    local message="$3"
    
    printf "  Component: %s\n" "$component"
    printf "  Status: %s\n" "$status"
    printf "  Message: %s\n" "$message"
}

# Universal formatter: Choose format based on --format flag
# Stores format choice in $OUTPUT_FORMAT variable (default: "table")
# Usage: After parsing flags, $OUTPUT_FORMAT will contain the chosen format
OUTPUT_FORMAT="table"

# Set the output format from --format flag
# Usage: Inside your script, after getting $PARAMS, call: _set_output_format $PARAMS
_set_output_format() {
    local params="$*"
    
    if [[ "$params" =~ --format[[:space:]]+([a-z]+) ]]; then
        local fmt="${BASH_REMATCH[1]}"
        case "$fmt" in
            json|csv|table)
                OUTPUT_FORMAT="$fmt"
                ;;
            *)
                log_warn "Unknown format: $fmt (using table)"
                OUTPUT_FORMAT="table"
                ;;
        esac
    fi
}
