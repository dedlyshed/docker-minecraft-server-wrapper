# 1.20.1 Fabric Minecraft server in docker

## Build:

```
docker build -t dedlyshed-mc-server .
```

## Prerequisites

- ### For new servers:

    ```bash
    mkdir -p server-data
    ```

- ### For existing servers:

    ```bash
    mv /path/to/your/mc-1.20.1-server/* server-data/
    ```

    Edit file and configure rcon `server.properties` as follows:

    ```
    enable-rcon=true
    rcon.password=minecraft
    rcon.port=25575
    ```

    It is safe because rcon is not exposed outside of container. It is required for gracefull server shutdown and command execution via docker exec.

---

## Run:

```
docker run -d \
    --name dedlyshed-mc-server \
    --user "$(id -u):$(id -g)" \
    -e EULA=true \
    -p 25565:25565 \
    -v ./server-data:/server/data \
    dedlyshed-mc-server
```

---

## Kind of useful commands:

### Shutdown gracefully

```
docker stop dedlyshed-mc-server
```

### Shutdown gracefully as well, but inform players to GTFO

```
docker exec dedlyshed-mc-server rcon-cli --config /server/rcon.yaml "kick @a GTFO, Server is shutting down! Have a nice day!" stop
```

### Whitelist player

```
docker exec dedlyshed-mc-server rcon-cli --config /server/rcon.yaml "whitelist add Dedlyshed"
```

### OP player

```
docker exec dedlyshed-mc-server rcon-cli --config /server/rcon.yaml "op Dedlyshed"
```

With OP rights, you can shutdown gracefully as well from the game using `/stop`, container will stop, too.