# Oracle Database

<br>


## Oracle Database Free

### Docker

Pull Command for Latest
```
docker pull container-registry.oracle.com/database/free:latest
```

Custom Configurations
```
docker run -d --name oracle-free \
  -p 1521:1521 -p 5500:5500 \
  -e ORACLE_PWD=Demasy@1986 \
  container-registry.oracle.com/database/free:latest
```
