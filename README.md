# Balconium minecraft server in docker

Build:

```
docker build -t balconium .
```

Run:

```
docker run -d --name balconium -p 25565:25565 balconium
```

Troubleshoot:

```
docker run -it --rm --name balconium -p 25565:25565 balconium /bin/sh
```

Shutdown 
```
docker stop balconium

# Shutdown gracefully and let players know to GTFO
docker exec balconium rcon-cli --config /server/rcon.yaml "kick @a GTFO, Server is shutting down! Have a nice day!" stop
```