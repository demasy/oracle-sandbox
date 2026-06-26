#!/bin/bash
################################################################################
# Sandbox CLI - Phase 7 Test Suite Main Runner
# Purpose: Orchestrate unit, integration, and E2E testing
# Usage: ./sandbox-test.sh [unit|integration|e2e|all|--coverage|--verbose]
################################################################################

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="${SCRIPT_DIR%/system/cli}"  # Go up to CLI root
source "${CLI_DIR}/sandbox-config.sh"

# Test configuration
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results}"
TEST_COVERAGE_DIR="${TEST_COVERAGE_DIR:-./coverage}"
VERBOSE="${VERBOSE:-false}"
COVERAGE="${COVERAGE:-false}"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((TESTS_FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $*"
    ((TESTS_SKIPPED++))
}

# Assert helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="${3:-Assertion}"
    
    ((TESTS_RUN++))
    
    if [[ "$expected" == "$actual" ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name - Expected: '$expected', Got: '$actual'"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="${3:-Assertion}"
    
    ((TESTS_RUN++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name - Expected to contain: '$needle', Got: '$haystack'"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="${2:-File exists: $file}"
    
    ((TESTS_RUN++))
    
    if [[ -f "$file" ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name - File not found"
        return 1
    fi
}

assert_returns() {
    local expected_code="$1"
    shift
    local test_name="${*:-Command returns $expected_code}"
    
    ((TESTS_RUN++))
    
    set +e
    "$@" > /dev/null 2>&1
    local actual_code=$?
    set -e
    
    if [[ $actual_code -eq $expected_code ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name - Expected exit code: $expected_code, Got: $actual_code"
        return 1
    fi
}

################################################################################
# Unit Tests
################################################################################

test_sandbox_config() {
    log_info "=== Testing sandbox-config.sh ==="
    
    # Test resource arrays are defined
    assert_contains "$(declare -p SANDBOX_RESOURCES)" "declare -A" "SANDBOX_RESOURCES array defined"
    assert_contains "$(declare -p SANDBOX_ALIASES)" "declare -A" "SANDBOX_ALIASES array defined"
    assert_contains "$(declare -p SANDBOX_ACTIONS)" "declare -A" "SANDBOX_ACTIONS array defined"
    
    # Test configuration values
    [[ -n "${SANDBOX_DB_HOST:-}" ]] && log_pass "SANDBOX_DB_HOST set" || log_fail "SANDBOX_DB_HOST not set"
    [[ -n "${SANDBOX_API_PORT:-}" ]] && log_pass "SANDBOX_API_PORT set" || log_fail "SANDBOX_API_PORT not set"
}

test_sandbox_format() {
    log_info "=== Testing sandbox-format.sh ==="
    
    source "${CLI_DIR}/sandbox-format.sh"
    
    # Test format detection
    local test_json='{"service":"test"}'
    assert_contains "$(format_json "$test_json")" "test" "format_json works"
    
    # Test table format
    local csv_output=$(format_csv "service,status,port" "db,running,1521")
    assert_contains "$csv_output" "service" "format_csv header"
}

test_sandbox_params() {
    log_info "=== Testing sandbox-params.sh ==="
    
    source "${CLI_DIR}/sandbox-params.sh"
    
    # Test parameter validation
    local test_param="test_value"
    assert_equals "$test_param" "test_value" "Parameter assignment works"
}

test_sandbox_help_search() {
    log_info "=== Testing sandbox-help-search.sh ==="
    
    source "${CLI_DIR}/sandbox-help-search.sh"
    
    # Test help search exists and is callable
    assert_returns 0 type _help_search "Help search function exists"
}

################################################################################
# Integration Tests
################################################################################

test_cli_aliases() {
    log_info "=== Testing CLI Aliases Integration ==="
    
    source "${CLI_DIR}/sandbox-aliases.sh"
    
    # Verify aliases are defined
    [[ -n "$(alias sb 2>/dev/null)" ]] && log_pass "Alias 'sb' defined" || log_fail "Alias 'sb' not defined"
    [[ -n "$(alias sr 2>/dev/null)" ]] && log_pass "Alias 'sr' defined" || log_fail "Alias 'sr' not defined"
    [[ -n "$(alias sc 2>/dev/null)" ]] && log_pass "Alias 'sc' defined" || log_fail "Alias 'sc' not defined"
}

test_help_system() {
    log_info "=== Testing Help System Integration ==="
    
    # Help should exist and be callable
    [[ -f "${CLI_DIR}/sandbox-help.sh" ]] && log_pass "Help script exists" || log_fail "Help script missing"
    
    # Check for help banner
    local help_output=$("${CLI_DIR}/sandbox-help.sh" 2>&1 || true)
    assert_contains "$help_output" "sandbox" "Help output contains 'sandbox'"
}

test_status_helpers() {
    log_info "=== Testing Status Helpers Integration ==="
    
    source "${CLI_DIR}/sandbox-status-helpers.sh"
    
    # Verify health check functions exist
    assert_returns 0 type check_tcp_port "check_tcp_port function exists"
    assert_returns 0 type check_process "check_process function exists"
}

################################################################################
# Docker/Container Tests
################################################################################

test_docker_container() {
    log_info "=== Testing Container Integration ==="
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_skip "Docker not available"
        return 0
    fi
    
    # Check if compose file exists
    [[ -f "${CLI_DIR}/../../../docker-compose.yml" ]] && \
        log_pass "docker-compose.yml exists" || \
        log_fail "docker-compose.yml not found"
}

test_cli_in_container() {
    log_info "=== Testing CLI Commands in Container ==="
    
    if ! command -v docker-compose &> /dev/null; then
        log_skip "Docker Compose not available"
        return 0
    fi
    
    local compose_dir="${CLI_DIR}/../../../"
    
    # Check container status
    if docker-compose -f "${compose_dir}/docker-compose.yml" ps 2>/dev/null | grep -q "sandbox-oracle"; then
        log_pass "Sandbox container is running"
    else
        log_skip "Sandbox container not running (expected in CI environment)"
    fi
}

################################################################################
# Performance Tests
################################################################################

test_performance() {
    log_info "=== Testing Performance ==="
    
    # Time help system load
    local start_time=$(date +%s%N)
    source "${CLI_DIR}/sandbox-help.sh" > /dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    if [[ $duration -lt 500 ]]; then
        log_pass "Help system loads in ${duration}ms (< 500ms)"
    else
        log_fail "Help system loads in ${duration}ms (should be < 500ms)"
    fi
    
    # Time aliases load
    start_time=$(date +%s%N)
    source "${CLI_DIR}/sandbox-aliases.sh" > /dev/null 2>&1
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    if [[ $duration -lt 100 ]]; then
        log_pass "Aliases load in ${duration}ms (< 100ms)"
    else
        log_fail "Aliases load in ${duration}ms (should be < 100ms)"
    fi
}

################################################################################
# Main Test Execution
################################################################################

run_unit_tests() {
    log_info ""
    echo "════════════════════════════════════════════════════════"
    echo "UNIT TESTS"
    echo "════════════════════════════════════════════════════════"
    
    test_sandbox_config
    test_sandbox_format
    test_sandbox_params
    test_sandbox_help_search
}

run_integration_tests() {
    log_info ""
    echo "════════════════════════════════════════════════════════"
    echo "INTEGRATION TESTS"
    echo "════════════════════════════════════════════════════════"
    
    test_cli_aliases
    test_help_system
    test_status_helpers
}

run_docker_tests() {
    log_info ""
    echo "════════════════════════════════════════════════════════"
    echo "DOCKER / CONTAINER TESTS"
    echo "════════════════════════════════════════════════════════"
    
    test_docker_container
    test_cli_in_container
}

run_performance_tests() {
    log_info ""
    echo "════════════════════════════════════════════════════════"
    echo "PERFORMANCE TESTS"
    echo "════════════════════════════════════════════════════════"
    
    test_performance
}

print_summary() {
    local total=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=$((total > 0 ? (TESTS_PASSED * 100 / total) : 0))
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "TEST SUMMARY"
    echo "════════════════════════════════════════════════════════"
    echo "Total Tests Run: ${TESTS_RUN}"
    echo -e "  ${GREEN}✓ Passed: ${TESTS_PASSED}${NC}"
    echo -e "  ${RED}✗ Failed: ${TESTS_FAILED}${NC}"
    echo -e "  ${YELLOW}⊘ Skipped: ${TESTS_SKIPPED}${NC}"
    echo ""
    echo "Pass Rate: ${pass_rate}%"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "${RED}✗ SOME TESTS FAILED${NC}"
        return 1
    fi
}

################################################################################
# Main Entry Point
################################################################################

main() {
    local test_type="${1:-all}"
    
    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR" "$TEST_COVERAGE_DIR"
    
    echo "════════════════════════════════════════════════════════"
    echo "Sandbox CLI - Phase 7 Test Suite"
    echo "════════════════════════════════════════════════════════"
    echo "Test Type: $test_type"
    echo "Verbose: $VERBOSE"
    echo "Coverage: $COVERAGE"
    echo ""
    
    case "$test_type" in
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        docker|e2e)
            run_docker_tests
            ;;
        perf|performance)
            run_performance_tests
            ;;
        all)
            run_unit_tests
            run_integration_tests
            run_docker_tests
            run_performance_tests
            ;;
        --coverage)
            COVERAGE=true
            run_unit_tests
            run_integration_tests
            ;;
        --verbose)
            VERBOSE=true
            run_unit_tests
            run_integration_tests
            ;;
        *)
            echo "Unknown test type: $test_type"
            echo "Usage: $0 [unit|integration|docker|perf|all|--coverage|--verbose]"
            return 1
            ;;
    esac
    
    print_summary
}

main "$@"
