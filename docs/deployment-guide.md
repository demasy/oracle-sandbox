# Oracle Sandbox CLI - Deployment & Operations Guide

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Bash 4.0+
- SQLcl 26.1 or later
- Oracle Instant Client (included in container)

### Installation

```bash
# Clone repository
git clone https://github.com/demasy/oracle-sandbox.git
cd oracle-sandbox

# Build containers
DOCKER_BUILDKIT=0 docker compose build

# Start services
docker compose up -d

# Verify installation
docker exec sandbox-oracle-server sandbox status
```

---

## Core Commands

### Status & Monitoring

```bash
# Display comprehensive status dashboard
sandbox status

# Export metrics for monitoring systems
sandbox monitor --export prometheus
sandbox monitor --export json | jq .

# View audit trail
sandbox audit list --limit 20
```

### Configuration Management

```bash
# Save configuration snapshot
sandbox template save --name production --description "Production config"

# Export for backup
sandbox template export --name production --file /backups/prod.template

# Restore from template
sandbox template load --name production --apply
```

### Batch Operations

```bash
# Execute multiple commands from file
sandbox batch execute --file commands.txt

# Apply with automatic rollback on failure
sandbox batch apply-with-rollback --file connections.csv

# Preview changes without applying
sandbox batch execute --file commands.txt --dry-run
```

### Import/Export

```bash
# Export current configuration
sandbox export config > config.json
sandbox export connections --format csv > connections.csv

# Import from file
sandbox import connections --file connections.csv
sandbox import config --file config.json
```

---

## Security Best Practices

### 1. Credential Management
```bash
# Store secrets in protected file
mkdir -p ~/.sandbox
cat > ~/.sandbox/secrets.conf << EOF
export SANDBOX_DB_USER=system
export SANDBOX_DB_PASS=SecurePassword123
EOF
chmod 600 ~/.sandbox/secrets.conf

# Load before running sandbox
source ~/.sandbox/secrets.conf
```

### 2. Audit Trail Review
```bash
# Review all administrative operations
sandbox audit search --search "delete\|import\|rollback"

# Export for compliance
sandbox audit export --export json > /audit-backups/audit-$(date +%Y%m%d).json
```

### 3. Access Control
- Restrict container access to authorized users only
- Use network segmentation for database connections
- Enable audit logging for all operations
- Review logs regularly for anomalies

### 4. Backup Strategy
```bash
# Daily template backup
sandbox template export --name production \
  --file /backups/prod-$(date +%Y%m%d).template

# Weekly connection backup
sandbox export connections \
  > /backups/connections-$(date +%Y%m%d).json

# Full audit log export
sandbox audit export --export json \
  > /audit-backups/audit-$(date +%Y%m%d).json
```

---

## Monitoring & Alerts

### Metrics Collection
```bash
# Collect system metrics every minute
0 * * * * docker exec sandbox-oracle-server \
    sandbox monitor --export json >> /var/log/sandbox-metrics.log

# Monitor database health
0 * * * * docker exec sandbox-oracle-server \
    sandbox status database --format json >> /var/log/sandbox-db.log
```

### Health Checks
```bash
# Verify services are healthy
docker compose ps

# Check specific service
docker exec sandbox-oracle-server sandbox status database
docker exec sandbox-oracle-server sandbox status apex
```

### Log Rotation
```bash
# Configure logrotate
cat > /etc/logrotate.d/sandbox << EOF
/var/log/sandbox-*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root root
}
EOF
```

---

## Troubleshooting

### Common Issues

#### 1. Connection Failures
```bash
# Test database connectivity
sandbox conn test --name <connection_name>

# Check connection parameters
sandbox conn list

# View logs for details
docker logs sandbox-oracle-server | tail -50
```

#### 2. Import Errors
```bash
# Validate import file format
cat connections.csv | head -5  # Check header

# Try with verbose output
sandbox import connections --file connections.csv --verbose

# Check audit trail for details
sandbox audit search --search "import" --limit 10
```

#### 3. Batch Operation Failures
```bash
# Dry-run to preview issues
sandbox batch execute --file commands.txt --dry-run

# Use rollback for safety
sandbox batch apply-with-rollback --file commands.txt

# Check rollback script after failure
ls -la /tmp/sandbox_batch_rollback.sh
```

#### 4. Performance Issues
```bash
# Monitor system metrics
sandbox monitor --export table

# Check database performance
sandbox status database

# Review audit log for slow operations
sandbox audit search --search "slow" --export json
```

### Debugging

```bash
# Enable verbose logging
export SANDBOX_VERBOSE=1
sandbox status

# Check container resources
docker stats sandbox-oracle-server

# Inspect container environment
docker exec sandbox-oracle-server env | grep SANDBOX
```

---

## Maintenance Tasks

### Daily
```bash
# Check system health
sandbox status

# Review recent audit entries
sandbox audit list --limit 50
```

### Weekly
```bash
# Export audit logs
sandbox audit export --export json > /backups/audit-weekly.json

# Create template snapshot
sandbox template save --name "weekly_snapshot" \
    --description "Weekly backup $(date +%Y-%m-%d)"
```

### Monthly
```bash
# Full configuration export
mkdir -p /backups/monthly-$(date +%Y%m)
sandbox export config > /backups/monthly-$(date +%Y%m)/config.json
sandbox export connections > /backups/monthly-$(date +%Y%m)/connections.json

# Audit stats and review
sandbox audit stats > /backups/monthly-$(date +%Y%m)/audit-stats.txt
```

### Quarterly
```bash
# Security audit
docker compose logs | grep -i "error\|failed\|denied" > security-review.log

# Performance analysis
docker stats --no-stream > perf-baseline.txt

# Template cleanup
sandbox template list | grep -v "production\|staging"
```

---

## Upgrade & Migration

### Pre-Upgrade Checklist
```bash
# Create backup snapshot
sandbox template save --name "pre-upgrade-$(date +%Y%m%d)"

# Export full configuration
sandbox export config > pre-upgrade-config.json
sandbox export connections > pre-upgrade-connections.json

# Document audit trail
sandbox audit export --export json > pre-upgrade-audit.json
```

### Upgrade Steps
```bash
# Stop services
docker compose down

# Update code
git pull origin main

# Rebuild containers
DOCKER_BUILDKIT=0 docker compose build

# Start services
docker compose up -d

# Verify upgrade
docker compose logs -f --tail=50

# Test operations
sandbox status
sandbox import connections --file pre-upgrade-connections.json
```

### Post-Upgrade Verification
```bash
# Verify all commands work
for cmd in status import batch monitor audit template; do
    sandbox $cmd -h > /dev/null && echo "✓ $cmd" || echo "✗ $cmd"
done

# Compare configurations
sandbox export config > post-upgrade-config.json
diff pre-upgrade-config.json post-upgrade-config.json
```

---

## Performance Tuning

### Container Optimization
```yaml
# Update docker-compose.yml
services:
  oracle-server:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### Database Optimization
```bash
# Adjust batch sizes for large imports
sandbox batch apply-connections --file large_batch.csv

# Use format optimization for large exports
sandbox export config --format json | gzip > config.json.gz
```

### Monitoring Performance
```bash
# Track operation latency
time sandbox status database

# Measure batch processing
time sandbox batch execute --file commands.txt
```

---

## Compliance & Auditing

### Audit Log Management
- All operations logged with timestamp and user
- Immutable audit trail for compliance
- Search and export for regulatory review

### Data Retention Policy
```bash
# Keep audit logs for 90 days
find /tmp/sandbox_audit -type f -mtime +90 -delete

# Archive templates monthly
tar -czf /archive/templates-$(date +%Y%m).tar.gz /tmp/sandbox_templates/
```

### Compliance Reporting
```bash
# Generate audit report
sandbox audit export --export json > compliance-report.json

# Extract failed operations
cat compliance-report.json | jq '.entries[] | select(.status=="failed")'
```

---

## Support & Community

### Getting Help
- Check logs: `docker logs sandbox-oracle-server`
- Review audit trail: `sandbox audit search --search <pattern>`
- Test connectivity: `sandbox conn test --name <connection>`

### Reporting Issues
Include:
1. Command executed
2. Error output
3. Audit log entries: `sandbox audit export --export json`
4. System information: `docker compose ps`

### Contributing
- Fork repository
- Create feature branch
- Test changes: `bash tests/test-suite.sh`
- Submit pull request

---

*Last Updated: Phase 6 Completion*
*Version: 1.0*
*Status: Production Ready*
