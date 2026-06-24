#!/bin/bash
################################################################################
# Sandbox CLI - Performance Monitoring & Benchmarking
# Purpose: Measure CLI performance, memory usage, and execution times
# Usage: ./sandbox-performance.sh [benchmark|monitor|profile|report]
################################################################################

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="${SCRIPT_DIR%/scripts/cli}"
source "${CLI_DIR}/sandbox-config.sh"

# Performance configuration
PERF_RESULTS_DIR="${PERF_RESULTS_DIR:-./.perf}"
ITERATIONS="${ITERATIONS:-10}"
SAMPLE_INTERVAL="${SAMPLE_INTERVAL:-1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

################################################################################
# Utilities
################################################################################

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_metric() { echo -e "${CYAN}[METRIC]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $*"; }

# Get memory usage (MB)
get_memory_usage() {
    local pid=$1
    if command -v ps &> /dev/null; then
        ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1 / 1024}'
    fi
}

# Get CPU usage percentage
get_cpu_usage() {
    local pid=$1
    if command -v ps &> /dev/null; then
        ps -o %cpu= -p "$pid" 2>/dev/null
    fi
}

# Measure execution time (milliseconds)
measure_time() {
    local start=$(date +%s%N)
    "$@" > /dev/null 2>&1
    local end=$(date +%s%N)
    echo $(( (end - start) / 1000000 ))
}

# Calculate statistics
calc_stats() {
    local values=("$@")
    local sum=0
    local min=${values[0]}
    local max=${values[0]}
    
    for val in "${values[@]}"; do
        sum=$((sum + val))
        [[ $val -lt $min ]] && min=$val
        [[ $val -gt $max ]] && max=$val
    done
    
    local avg=$((sum / ${#values[@]}))
    
    echo "avg=$avg min=$min max=$max sum=$sum"
}

################################################################################
# Benchmark Tests
################################################################################

benchmark_help_load() {
    log_info "Benchmarking Help System Load (${ITERATIONS} iterations)"
    
    local times=()
    for ((i=0; i<ITERATIONS; i++)); do
        local time=$(measure_time source "${CLI_DIR}/sandbox-help.sh")
        times+=($time)
        echo -n "."
    done
    echo ""
    
    local stats=$(calc_stats "${times[@]}")
    eval "$stats"
    
    log_metric "Help System Load: avg=${avg}ms min=${min}ms max=${max}ms"
    echo "$stats" >> "${PERF_RESULTS_DIR}/benchmark-help-load.txt"
}

benchmark_aliases_load() {
    log_info "Benchmarking Aliases Load (${ITERATIONS} iterations)"
    
    local times=()
    for ((i=0; i<ITERATIONS; i++)); do
        local time=$(measure_time source "${CLI_DIR}/sandbox-aliases.sh")
        times+=($time)
        echo -n "."
    done
    echo ""
    
    local stats=$(calc_stats "${times[@]}")
    eval "$stats"
    
    log_metric "Aliases Load: avg=${avg}ms min=${min}ms max=${max}ms"
    echo "$stats" >> "${PERF_RESULTS_DIR}/benchmark-aliases-load.txt"
}

benchmark_config_load() {
    log_info "Benchmarking Configuration Load (${ITERATIONS} iterations)"
    
    local times=()
    for ((i=0; i<ITERATIONS; i++)); do
        local time=$(measure_time source "${CLI_DIR}/sandbox-config.sh")
        times+=($time)
        echo -n "."
    done
    echo ""
    
    local stats=$(calc_stats "${times[@]}")
    eval "$stats"
    
    log_metric "Configuration Load: avg=${avg}ms min=${min}ms max=${max}ms"
    echo "$stats" >> "${PERF_RESULTS_DIR}/benchmark-config-load.txt"
}

benchmark_format_operations() {
    log_info "Benchmarking Format Operations (${ITERATIONS} iterations)"
    
    source "${CLI_DIR}/sandbox-format.sh"
    
    # Test JSON formatting
    local json_test='{"service":"database","status":"running","port":1521}'
    local times=()
    for ((i=0; i<ITERATIONS; i++)); do
        local time=$(measure_time format_json "$json_test")
        times+=($time)
        echo -n "."
    done
    echo ""
    
    local stats=$(calc_stats "${times[@]}")
    eval "$stats"
    log_metric "JSON Formatting: avg=${avg}ms min=${min}ms max=${max}ms"
    
    # Test CSV formatting
    times=()
    for ((i=0; i<ITERATIONS; i++)); do
        local time=$(measure_time format_csv "service,status,port" "database,running,1521")
        times+=($time)
        echo -n "."
    done
    echo ""
    
    stats=$(calc_stats "${times[@]}")
    eval "$stats"
    log_metric "CSV Formatting: avg=${avg}ms min=${min}ms max=${max}ms"
}

################################################################################
# Monitoring
################################################################################

monitor_cli() {
    log_info "Monitoring CLI Performance (${SAMPLE_INTERVAL}s interval)"
    
    local output_file="${PERF_RESULTS_DIR}/monitor-$(date +%Y%m%d-%H%M%S).csv"
    
    echo "timestamp,memory_mb,cpu_percent,command" > "$output_file"
    
    # Monitor a running CLI command (this would need a long-running process)
    log_info "Enter monitoring duration (seconds, default 10):"
    local duration=${1:-10}
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        local timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
        
        # Note: This would require actual running processes to monitor
        # For now, we'll log the monitoring points
        echo "$timestamp,0,0,idle" >> "$output_file"
        
        sleep "$SAMPLE_INTERVAL"
    done
    
    log_success "Monitoring data saved to: $output_file"
}

################################################################################
# Profiling
################################################################################

profile_functions() {
    log_info "Profiling Key Functions"
    
    source "${CLI_DIR}/sandbox-config.sh"
    source "${CLI_DIR}/sandbox-params.sh"
    source "${CLI_DIR}/sandbox-format.sh"
    
    local profile_output="${PERF_RESULTS_DIR}/profile-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Function Performance Profile"
        echo "============================"
        echo "Generated: $(date)"
        echo ""
        
        echo "### Configuration Loading ###"
        local time=$(measure_time source "${CLI_DIR}/sandbox-config.sh")
        echo "sandbox-config.sh: ${time}ms"
        echo ""
        
        echo "### Parameter Processing ###"
        time=$(measure_time bash -c "source ${CLI_DIR}/sandbox-params.sh && parse_params --test value")
        echo "parse_params: ${time}ms"
        echo ""
        
        echo "### Format Operations ###"
        time=$(measure_time bash -c "source ${CLI_DIR}/sandbox-format.sh && format_json '{\"test\":1}'")
        echo "format_json: ${time}ms"
        echo ""
        
    } | tee "$profile_output"
    
    log_success "Profile saved to: $profile_output"
}

################################################################################
# Reporting
################################################################################

generate_report() {
    log_info "Generating Performance Report"
    
    local report_file="${PERF_RESULTS_DIR}/performance-report-$(date +%Y%m%d-%H%M%S).md"
    
    {
        echo "# Sandbox CLI Performance Report"
        echo ""
        echo "**Generated**: $(date)"
        echo ""
        
        echo "## Benchmark Results"
        echo ""
        
        if [[ -f "${PERF_RESULTS_DIR}/benchmark-help-load.txt" ]]; then
            echo "### Help System Load"
            cat "${PERF_RESULTS_DIR}/benchmark-help-load.txt" | sed 's/^/- /'
            echo ""
        fi
        
        if [[ -f "${PERF_RESULTS_DIR}/benchmark-aliases-load.txt" ]]; then
            echo "### Aliases Load"
            cat "${PERF_RESULTS_DIR}/benchmark-aliases-load.txt" | sed 's/^/- /'
            echo ""
        fi
        
        if [[ -f "${PERF_RESULTS_DIR}/benchmark-config-load.txt" ]]; then
            echo "### Configuration Load"
            cat "${PERF_RESULTS_DIR}/benchmark-config-load.txt" | sed 's/^/- /'
            echo ""
        fi
        
        echo "## System Information"
        echo ""
        echo "- **OS**: $(uname -s)"
        echo "- **Kernel**: $(uname -r)"
        echo "- **CPU Cores**: $(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 'unknown')"
        echo "- **Memory**: $(sysctl -n hw.memsize 2>/dev/null | awk '{print $1/1024/1024/1024 " GB"}' || echo 'unknown')"
        echo ""
        
        echo "## CLI Components Status"
        echo ""
        echo "- Help System: $(test -f "${CLI_DIR}/sandbox-help.sh" && echo '✓' || echo '✗')"
        echo "- Aliases: $(test -f "${CLI_DIR}/sandbox-aliases.sh" && echo '✓' || echo '✗')"
        echo "- Configuration: $(test -f "${CLI_DIR}/sandbox-config.sh" && echo '✓' || echo '✗')"
        echo "- Formatting: $(test -f "${CLI_DIR}/sandbox-format.sh" && echo '✓' || echo '✗')"
        echo ""
        
    } | tee "$report_file"
    
    log_success "Report saved to: $report_file"
}

################################################################################
# Main Entry Point
################################################################################

main() {
    local action="${1:-report}"
    
    # Create results directory
    mkdir -p "$PERF_RESULTS_DIR"
    
    echo "════════════════════════════════════════════════════════"
    echo "Sandbox CLI - Performance Analysis"
    echo "════════════════════════════════════════════════════════"
    echo "Action: $action"
    echo "Iterations: $ITERATIONS"
    echo ""
    
    case "$action" in
        benchmark)
            benchmark_help_load
            benchmark_aliases_load
            benchmark_config_load
            benchmark_format_operations
            log_success "Benchmarking complete"
            ;;
        monitor)
            monitor_cli "${2:-10}"
            ;;
        profile)
            profile_functions
            ;;
        report)
            generate_report
            ;;
        all)
            benchmark_help_load
            benchmark_aliases_load
            benchmark_config_load
            benchmark_format_operations
            profile_functions
            generate_report
            log_success "Full performance analysis complete"
            ;;
        *)
            echo "Unknown action: $action"
            echo "Usage: $0 [benchmark|monitor|profile|report|all]"
            return 1
            ;;
    esac
}

main "$@"
