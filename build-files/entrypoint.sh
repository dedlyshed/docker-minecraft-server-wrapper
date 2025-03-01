#!/bin/sh

# Function to handle signals and gracefully stop server
stop-server() {
    echo "Caught signal! Gracefully stopping server..."
    rcon-cli --config /server/rcon.yaml "kick @a GTFO, Server is shutting down! Have a nice day!" stop

    wait $JAVA_PID  # Wait for Java process to fully exit
    exit 0
}

# Trap SIGINT (Ctrl+C) and SIGTERM (kill -15)
trap stop-server SIGINT SIGTERM

echo "Ensuring essential server files are in place..."

if [ ! -f /server/data/fabric-server.jar ]; then
    echo "Restoring default fabric-server.jar..."
    cp /server/fabric-server.jar /server/data/fabric-server.jar
fi

if [ ! -f /server/data/server.properties ]; then
    echo "Restoring default server.properties..."
    cp /server/server.properties /server/data/server.properties
fi

if [ "$EULA" = "true" ]; then
    echo "eula=true" > /server/data/eula.txt
fi

nohup java -Xmx4G -jar fabric-server.jar nogui > /dev/null 2>&1 &

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