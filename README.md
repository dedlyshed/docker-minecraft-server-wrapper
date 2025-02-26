# Balconium minecraft server in docker

Build:

```
docker build -t balconium .
```

Run:

```
docker run -d --name balconium -p 25565:25565 balconium
```

Logs:
```
docker logs -f balconium
```

Attach

```
docker exec -it balconium screen -r mcserver
```

Stop server not gracefully 

```
docker stop balconium
```