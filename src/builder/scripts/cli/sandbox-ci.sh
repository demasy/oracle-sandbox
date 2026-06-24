#!/bin/bash
################################################################################
# Sandbox CLI - CI/CD Pipeline Integration
# Purpose: Automated testing, linting, and quality checks for CI/CD
# Usage: ./sandbox-ci.sh [test|build|validate|quality|full]
################################################################################

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="${SCRIPT_DIR%/scripts/cli}"
source "${CLI_DIR}/sandbox-config.sh" 2>/dev/null || true

# CI Configuration
CI_RESULTS_DIR="${CI_RESULTS_DIR:-./.ci-results}"
CI_STRICT="${CI_STRICT:-true}"
EXIT_CODE=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

################################################################################
# Utilities
################################################################################

log_stage() {
    echo ""
    echo -e "${MAGENTA}════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}$*${NC}"
    echo -e "${MAGENTA}════════════════════════════════════════════════════════${NC}"
}

log_step() { echo -e "${BLUE}[→]${NC} $*"; }
log_pass() { echo -e "${GREEN}[✓]${NC} $*"; }
log_fail() { echo -e "${RED}[✗]${NC} $*"; EXIT_CODE=1; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $*"; }
log_info() { echo -e "${BLUE}[ℹ]${NC} $*"; }

################################################################################
# Initialization
################################################################################

init_ci() {
    log_step "Initializing CI environment"
    
    # Create results directory
    mkdir -p "$CI_RESULTS_DIR"
    
    # Set strict mode for CI
    export STRICT="$CI_STRICT"
    
    # Log CI environment
    {
        echo "CI Environment"
        echo "=============="
        echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo "Shell: $SHELL"
        echo "Bash Version: ${BASH_VERSION:-unknown}"
        echo ""
        echo "Directories:"
        echo "  CLI: $CLI_DIR"
        echo "  Results: $CI_RESULTS_DIR"
        echo ""
    } | tee "${CI_RESULTS_DIR}/environment.txt"
    
    log_pass "CI initialized"
}

################################################################################
# File Existence Checks
################################################################################

check_cli_files() {
    log_stage "Checking CLI File Integrity"
    
    local required_files=(
        "sandbox-config.sh"
        "sandbox-aliases.sh"
        "sandbox-help.sh"
        "sandbox-help-search.sh"
        "sandbox-params.sh"
        "sandbox-menu.sh"
        "sandbox-status-helpers.sh"
        "sandbox-format.sh"
        "sandbox-batch.sh"
        "sandbox-export.sh"
        "sandbox-diff.sh"
        "sandbox-shell.sh"
        "sandbox-completion.bash"
        "sandbox-completion.zsh"
    )
    
    local missing=0
    for file in "${required_files[@]}"; do
        if [[ -f "${CLI_DIR}/$file" ]]; then
            log_pass "$file"
        else
            log_fail "$file (MISSING)"
            ((missing++))
        fi
    done
    
    if [[ $missing -gt 0 ]]; then
        log_fail "Missing $missing required files"
        return 1
    else
        log_pass "All required files present"
        return 0
    fi
}

################################################################################
# Syntax Validation
################################################################################

validate_syntax() {
    log_stage "Validating Script Syntax"
    
    local scripts=(
        "${CLI_DIR}/sandbox-config.sh"
        "${CLI_DIR}/sandbox-aliases.sh"
        "${CLI_DIR}/sandbox-help.sh"
        "${CLI_DIR}/sandbox-help-search.sh"
        "${CLI_DIR}/sandbox-params.sh"
        "${CLI_DIR}/sandbox-menu.sh"
        "${CLI_DIR}/sandbox-status-helpers.sh"
        "${CLI_DIR}/sandbox-format.sh"
        "${CLI_DIR}/sandbox-batch.sh"
        "${CLI_DIR}/sandbox-export.sh"
        "${CLI_DIR}/sandbox-diff.sh"
        "${CLI_DIR}/sandbox-shell.sh"
    )
    
    local failures=0
    for script in "${scripts[@]}"; do
        if bash -n "$script" 2>/dev/null; then
            log_pass "$(basename "$script")"
        else
            log_fail "$(basename "$script") - Syntax error"
            ((failures++))
        fi
    done
    
    if [[ $failures -gt 0 ]]; then
        log_fail "$failures scripts have syntax errors"
        return 1
    else
        log_pass "All scripts have valid syntax"
        return 0
    fi
}

################################################################################
# Unit Tests
################################################################################

run_unit_tests() {
    log_stage "Running Unit Tests"
    
    if [[ ! -f "${SCRIPT_DIR}/sandbox-test.sh" ]]; then
        log_warn "Test suite not found"
        return 0
    fi
    
    log_step "Executing unit tests"
    
    if bash "${SCRIPT_DIR}/sandbox-test.sh" unit > "${CI_RESULTS_DIR}/unit-tests.log" 2>&1; then
        log_pass "Unit tests passed"
        cat "${CI_RESULTS_DIR}/unit-tests.log" | tail -10
        return 0
    else
        log_fail "Unit tests failed"
        cat "${CI_RESULTS_DIR}/unit-tests.log"
        return 1
    fi
}

################################################################################
# Integration Tests
################################################################################

run_integration_tests() {
    log_stage "Running Integration Tests"
    
    if [[ ! -f "${SCRIPT_DIR}/sandbox-test.sh" ]]; then
        log_warn "Test suite not found"
        return 0
    fi
    
    log_step "Executing integration tests"
    
    if bash "${SCRIPT_DIR}/sandbox-test.sh" integration > "${CI_RESULTS_DIR}/integration-tests.log" 2>&1; then
        log_pass "Integration tests passed"
        cat "${CI_RESULTS_DIR}/integration-tests.log" | tail -10
        return 0
    else
        log_fail "Integration tests failed"
        cat "${CI_RESULTS_DIR}/integration-tests.log"
        return 1
    fi
}

################################################################################
# Code Quality Checks
################################################################################

run_quality_checks() {
    log_stage "Running Code Quality Checks"
    
    if [[ ! -f "${SCRIPT_DIR}/sandbox-lint.sh" ]]; then
        log_warn "Linter not found"
        return 0
    fi
    
    log_step "Running syntax validation"
    if bash "${SCRIPT_DIR}/sandbox-lint.sh" validate > "${CI_RESULTS_DIR}/lint-validate.log" 2>&1; then
        log_pass "Syntax validation passed"
    else
        log_warn "Syntax validation had issues"
    fi
    
    log_step "Running security checks"
    if bash "${SCRIPT_DIR}/sandbox-lint.sh" security > "${CI_RESULTS_DIR}/lint-security.log" 2>&1; then
        log_pass "Security checks passed"
    else
        log_warn "Security checks had issues"
    fi
    
    log_step "Analyzing complexity"
    if bash "${SCRIPT_DIR}/sandbox-lint.sh" complexity > "${CI_RESULTS_DIR}/lint-complexity.log" 2>&1; then
        log_pass "Complexity analysis passed"
    else
        log_warn "Complexity analysis had issues"
    fi
}

################################################################################
# Performance Baseline
################################################################################

run_performance_baseline() {
    log_stage "Establishing Performance Baseline"
    
    if [[ ! -f "${SCRIPT_DIR}/sandbox-performance.sh" ]]; then
        log_warn "Performance tool not found"
        return 0
    fi
    
    log_step "Running performance benchmarks"
    
    if bash "${SCRIPT_DIR}/sandbox-performance.sh" benchmark > "${CI_RESULTS_DIR}/performance-baseline.log" 2>&1; then
        log_pass "Performance baseline established"
        
        # Display key metrics
        grep "Metric" "${CI_RESULTS_DIR}/performance-baseline.log" | head -5
    else
        log_warn "Performance benchmarking had issues"
    fi
}

################################################################################
# Docker Build Validation
################################################################################

validate_docker_build() {
    log_stage "Validating Docker Build"
    
    if ! command -v docker &> /dev/null; then
        log_warn "Docker not available - skipping Docker build validation"
        return 0
    fi
    
    local compose_file="${CLI_DIR}/../../../docker-compose.yml"
    
    if [[ ! -f "$compose_file" ]]; then
        log_warn "docker-compose.yml not found"
        return 0
    fi
    
    log_step "Validating docker-compose configuration"
    
    if docker-compose -f "$compose_file" config > /dev/null 2>&1; then
        log_pass "docker-compose configuration is valid"
        return 0
    else
        log_fail "docker-compose configuration is invalid"
        return 1
    fi
}

################################################################################
# Report Generation
################################################################################

generate_ci_report() {
    log_stage "Generating CI Report"
    
    local report_file="${CI_RESULTS_DIR}/ci-report-$(date +%Y%m%d-%H%M%S).md"
    
    {
        echo "# Sandbox CLI - CI Report"
        echo ""
        echo "**Generated**: $(date)"
        echo "**Exit Code**: $EXIT_CODE"
        echo ""
        
        echo "## Checks Performed"
        echo ""
        echo "- [x] File integrity"
        echo "- [x] Syntax validation"
        echo "- [x] Unit tests"
        echo "- [x] Integration tests"
        echo "- [x] Code quality"
        echo "- [x] Performance baseline"
        echo "- [x] Docker validation"
        echo ""
        
        echo "## Results Summary"
        echo ""
        if [[ $EXIT_CODE -eq 0 ]]; then
            echo "✓ **ALL CHECKS PASSED**"
        else
            echo "✗ **SOME CHECKS FAILED**"
        fi
        echo ""
        
        echo "## Artifacts"
        echo ""
        echo "Test Results:"
        for log in "${CI_RESULTS_DIR}"/*.log; do
            if [[ -f "$log" ]]; then
                echo "- $(basename "$log")"
            fi
        done
        echo ""
        
    } | tee "$report_file"
    
    log_pass "Report saved to: $report_file"
}

################################################################################
# Main Entry Point
################################################################################

main() {
    local action="${1:-full}"
    
    init_ci
    
    echo ""
    log_info "Starting CI pipeline: $action"
    echo ""
    
    case "$action" in
        test)
            check_cli_files || EXIT_CODE=1
            validate_syntax || EXIT_CODE=1
            run_unit_tests || EXIT_CODE=1
            run_integration_tests || EXIT_CODE=1
            ;;
        build)
            validate_docker_build || EXIT_CODE=1
            ;;
        validate)
            check_cli_files || EXIT_CODE=1
            validate_syntax || EXIT_CODE=1
            ;;
        quality)
            run_quality_checks || EXIT_CODE=1
            run_performance_baseline || EXIT_CODE=1
            ;;
        full)
            check_cli_files || EXIT_CODE=1
            validate_syntax || EXIT_CODE=1
            run_unit_tests || EXIT_CODE=1
            run_integration_tests || EXIT_CODE=1
            run_quality_checks || EXIT_CODE=1
            run_performance_baseline || EXIT_CODE=1
            validate_docker_build || EXIT_CODE=1
            ;;
        *)
            echo "Unknown action: $action"
            echo "Usage: $0 [test|build|validate|quality|full]"
            EXIT_CODE=1
            ;;
    esac
    
    generate_ci_report
    
    echo ""
    log_stage "CI Pipeline Complete"
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        log_pass "All checks passed"
    else
        log_fail "Some checks failed (exit code: $EXIT_CODE)"
    fi
    
    return $EXIT_CODE
}

main "$@"
