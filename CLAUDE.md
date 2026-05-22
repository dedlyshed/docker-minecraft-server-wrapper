# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A minimal Docker wrapper for running Minecraft servers in containerized environments (e.g., Kubernetes homelab). The entire logic lives in two files: `Dockerfile` and `build-files/entrypoint.sh`.

## Build

```bash
docker build \
  -t dedlyshed-mc-server \
  -t ghcr.io/dedlyshed/dedlyshed-mc-server:1.1 \
  -t ghcr.io/dedlyshed/dedlyshed-mc-server:latest \
  .
```

## Run (for local testing)

```bash
mkdir -p server-data
wget -O ./server-data/mc-server.jar <jar-url>

docker run -d \
    --name dedlyshed-mc-server \
    --user "$(id -u):$(id -g)" \
    -e EULA=true \
    -p 25565:25565 \
    -v ./server-data:/server/data \
    dedlyshed-mc-server
```

## Architecture

- **`Dockerfile`** — based on `eclipse-temurin:21-jdk-alpine`. Downloads `rcon-cli` v0.10.3 at build time, copies `build-files/` to `/server/`, and uses `entrypoint.sh` as the entrypoint. The default `CMD` passes JVM args and `mc-server.jar`; users can override these entirely for modded servers.

- **`build-files/entrypoint.sh`** — the wrapper's core. On startup it:
  1. Writes an `rcon.yaml` config from env vars (`RCON_PORT`, `RCON_PASSWORD`).
  2. Patches `server.properties` via `awk` — **enforcing** `enable-rcon`, `rcon.port`, and `rcon.password` (overwriting existing values), and **defaulting** `server-port` and `server-ip` only if absent.
  3. Validates `EULA=true` and writes `eula.txt`.
  4. Starts the Java process in the background, traps `SIGINT`/`SIGTERM`, and on signal kicks all players then runs `stop` via RCON before waiting for the JVM to exit.

## Key environment variables

| Variable | Default | Notes |
|---|---|---|
| `EULA` | *(required)* | Must be `true` |
| `RCON_PORT` | `25575` | Not exposed outside container |
| `RCON_PASSWORD` | `changeme_in_production` | Internal only |
| `SERVER_PORT` | `25565` | Only set in properties if missing |
| `SERVER_IP` | *(empty)* | Bind address; empty = all interfaces |

## Sending commands / useful operations

```bash
# Run a Minecraft command
docker exec dedlyshed-mc-server rcon-cli --config /server/data/rcon.yaml "<command>"

# Graceful shutdown
docker stop dedlyshed-mc-server
```

## Publish

```bash
docker tag ghcr.io/dedlyshed/dedlyshed-mc-server:1.1 ghcr.io/dedlyshed/dedlyshed-mc-server:latest

export CR_PAT='<token>'
echo "$CR_PAT" | docker login ghcr.io -u dedlyshed --password-stdin

docker push ghcr.io/dedlyshed/dedlyshed-mc-server:1.1
docker push ghcr.io/dedlyshed/dedlyshed-mc-server:latest
```
