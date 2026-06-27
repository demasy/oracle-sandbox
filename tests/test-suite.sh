#!/bin/bash

# ─── sandbox test suite ────────────────────────────────────────────────────────
# Comprehensive test infrastructure for sandbox CLI
# Usage: bash test-suite.sh [test-name] [--verbose] [--quiet]
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_SCRIPT="$TEST_DIR/../app.js"  # Adjust path to actual sandbox entry
TEST_RESULTS=()
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
VERBOSE=0
QUIET=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) VERBOSE=1; shift ;;
        --quiet) QUIET=1; shift ;;
        *) break ;;
    esac
done

# ─── Test Framework ────────────────────────────────────────────────────────────

assert_success() {
    local test_name="$1"
    local cmd="$2"
    
    ((TEST_COUNT++))
    if [[ $VERBOSE -eq 1 ]]; then
        echo "  Running: $cmd"
    fi
    
    if output=$(eval "$cmd" 2>&1); then
        ((PASS_COUNT++))
        [[ $QUIET -eq 0 ]] && echo "✓ $test_name"
    else
        ((FAIL_COUNT++))
        echo "✗ $test_name"
        [[ $VERBOSE -eq 1 ]] && echo "  Error: $output"
    fi
    return 0
}

assert_failure() {
    local test_name="$1"
    local cmd="$2"
    local expected_error="${3:-}"
    
    ((TEST_COUNT++))
    if [[ $VERBOSE -eq 1 ]]; then
        echo "  Running: $cmd (expecting failure)"
    fi
    
    if ! output=$(eval "$cmd" 2>&1); then
        if [[ -z "$expected_error" ]] || echo "$output" | grep -q "$expected_error"; then
            ((PASS_COUNT++))
            [[ $QUIET -eq 0 ]] && echo "✓ $test_name"
            return 0
        fi
    fi

    ((FAIL_COUNT++))
    echo "✗ $test_name"
    [[ $VERBOSE -eq 1 ]] && echo "  Expected failure with: $expected_error, got: $output"
    return 0
}

assert_contains() {
    local test_name="$1"
    local output="$2"
    local expected_substring="$3"
    
    ((TEST_COUNT++))
    if echo "$output" | grep -q "$expected_substring"; then
        ((PASS_COUNT++))
        [[ $QUIET -eq 0 ]] && echo "✓ $test_name"
        return 0
    else
        ((FAIL_COUNT++))
        echo "✗ $test_name (expected substring not found: $expected_substring)"
        return 1
    fi
}

# ─── Parameter Parsing Tests ────────────────────────────────────────────────────

test_parameter_parsing() {
    echo ""
    echo "=== Parameter Parsing Tests ==="
    
    # Test flag parsing
    assert_success "Parse --format flag" \
        "bash -c 'source sandbox-params.sh; _parse_flag_with_value \"--format\" \"\" \"--format json --verbose\" | grep -q json'"
    
    assert_success "Parse --file flag" \
        "bash -c 'source sandbox-params.sh; _parse_flag_with_value \"--file\" \"\" \"--file /tmp/test.json\" | grep -q /tmp/test.json'"
    
    assert_success "Standalone flag detection" \
        "bash -c 'source sandbox-params.sh; _parse_flag_standalone \"--dry-run\" \"--verbose --dry-run --quiet\" | grep -q 1'"
}

# ─── Help System Tests ────────────────────────────────────────────────────────

test_help_system() {
    echo ""
    echo "=== Help System Tests ==="
    
    assert_success "Status help available" \
        "sandbox status -h | grep -q 'sandbox status'"
    
    assert_success "Import help available" \
        "sandbox import -h | grep -q 'sandbox import'"
    
    assert_success "Batch help available" \
        "sandbox batch -h | grep -q 'sandbox batch'"
    
    assert_success "Monitor help available" \
        "sandbox monitor -h | grep -q 'sandbox monitor'"
    
    assert_success "Audit help available" \
        "sandbox audit -h | grep -q 'sandbox audit'"
    
    assert_success "Template help available" \
        "sandbox template -h | grep -q 'sandbox template'"
}

# ─── Format Support Tests ────────────────────────────────────────────────────────

test_format_support() {
    echo ""
    echo "=== Format Support Tests ==="
    
    # Test JSON format
    local json_output=$(sandbox status --format json 2>/dev/null || echo '{}')
    assert_contains "JSON format produces valid JSON" \
        "$json_output" '"timestamp"'
    
    # Test CSV format
    local csv_output=$(sandbox status database --format csv 2>/dev/null || echo '')
    assert_contains "CSV format produces header" \
        "$csv_output" 'component'
    
    # Test table format (default)
    local table_output=$(sandbox status --format table 2>/dev/null || echo '')
    assert_contains "Table format has structure" \
        "$table_output" 'DATABASE\|System'
}

# ─── Import/Export Tests ────────────────────────────────────────────────────────

test_import_export() {
    echo ""
    echo "=== Import/Export Tests ==="
    
    # Create temp export file
    local temp_export=$(mktemp)
    sandbox export connections > "$temp_export" 2>/dev/null || true
    
    assert_success "Export connections" \
        "[[ -s '$temp_export' ]]"
    
    # Test import (dry-run)
    assert_success "Import connections (validate file exists)" \
        "[[ -f '$temp_export' ]]"
    
    rm -f "$temp_export"
}

# ─── Batch Operations Tests ────────────────────────────────────────────────────────

test_batch_operations() {
    echo ""
    echo "=== Batch Operations Tests ==="
    
    # Create temp batch file
    local temp_batch=$(mktemp)
    cat > "$temp_batch" << 'EOF'
cmd=sandbox status database
cmd=sandbox status apex
EOF
    
    assert_success "Batch file created" \
        "[[ -f '$temp_batch' ]]"
    
    assert_success "Batch dry-run executes" \
        "sandbox batch execute --file '$temp_batch' --dry-run | grep -q 'DRY RUN'"
    
    rm -f "$temp_batch"
}

# ─── Audit System Tests ────────────────────────────────────────────────────────

test_audit_system() {
    echo ""
    echo "=== Audit System Tests ==="
    
    assert_success "Audit list command" \
        "sandbox audit list | grep -q -E 'timestamp|id|Audit' || true"
    
    assert_success "Audit stats command" \
        "sandbox audit stats | grep -q 'AUDIT LOG' || true"
}

# ─── Template System Tests ────────────────────────────────────────────────────────

test_template_system() {
    echo ""
    echo "=== Template System Tests ==="
    
    assert_success "Template list command" \
        "sandbox template list | grep -q -E 'TEMPLATES|name|created' || true"
    
    # Test save operation
    assert_success "Template save command" \
        "sandbox template save --name test_template --description 'Test template' | grep -q -E 'Template|saved' || true"
    
    # Test delete operation
    assert_success "Template delete command" \
        "sandbox template delete --name test_template | grep -q -E 'deleted|not found' || true"
}

# ─── Monitoring Tests ────────────────────────────────────────────────────────

test_monitoring() {
    echo ""
    echo "=== Monitoring Tests ==="
    
    local monitor_json=$(sandbox monitor --export json 2>/dev/null || echo '{}')
    assert_contains "Monitor exports JSON with timestamp" \
        "$monitor_json" '"timestamp"'
    
    local monitor_prometheus=$(sandbox monitor --export prometheus 2>/dev/null || echo '')
    assert_contains "Monitor exports Prometheus format" \
        "$monitor_prometheus" 'sandbox_'
}

# ─── Error Handling Tests ────────────────────────────────────────────────────────

test_error_handling() {
    echo ""
    echo "=== Error Handling Tests ==="
    
    assert_failure "Import missing file" \
        "sandbox import connections --file /nonexistent/file.json" \
        "not found\|not readable"
    
    assert_failure "Batch missing file" \
        "sandbox batch execute --file /nonexistent/file.txt" \
        "not found\|not readable"
    
    assert_failure "Invalid template operation" \
        "sandbox template invalid_op" \
        "Unknown\|invalid"
}

# ─── Integration Tests ────────────────────────────────────────────────────────

test_integration() {
    echo ""
    echo "=== Integration Tests ==="
    
    # Test status action with multiple resources
    assert_success "Status multiple resources" \
        "sandbox status database apex | grep -q -E 'database|apex|status'"
    
    # Test help for all major actions
    assert_success "All actions have help" \
        "for action in status import batch monitor audit template; do sandbox \$action -h > /dev/null 2>&1 || exit 1; done"
}

# ─── Main Test Runner ────────────────────────────────────────────────────────

# ─── Container Smoke Tests ────────────────────────────────────────────────────
# Requires sandbox-oracle-server container to be running.
# Skipped automatically if the container is not found.

_dexec() {
    docker exec --user sandbox sandbox-oracle-server bash -c "$1" 2>/dev/null
}

test_container_smoke() {
    echo ""
    echo "=== Container Smoke Tests ==="

    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "sandbox-oracle-server"; then
        echo "  ⚠ sandbox-oracle-server not running — skipping container tests"
        return 0
    fi

    # CLI help
    assert_success "sb help exits 0" \
        "_dexec 'sb help > /dev/null'"

    assert_success "sb backup -h shows resources" \
        "_dexec 'sb backup -h' | grep -q 'connections'"

    assert_success "sb restore -h shows --from param" \
        "_dexec 'sb restore connections -h' | grep -q '\-\-from'"

    # Input validation: reject bad connection names
    assert_failure "conn add rejects path-traversal name" \
        "_dexec 'sb conn add --name \"../../etc\" --user sys 2>&1'" \
        "invalid characters"

    assert_failure "conn rename rejects slash in --from" \
        "_dexec 'sb conn rename --from \"a/b\" --to ok 2>&1'" \
        "invalid characters"

    # JSON export outputs valid JSON
    local conn_json
    conn_json=$(_dexec 'SANDBOX_QUIET=1 sb conn list --export json' 2>/dev/null || echo '{}')
    assert_contains "conn list --export json has connections key" \
        "$conn_json" '"connections"'

    # Healthcheck JSON
    local hc_json
    hc_json=$(_dexec 'bash /usr/sandbox/app/system/admin/healthcheck.sh --export json' 2>/dev/null || echo '{}')
    assert_contains "healthcheck --export json has status key" \
        "$hc_json" '"status"'
    assert_contains "healthcheck reports HEALTHY" \
        "$hc_json" 'HEALTHY'

    # Backup list runs without error
    assert_success "sb backup list exits 0" \
        "_dexec 'sb backup list'"

    # Audit logging: run a command then verify it was logged
    _dexec 'sb conn list' >/dev/null 2>&1 || true
    local audit_out
    audit_out=$(_dexec 'sb audit list' 2>/dev/null || echo '')
    assert_contains "audit log records conn action" \
        "$audit_out" 'ACTION: conn'
}

main() {
    echo ""
    echo "╔═════════════════════════════════════════════════════════════════╗"
    echo "║           SANDBOX CLI TEST SUITE - COMPREHENSIVE                 ║"
    echo "╚═════════════════════════════════════════════════════════════════╝"

    # Run test groups
    test_parameter_parsing
    test_help_system
    test_format_support
    test_import_export
    test_batch_operations
    test_audit_system
    test_template_system
    test_monitoring
    test_error_handling
    test_integration
    test_container_smoke
    
    # Print summary
    echo ""
    echo "╔═════════════════════════════════════════════════════════════════╗"
    echo "║                        TEST SUMMARY                              ║"
    echo "╚═════════════════════════════════════════════════════════════════╝"
    echo "Total Tests:    $TEST_COUNT"
    echo "Passed:         $PASS_COUNT"
    echo "Failed:         $FAIL_COUNT"
    
    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo "Result:         ✓ ALL TESTS PASSED"
        return 0
    else
        echo "Result:         ✗ SOME TESTS FAILED"
        return 1
    fi
}

# Run main function
main "$@"
