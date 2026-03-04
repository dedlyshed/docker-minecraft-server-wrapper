# Minecraft Server wrapper in docker

## Purpose

I made this wrapper to run my different Minecraft servers in my homelab Kubernetes cluster; therefore, it requires a Docker container as a wrapper. The main advantage of this wrapper is that it is lightweight, allows the server to shut down gracefully with docker stop or CTRL+C, and enables executing Minecraft commands with docker exec while displaying Minecraft logs.

## Pull

```bash
docker pull ghcr.io/dedlyshed/dedlyshed-mc-server:1.1
```

## Build

```bash
docker build \
  -t dedlyshed-mc-server \
  -t ghcr.io/dedlyshed/dedlyshed-mc-server:1.1 \
  -t ghcr.io/dedlyshed/dedlyshed-mc-server:latest \
  .
```

## Run

### Example 1: Running new vanilla minecraft 1.21.4 server

```bash
mkdir -p server-data
wget -O ./server-data/mc-server.jar https://piston-data.mojang.com/v1/objects/4707d00eb834b446575d89a61a11b5d548d8c001/server.jar

docker run -d \
    --name dedlyshed-mc-server \
    --user "$(id -u):$(id -g)" \
    -e EULA=true \
    -p 25565:25565 \
    -v ./server-data:/server/data \
    ghcr.io/dedlyshed/dedlyshed-mc-server:latest
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
    ghcr.io/dedlyshed/dedlyshed-mc-server:latest \
    -Xms6G -Xmx6G -Dfml.readTimeout=180 @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui
```

## Tag and push

Tag and push to GitHub Container Registry:

```bash
docker tag ghcr.io/dedlyshed/dedlyshed-mc-server:1.1 ghcr.io/dedlyshed/dedlyshed-mc-server:latest

export CR_PAT='<your_token_here>'
echo "$CR_PAT" | docker login ghcr.io -u dedlyshed --password-stdin

docker push ghcr.io/dedlyshed/dedlyshed-mc-server:1.1
docker push ghcr.io/dedlyshed/dedlyshed-mc-server:latest
```

---

## Kind of useful commands:

### Shutdown gracefully

```
docker stop dedlyshed-mc-server
```

### Whitelist player

```
docker exec dedlyshed-mc-server rcon-cli --config /server/data/rcon.yaml "whitelist add Dedlyshed"
```

### OP player

```
docker exec dedlyshed-mc-server rcon-cli --config /server/data/rcon.yaml "op Dedlyshed"
```

With OP rights, you can shutdown gracefully as well from the game using `/stop`, container will stop, too. Make sure `op-permission-level=4` is set in `server.properties`.