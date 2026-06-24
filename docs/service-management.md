# Service Management


## Database Service

#### Stop Database
```bash
docker stop sandbox-oracle-database
```

#### Start Database
```bash
docker start sandbox-oracle-database
```

#### Restart Database
```bash
docker restart sandbox-oracle-database
```

#### Remove Database Container
```bash
docker rm -f sandbox-oracle-database
```

#### Access Database Shell
```bash
docker exec -it sandbox-oracle-database bash
```

#### View Database Logs
```bash
# View all logs
docker logs sandbox-oracle-database

# Follow logs in real-time
docker logs -f sandbox-oracle-database

# View last 100 lines
docker logs --tail 100 sandbox-oracle-database

# View logs with timestamps
docker logs -t sandbox-oracle-database
```

#### Monitor Database
```bash
# View container details
docker inspect sandbox-oracle-database

# View resource usage
docker stats sandbox-oracle-database

# Check container health
docker inspect --format='{{.State.Health.Status}}' sandbox-oracle-database
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
docker commit sandbox-oracle-database oracle-db-backup:$(date +%Y%m%d)
```

<br>

## Management Server

#### Stop Server
```bash
docker stop sandbox-oracle-server
```

#### Start Server
```bash
docker start sandbox-oracle-server
```

#### Restart Server
```bash
docker restart sandbox-oracle-server
```

#### Remove Container
```bash
docker rm -f sandbox-oracle-server
```

#### Access Shell
```bash
docker exec -it sandbox-oracle-server bash
```

#### View Logs
```bash
# View all logs
docker logs sandbox-oracle-server

# Follow logs in real-time
docker logs -f sandbox-oracle-server

# View last 100 lines
docker logs --tail 100 sandbox-oracle-server
```

#### Check Container Status
```bash
# View container details
docker inspect sandbox-oracle-server

# View resource usage
docker stats sandbox-oracle-server
```
