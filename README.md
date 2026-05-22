# Minecraft Server wrapper in docker

## Purpose

I made this wrapper to run my different Minecraft servers in my homelab Kubernetes cluster; therefore, it requires a Docker container as a wrapper. The main advantages are: lightweight, graceful shutdown on `docker stop` or CTRL+C, executing Minecraft commands via `docker exec`, and a built-in `backup` command for world archiving with optional S3 upload.

## Pull

```bash
docker pull ghcr.io/dedlyshed/dedlyshed-mc-server:1.2
```

## Build

```bash
docker buildx build \
  -t dedlyshed-mc-server \
  -t ghcr.io/dedlyshed/dedlyshed-mc-server:1.2 \
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
docker tag ghcr.io/dedlyshed/dedlyshed-mc-server:1.2 ghcr.io/dedlyshed/dedlyshed-mc-server:latest

export CR_PAT='<your_token_here>'
echo "$CR_PAT" | docker login ghcr.io -u dedlyshed --password-stdin

docker push ghcr.io/dedlyshed/dedlyshed-mc-server:1.2
docker push ghcr.io/dedlyshed/dedlyshed-mc-server:latest
```

## Backup

Run a one-shot backup by passing `backup` as the command. Designed to be used as a K8s CronJob against the same data volume as the server.

### Example 1: Local backup only

```bash
docker run -d --rm \
    --name mc-backup \
    --user "$(id -u):$(id -g)" \
    -e BACKUP_ID=survival \
    -e BACKUP_RETAIN=7 \
    -v ./server-data:/server/data \
    ghcr.io/dedlyshed/dedlyshed-mc-server:latest \
    backup

docker logs -f mc-backup
```

### Example 2: Backup with S3 upload

```bash
docker run -d --rm \
    --name mc-backup \
    --user "$(id -u):$(id -g)" \
    -e BACKUP_ID=my-server \
    -e S3_UPLOAD=true \
    -e S3_BUCKET=my-mc-backups \
    -e S3_ENDPOINT=https://s3.example.com \
    -e AWS_ACCESS_KEY_ID=<key> \
    -e AWS_SECRET_ACCESS_KEY=<secret> \
    -e AWS_REGION=us-east-1 \
    -v ./server-data:/server/data \
    ghcr.io/dedlyshed/dedlyshed-mc-server:latest \
    backup

docker logs -f mc-backup
```

Creates `<BACKUP_ID>-YYYYMMDD-HHMMSS.tar.gz` in `BACKUP_DIR`, then rotates old archives (scoped to `BACKUP_ID`). If `S3_UPLOAD=true`, uploads via [s5cmd](https://github.com/peak/s5cmd) and applies the same rotation to the bucket.

| Variable | Default | |
|---|---|---|
| `BACKUP_DIR` | `/server/data/backups` | Mount a dedicated PVC in K8s |
| `BACKUP_ID` | world name | Scope rotation when sharing a dir/bucket |
| `BACKUP_RETAIN` | `7` | Archives to keep locally and in S3 |
| `S3_UPLOAD` | `false` | Set `true` to enable upload |
| `S3_BUCKET` | — | Required when uploading |
| `S3_PREFIX` | `backups/` | Key prefix in the bucket |
| `S3_ENDPOINT` | — | For MinIO / R2 / non-AWS S3 |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` | — | Standard AWS env vars |


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