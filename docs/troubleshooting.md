# Troubleshooting

## Common Issues

### Port Already in Use

**Symptom:** Container fails to start with port binding error

**Solution:**

```bash
# Check what's using the port
lsof -i :1521
netstat -an | grep 1521

# Stop conflicting service or change port in docker-compose.yml
```

## Database Initialization Timeout

**Symptom:** Database takes longer than 10 minutes to initialize

**Solution:**

```bash
# Increase timeout in healthcheck
# Check available resources
docker system df
docker system prune  # Free up space

# Monitor initialization
docker logs -f sandbox-oracle-database
```

## Connection Refused

**Symptom:** Cannot connect to database

**Solution:**
```bash
# Verify database is healthy
docker ps --filter "name=sandbox-oracle-database"

# Check listener status
docker exec sandbox-oracle-database lsnrctl status

# Verify network connectivity
docker exec sandbox-oracle-server ping sandbox-oracle-database

# Check firewall rules
sudo iptables -L
```

## APEX Installation Fails

**Symptom:** `install-apex` command returns errors

**Solution:**
```bash
# Check database is running
docker exec -it sandbox-oracle-database sqlplus / as sysdba

# Review installation logs
docker exec sandbox-oracle-server cat /tmp/apex_install.log

# Verify connectivity
docker exec sandbox-oracle-server ping sandbox-oracle-database
```

## Images Not Loading in APEX

**Symptom:** APEX UI shows missing images

**Solution:**
```bash
# Verify images directory
docker exec sandbox-oracle-server ls -la /tmp/i | wc -l

# Should show ~27000 files
# If empty, reinstall APEX or restart ORDS

docker exec sandbox-oracle-server stop-apex
docker exec sandbox-oracle-server start-apex
```
