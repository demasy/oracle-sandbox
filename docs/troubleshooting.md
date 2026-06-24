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
docker logs -f oracle-al-database-26ai
```

## Connection Refused

**Symptom:** Cannot connect to database

**Solution:**
```bash
# Verify database is healthy
docker ps --filter "name=oracle-al-database-26ai"

# Check listener status
docker exec oracle-al-database-26ai lsnrctl status

# Verify network connectivity
docker exec demasy-server ping oracle-al-database-26ai

# Check firewall rules
sudo iptables -L
```

## APEX Installation Fails

**Symptom:** `install-apex` command returns errors

**Solution:**
```bash
# Check database is running
docker exec -it oracle-al-database-26ai sqlplus / as sysdba

# Review installation logs
docker exec demasy-server cat /tmp/apex_install.log

# Verify connectivity
docker exec demasy-server ping oracle-al-database-26ai
```

## Images Not Loading in APEX

**Symptom:** APEX UI shows missing images

**Solution:**
```bash
# Verify images directory
docker exec demasy-server ls -la /tmp/i | wc -l

# Should show ~27000 files
# If empty, reinstall APEX or restart ORDS

docker exec demasy-server stop-apex
docker exec demasy-server start-apex
```
