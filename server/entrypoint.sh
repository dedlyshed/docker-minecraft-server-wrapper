#!/bin/sh

# Name of the screen session
SCREEN_NAME="mcserver"

# Function to handle SIGTERM (graceful shutdown)
handle_sigterm() {
    echo "SIGTERM received! Stopping Minecraft server..."
    screen -S "$SCREEN_NAME" -X stuff "stop$(printf \\r)"  # Send "/stop" to Minecraft
    sleep 5  # Give time for shutdown
    exit 0
}

# Trap SIGTERM and call handle_sigterm
trap handle_sigterm SIGTERM

# Start a new screen session with a pseudo-TTY
echo "Starting Minecraft server in screen session: $SCREEN_NAME"
screen -L -Logfile /server/mc.log -dmS "$SCREEN_NAME" sh -c 'java -Xmx2G -jar fabric-server.jar nogui'

# Keep container running by tailing the log
tail -f /server/mc.log
