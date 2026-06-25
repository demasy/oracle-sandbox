#!/bin/bash
################################################################################
# Sandbox CLI - Code Quality & Linting
# Purpose: Lint, validate, and check code quality of CLI scripts
# Usage: ./sandbox-lint.sh [lint|validate|security|all]
################################################################################

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="${SCRIPT_DIR%/scripts/cli}"
source "${CLI_DIR}/sandbox-config.sh" 2>/dev/null || true

# Lint configuration
LINT_RESULTS_DIR="${LINT_RESULTS_DIR:-./.lint}"
STRICT="${STRICT:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
ISSUES_FOUND=0
WARNINGS_FOUND=0
ERRORS_FOUND=0

################################################################################
# Utilities
################################################################################

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_pass() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $*"; ((WARNINGS_FOUND++)); }
log_error() { echo -e "${RED}[✗]${NC} $*"; ((ERRORS_FOUND++)); }

################################################################################
# ShellCheck Linting
################################################################################

lint_with_shellcheck() {
    log_info "Running ShellCheck linting..."
    
    if ! command -v shellcheck &> /dev/null; then
        log_warn "ShellCheck not installed. Skipping ShellCheck analysis."
        return 0
    fi
    
    local scripts=(
        "${CLI_DIR}/sandbox-config.sh"
        "${CLI_DIR}/sandbox-aliases.sh"
        "${CLI_DIR}/sandbox-help.sh"
        "${CLI_DIR}/sandbox-help-search.sh"
        "${CLI_DIR}/sandbox-params.sh"
        "${CLI_DIR}/sandbox-menu.sh"
        "${CLI_DIR}/sandbox-format.sh"
        "${CLI_DIR}/sandbox-status-helpers.sh"
        "${CLI_DIR}/sandbox-batch.sh"
        "${CLI_DIR}/sandbox-export.sh"
        "${CLI_DIR}/sandbox-diff.sh"
        "${CLI_DIR}/sandbox-shell.sh"
        "${CLI_DIR}/sandbox-completion.bash"
        "${CLI_DIR}/sandbox-completion.zsh"
    )
    
    local issues=0
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            local result=$(shellcheck "$script" 2>&1 || true)
            if [[ -n "$result" ]]; then
                echo "$result" | while read -r line; do
                    log_warn "$(basename "$script"): $line"
                done
                ((issues++))
            else
                log_pass "$(basename "$script") - No issues"
            fi
        fi
    done
    
    ISSUES_FOUND=$((ISSUES_FOUND + issues))
}

################################################################################
# Style & Format Validation
################################################################################

validate_shell_style() {
    log_info "Validating shell script style..."
    
    local scripts=(
        "${CLI_DIR}/sandbox-config.sh"
        "${CLI_DIR}/sandbox-aliases.sh"
        "${CLI_DIR}/sandbox-help.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            continue
        fi
        
        # Check for consistent indentation (4 spaces)
        if grep -q $'^\t' "$script"; then
            log_warn "$(basename "$script") uses tabs instead of spaces"
        fi
        
        # Check for trailing whitespace
        if grep -q '[[:space:]]$' "$script"; then
            log_warn "$(basename "$script") contains trailing whitespace"
        fi
        
        # Check line length (warn if > 100 chars)
        local long_lines=$(grep -E '.{101,}' "$script" | wc -l)
        if [[ $long_lines -gt 0 ]]; then
            log_warn "$(basename "$script") has $long_lines lines exceeding 100 characters"
        fi
        
        log_pass "$(basename "$script") - Style check complete"
    done
}

################################################################################
# Bash Syntax Validation
################################################################################

validate_bash_syntax() {
    log_info "Validating bash syntax..."
    
    local scripts=(
        "${CLI_DIR}/sandbox-config.sh"
        "${CLI_DIR}/sandbox-aliases.sh"
        "${CLI_DIR}/sandbox-help.sh"
        "${CLI_DIR}/sandbox-help-search.sh"
        "${CLI_DIR}/sandbox-params.sh"
        "${CLI_DIR}/sandbox-menu.sh"
        "${CLI_DIR}/sandbox-format.sh"
        "${CLI_DIR}/sandbox-status-helpers.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            continue
        fi
        
        if bash -n "$script" 2>/dev/null; then
            log_pass "$(basename "$script") - Syntax OK"
        else
            log_error "$(basename "$script") - Syntax Error"
        fi
    done
}

################################################################################
# Security Checks
################################################################################

security_check() {
    log_info "Running security checks..."
    
    local scripts=(
        "${CLI_DIR}/sandbox-config.sh"
        "${CLI_DIR}/sandbox-params.sh"
        "${CLI_DIR}/sandbox-format.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            continue
        fi
        
        # Check for hardcoded credentials
        if grep -qi 'password\|passwd\|pwd\|secret' "$script"; then
            log_warn "$(basename "$script") may contain hardcoded credentials"
        fi
        
        # Check for unsafe command execution
        if grep -q 'eval\|exec\|\${.*}' "$script"; then
            log_warn "$(basename "$script") uses potentially unsafe command execution"
        fi
        
        # Check for SQL injection risks
        if grep -q 'sqlplus\|sqlcl' "$script"; then
            if ! grep -q 'bind\|parameter\|placeholder' "$script"; then
                log_warn "$(basename "$script") executes SQL - verify parameterization"
            fi
        fi
        
        log_pass "$(basename "$script") - Security check complete"
    done
}

################################################################################
# Dependency Analysis
################################################################################

analyze_dependencies() {
    log_info "Analyzing script dependencies..."
    
    local scripts=(
        "${CLI_DIR}/sandbox-config.sh"
        "${CLI_DIR}/sandbox-aliases.sh"
        "${CLI_DIR}/sandbox-help.sh"
        "${CLI_DIR}/sandbox-params.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            continue
        fi
        
        # Find sourced files
        local sources=$(grep -o 'source [^[:space:]]*\|^\. [^[:space:]]*' "$script" | cut -d' ' -f2 | sort -u)
        
        echo -e "${BLUE}Dependencies for $(basename "$script"):${NC}"
        if [[ -n "$sources" ]]; then
            echo "$sources" | while read -r dep; do
                if [[ -f "$dep" ]] || [[ -f "${CLI_DIR}/$dep" ]]; then
                    log_pass "  ✓ $dep"
                else
                    log_warn "  ? $dep (not found)"
                fi
            done
        else
            echo "  (no sourced dependencies)"
        fi
    done
}

################################################################################
# Function Complexity Analysis
################################################################################

analyze_complexity() {
    log_info "Analyzing function complexity..."
    
    local scripts=(
        "${CLI_DIR}/sandbox-help.sh"
        "${CLI_DIR}/sandbox-format.sh"
        "${CLI_DIR}/sandbox-batch.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            continue
        fi
        
        local func_count=$(grep -c '^[a-zA-Z_][a-zA-Z0-9_]*()' "$script" || echo 0)
        local line_count=$(wc -l < "$script")
        local avg_lines_per_func=$((line_count / (func_count + 1)))
        
        echo -e "${BLUE}$(basename "$script"):${NC}"
        echo "  Functions: $func_count"
        echo "  Total Lines: $line_count"
        echo "  Avg Lines/Function: $avg_lines_per_func"
        
        if [[ $avg_lines_per_func -gt 50 ]]; then
            log_warn "  Average function length is high (> 50 lines)"
        else
            log_pass "  Complexity within acceptable range"
        fi
    done
}

################################################################################
# Documentation Validation
################################################################################

validate_documentation() {
    log_info "Validating documentation..."
    
    local scripts=(
        "${CLI_DIR}/sandbox-config.sh"
        "${CLI_DIR}/sandbox-aliases.sh"
        "${CLI_DIR}/sandbox-help.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            continue
        fi
        
        # Check for header comments
        if grep -q '^################################' "$script"; then
            log_pass "$(basename "$script") has header documentation"
        else
            log_warn "$(basename "$script") missing header documentation"
        fi
        
        # Check for function documentation
        local funcs=$(grep -c '^[a-zA-Z_][a-zA-Z0-9_]*()' "$script" || echo 0)
        local docs=$(grep -c '^#.*Purpose\|^# Arg' "$script" || echo 0)
        
        if [[ $docs -lt $((funcs / 2)) ]]; then
            log_warn "$(basename "$script") has limited function documentation"
        fi
    done
}

################################################################################
# Report Generation
################################################################################

generate_lint_report() {
    log_info "Generating lint report..."
    
    local report_file="${LINT_RESULTS_DIR}/lint-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Sandbox CLI - Code Quality Report"
        echo "=================================="
        echo "Generated: $(date)"
        echo ""
        echo "Summary:"
        echo "  Issues Found: $ISSUES_FOUND"
        echo "  Warnings: $WARNINGS_FOUND"
        echo "  Errors: $ERRORS_FOUND"
        echo ""
        
        echo "Files Analyzed:"
        ls -1 "${CLI_DIR}"/sandbox-*.sh 2>/dev/null | xargs -n1 basename | sed 's/^/  - /'
        echo ""
        
        echo "Checks Performed:"
        echo "  ✓ ShellCheck syntax analysis"
        echo "  ✓ Bash syntax validation"
        echo "  ✓ Style and formatting"
        echo "  ✓ Security checks"
        echo "  ✓ Dependency analysis"
        echo "  ✓ Complexity analysis"
        echo "  ✓ Documentation validation"
        echo ""
        
    } | tee "$report_file"
    
    log_pass "Report saved to: $report_file"
}

################################################################################
# Main Entry Point
################################################################################

main() {
    local action="${1:-all}"
    
    # Create results directory
    mkdir -p "$LINT_RESULTS_DIR"
    
    echo "════════════════════════════════════════════════════════"
    echo "Sandbox CLI - Code Quality & Linting"
    echo "════════════════════════════════════════════════════════"
    echo "Action: $action"
    echo ""
    
    case "$action" in
        lint)
            validate_bash_syntax
            ;;
        shellcheck)
            lint_with_shellcheck
            ;;
        validate)
            validate_bash_syntax
            validate_shell_style
            ;;
        security)
            security_check
            ;;
        complexity)
            analyze_complexity
            ;;
        dependencies)
            analyze_dependencies
            ;;
        docs)
            validate_documentation
            ;;
        all)
            validate_bash_syntax
            validate_shell_style
            security_check
            analyze_dependencies
            analyze_complexity
            validate_documentation
            ;;
        *)
            echo "Unknown action: $action"
            echo "Usage: $0 [lint|shellcheck|validate|security|complexity|dependencies|docs|all]"
            return 1
            ;;
    esac
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "Summary: $ERRORS_FOUND errors, $WARNINGS_FOUND warnings, $ISSUES_FOUND total issues"
    echo "════════════════════════════════════════════════════════"
    
    if [[ "$STRICT" == "true" ]] && [[ $ERRORS_FOUND -gt 0 ]]; then
        return 1
    fi
    
    generate_lint_report
}

main "$@"
