# Oracle Database

<br>


## Oracle Database Free

### Docker

##### Pull Command for Latest
```
docker pull container-registry.oracle.com/database/free:latest
```

##### Run Docker with Custom Configurations
```
docker run -d --name oracle-free \
  -p 1521:1521 -p 5500:5500 \
  -e ORACLE_PWD=Demasy@1986 \
  container-registry.oracle.com/database/free:latest
```

##### Stop the Container
```
docker stop oracle-free
```

##### Start the Container
```
docker start oracle-free
```

##### Remove the Container
```
docker rm -f oracle-free
```


### Connect to the Database

##### Shell into the Container
```
docker exec -it oracle-free bash
```

```
sqlplus / as sysdba
```

##### Using Oracle SQLcl
```
./sql sys/Demasy@1986@localhost:1521/FREE as sysdba
```

