# Service Management


## Database Service

#### Stop Database
```bash
docker stop oracle-al-database-26ai
```

#### Start Database
```bash
docker start oracle-al-database-26ai
```

#### Restart Database
```bash
docker restart oracle-al-database-26ai
```

#### Remove Database Container
```bash
docker rm -f oracle-al-database-26ai
```

#### Access Database Shell
```bash
docker exec -it oracle-al-database-26ai bash
```

#### View Database Logs
```bash
# View all logs
docker logs oracle-al-database-26ai

# Follow logs in real-time
docker logs -f oracle-al-database-26ai

# View last 100 lines
docker logs --tail 100 oracle-al-database-26ai

# View logs with timestamps
docker logs -t oracle-al-database-26ai
```

#### Monitor Database
```bash
# View container details
docker inspect oracle-al-database-26ai

# View resource usage
docker stats oracle-al-database-26ai

# Check container health
docker inspect --format='{{.State.Health.Status}}' oracle-al-database-26ai
```

#### Database Port Status
```bash
# Check if database port is listening
netstat -an | grep 1521

# Check Enterprise Manager Express port
netstat -an | grep 5500
```

#### Backup Database
```bash
# Create a backup of the container
docker commit oracle-al-database-26ai oracle-db-backup:$(date +%Y%m%d)
```

<br>

## Management Server

#### Stop Server
```bash
docker stop demasy-server
```

#### Start Server
```bash
docker start demasy-server
```

#### Restart Server
```bash
docker restart demasy-server
```

#### Remove Container
```bash
docker rm -f demasy-server
```

#### Access Shell
```bash
docker exec -it demasy-server bash
```

#### View Logs
```bash
# View all logs
docker logs demasy-server

# Follow logs in real-time
docker logs -f demasy-server

# View last 100 lines
docker logs --tail 100 demasy-server
```

#### Check Container Status
```bash
# View container details
docker inspect demasy-server

# View resource usage
docker stats demasy-server
```
