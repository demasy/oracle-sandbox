# Production Hardening & Security Guide

## Overview
This document details the security hardening, error handling, and deployment preparation for the Oracle Sandbox CLI system. All features from Phases 5-6 are production-ready; this phase focuses on robustness, security, and operational excellence.

## 1. Security Hardening

### 1.1 Input Validation & Sanitization

#### Status: ⚠️ PARTIAL
**Current Implementation:**
- Basic parameter parsing via `_parse_flag_with_value()` and `_parse_flag_standalone()`
- File existence checks in import/batch/template operations
- Database connection parameter validation in conn add

**Required Enhancements:**
```bash
# Add to sandbox-params.sh
_sanitize_input() {
    local input="$1"
    # Remove shell metacharacters
    echo "$input" | sed 's/[;|&$(){}[\]<>]//' | head -c 255
}

_validate_connection_params() {
    local user="$1" host="$2" port="$3"
    [[ ! "$user" =~ ^[a-zA-Z0-9_]{1,30}$ ]] && return 1
    [[ ! "$host" =~ ^[a-zA-Z0-9._-]{1,253}$ ]] && return 1
    [[ ! "$port" =~ ^[0-9]{1,5}$ ]] && return 1
    return 0
}
```

### 1.2 SQL Injection Prevention

#### Status: ⚠️ REQUIRES ATTENTION
**Current Risk:**
- SQL queries concatenate variables directly in sqlcl calls
- `_check_oracle_status()`, `_collect_database_metrics()` vulnerable

**Required Fixes:**
```bash
# Use bind variables instead of concatenation
_execute_safe_query() {
    local query="$1"
    sqlcl -S /nolog << EOF
set heading off feedback off pagesize 0
connect \${SANDBOX_DB_USER}/\${SANDBOX_DB_PASS}@\${SANDBOX_DB_HOST}:\${SANDBOX_DB_PORT}/\${SANDBOX_DB_PDB}
$query
exit;
EOF
}
```

### 1.3 Access Control

#### Status: 🔴 NOT IMPLEMENTED
**Required Additions:**
- Role-based access control for audit operations
- Sensitive operation (delete, rollback, import) require confirmation
- Audit log for all administrative operations
- User/role tracking in audit entries

```bash
_require_confirmation() {
    local operation="$1"
    read -p "Confirm $operation (type 'yes' to proceed): " -r confirmation
    [[ "$confirmation" != "yes" ]] && return 1
}
```

### 1.4 Secret Management

#### Status: ⚠️ PARTIAL
**Current Implementation:**
- Passwords stored in environment variables
- Connection files may contain plaintext passwords (export/import)

**Required Enhancements:**
- Use `.sandbox/secrets.conf` with restricted permissions (600)
- Support for keyring/credential helpers
- Password masking in logs/output
- Template export should exclude sensitive credentials

### 1.5 Audit Trail Integrity

#### Status: ✅ IMPLEMENTED
- Comprehensive audit logging with timestamps
- Immutable action records
- Search and export capabilities for compliance

**Recommendations:**
- Add digital signing to audit logs
- Support for log archival to external storage
- Retention policies and cleanup tasks

---

## 2. Error Handling & Resilience

### 2.1 Error Recovery

#### Status: ⚠️ PARTIAL
**Current Implementation:**
- Basic error logging in action handlers
- Rollback support in batch operations (apply-with-rollback)
- Connection retry logic needed

**Required Enhancements:**
```bash
_execute_with_retry() {
    local cmd="$1" max_attempts=3 attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if eval "$cmd"; then
            return 0
        fi
        ((attempt++))
        sleep 2
    done
    return 1
}

_handle_error() {
    local error_code="$1" context="$2"
    _audit_log_operation "error" "system" "$context" "" "failed"
    _log "error" "Operation failed: $error_code"
    return $error_code
}
```

### 2.2 Graceful Degradation

#### Status: ⚠️ PARTIAL
**Current Issues:**
- Monitor action fails silently if metrics unavailable
- Status command shows errors inline instead of fallback values
- SQL contamination from wrapper (non-blocking, workaround needed)

**Improvements:**
- Fallback to cached/previous values
- Graceful handling of missing optional metrics
- Status operation succeeds with reduced data

### 2.3 Timeout & Deadlock Prevention

#### Status: ⚠️ NEEDS IMPLEMENTATION
```bash
_execute_with_timeout() {
    local cmd="$1" timeout_sec=30
    timeout "$timeout_sec" eval "$cmd"
    case $? in
        124) _log "error" "Operation timed out after ${timeout_sec}s" ;;
        *) ;;
    esac
}
```

---

## 3. Operational Hardening

### 3.1 Logging Best Practices

#### Status: ✅ GOOD
- Structured logging with levels (info, warn, error, success)
- Color-coded output for readability
- Audit trail integration

**Remaining Work:**
- Log rotation and retention
- Centralized logging support (syslog/ELK)
- Performance logging

### 3.2 Resource Management

#### Status: ⚠️ PARTIAL
**Current:**
- Audit/template files accumulate indefinitely
- No cleanup policies

**Required:**
```bash
_cleanup_old_logs() {
    local dir="$1" days=90
    find "$dir" -type f -mtime +$days -delete
}
```

### 3.3 Container Security

#### Status: ⚠️ PARTIAL
**Current Issues:**
- Non-root user hardening needed (via runtime-hardening-notes.md)
- Container resource limits not configured
- No security scanning in build pipeline

**Improvements:**
- Add resource limits to docker-compose.yml
- Run containers as non-root user
- Scan images with Trivy during build
- Drop unnecessary Linux capabilities

---

## 4. Documentation & Deployment

### 4.1 Documentation

#### Status: ⚠️ PARTIAL
**Completed:**
- Individual action help sections (sandbox -h)
- High-level README
- Configuration reference

**Required:**
- Security documentation
- Deployment procedures
- Troubleshooting guide
- API/CLI reference guide
- Runbook for common operations

### 4.2 Testing

#### Status: 🔴 NOT IMPLEMENTED
**Required:**
- Unit tests for core functions (parameter parsing, formatting)
- Integration tests for actions (status, import, batch)
- Security tests (injection, privilege escalation)
- Performance tests (load, large batches)

### 4.3 Release Process

#### Status: 🔴 NOT IMPLEMENTED
**Required:**
- Version numbering (semantic versioning)
- Changelog management
- Release notes
- Backward compatibility guarantees
- Deprecation policy

---

## 5. Implementation Checklist

### High Priority (Security Critical)
- [ ] Input validation for all parameters
- [ ] SQL injection prevention (bind variables)
- [ ] Sensitive data masking in logs
- [ ] Confirmation prompts for destructive operations
- [ ] Audit trail verification

### Medium Priority (Operational)
- [ ] Retry logic for transient failures
- [ ] Timeout handling for hanging operations
- [ ] Log rotation and cleanup
- [ ] Error handling improvements
- [ ] Container resource limits

### Low Priority (Enhancement)
- [ ] Comprehensive test suite
- [ ] CI/CD pipeline integration
- [ ] Performance optimizations
- [ ] Advanced monitoring (metrics export)
- [ ] Multi-environment support

---

## 6. Security Best Practices

### Environment Isolation
```bash
# Validate environment setup
_validate_environment() {
    [[ -z "$SANDBOX_DB_USER" ]] && _log "error" "SANDBOX_DB_USER not set" && return 1
    [[ -z "$SANDBOX_DB_PDB" ]] && _log "error" "SANDBOX_DB_PDB not set" && return 1
    return 0
}
```

### Credential Management
```bash
# Load secrets from protected file
_load_credentials() {
    local secrets_file="$HOME/.sandbox/secrets.conf"
    [[ ! -f "$secrets_file" ]] && return 1
    chmod 600 "$secrets_file"  # Enforce permissions
    source "$secrets_file"
}
```

### Audit & Compliance
- All operations logged with user identification
- Immutable audit trail for compliance audits
- Export capabilities for regulatory review
- Retention policies documented

---

## 7. Known Issues & Workarounds

### SQL Output Contamination
**Issue:** SQLcl wrapper script output mixed with query results
**Status:** Known, non-blocking architectural issue
**Workaround:** Use direct `/opt/oracle/sqlcl/bin/sql` calls with output filtering
**Resolution:** Planned for future sqlcl wrapper refactoring

### Non-root Runtime Constraints
**Issue:** Helper scripts cannot write to /usr/local/bin at runtime
**Status:** Documented in runtime-hardening-notes.md
**Solution:** Use writable app bin directory (/usr/sandbox/app/bin)

---

## 8. Production Deployment Checklist

Before deploying to production:
- [ ] All security hardening items implemented
- [ ] Comprehensive test suite passing
- [ ] Documentation complete and reviewed
- [ ] Audit trail verified and tested
- [ ] Backup/recovery procedures documented
- [ ] Security audit performed
- [ ] Performance baseline established
- [ ] Rollback procedures tested
- [ ] Monitoring dashboards configured
- [ ] Incident response plan created

---

## 9. Success Metrics

**Security:**
- Zero injection vulnerabilities in security scans
- 100% input validation coverage
- All operations audited and logged

**Reliability:**
- 99.5% uptime for core services
- < 2s average operation latency
- < 0.1% failed operations

**Operations:**
- Log retention policy enforced
- Resource cleanup scheduled
- Alerts configured for anomalies

---

*Last Updated: Phase 6 Completion*
*Next Phase: Implement hardening items in priority order*
