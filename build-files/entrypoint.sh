#!/bin/sh

SERVER_PROPERTIES="/server/data/server.properties"

# Function to handle signals and gracefully stop server
stop-server() {
    echo "Caught signal! Gracefully stopping server..."
    rcon-cli --config /server/rcon.yaml "kick @a GTFO, Server is shutting down! Have a nice day!" stop

    wait $JAVA_PID  # Wait for Java process to fully exit
    exit 0
}

# Trap SIGINT (Ctrl+C) and SIGTERM (kill -15)
trap stop-server SIGINT SIGTERM

if [ ! -f "$SERVER_PROPERTIES" ]; then
    echo "Restoring default server.properties..."
    cp /server/server.properties "$SERVER_PROPERTIES"
fi

# In case importing existing server, this will overwrite rcon settings
awk -F= '
BEGIN {
    updated["enable-rcon"] = "true";
    updated["rcon.password"] = "minecraft";
    updated["rcon.port"] = "25575";
}
{
    key = $1;
    if (key in updated) {
        print key "=" updated[key];
        delete updated[key];  # Remove from the update list once modified
    } else {
        print $0;
    }
}
END {
    for (key in updated) print key "=" updated[key];  # Append missing keys
}' "$SERVER_PROPERTIES" > temp && mv temp "$SERVER_PROPERTIES"

if [ "$EULA" = "true" ]; then
    echo "eula=true" > /server/data/eula.txt
fi

echo "Starting server with params: $@"

nohup java "$@" > /dev/null 2>&1 &

# Get the Java process PID
JAVA_PID=$!

echo "Minecraft server (PID: $JAVA_PID) is now running!"

# Wait for log file to be created
while [ ! -f /server/data/logs/latest.log ]; do
    sleep 1
done

# Tail logs in the background so they are visible in `docker logs`
tail -F /server/data/logs/latest.log &

# Keep script alive to handle termination signals properly
wait $JAVA_PID

# When Java process exits (manually via rcon, in-game comamand or crash), stop tail to let the container exit properly
echo "Minecraft server has stopped. Exiting..."
kill %1 2>/dev/null  # Kill tail process if still running