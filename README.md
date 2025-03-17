# 1.21.1 Fabric Minecraft server in docker

## Build:

```
docker build -t dedlyshed-mc-server .
```

## Run

### Example 1: Running new vanilla minecraft 1.21.4 server

```bash
mkdir -p server-data
wget -O ./server-data/mc-server.jar https://piston-data.mojang.com/v1/objects/4707d00eb834b446575d89a61a11b5d548d8c001/server.jar
```

```bash
docker run -d \
    --name dedlyshed-mc-server \
    --user "$(id -u):$(id -g)" \
    -e EULA=true \
    -p 25565:25565 \
    -v ./server-data:/server/data \
    dedlyshed-mc-server
```

### Example 2: Running existing modded server with custom params

> ℹ️ RCON and connection parameters will be **overwritten** in `server.properties`.  It is safe because rcon is not exposed outside of container. It is required for gracefull server shutdown and command execution via docker exec.
>
> ℹ️ Make sure your minecraft server is compatible with **java 21**.

```bash
mv /path/to/your/mc-server/* server-data/
```

```bash
docker run -d \
    --name dedlyshed-mc-server \
    --user "$(id -u):$(id -g)" \
    -e EULA=true \
    -p 25565:25565 \
    -v ./server-data:/server/data \
    dedlyshed-mc-server \
    -Xms6G -Xmx6G -Dfml.readTimeout=180 @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui
```

---

## Kind of useful commands:

### Shutdown gracefully

```
docker stop dedlyshed-mc-server
```

### Whitelist player

```
docker exec dedlyshed-mc-server rcon-cli --config /server/rcon.yaml "whitelist add Dedlyshed"
```

### OP player

```
docker exec dedlyshed-mc-server rcon-cli --config /server/rcon.yaml "op Dedlyshed"
```

With OP rights, you can shutdown gracefully as well from the game using `/stop`, container will stop, too. Make sure `op-permission-level=4` is set in `server.properties`.