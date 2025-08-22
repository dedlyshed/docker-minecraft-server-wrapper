#!/bin/sh

set -Eeuo pipefail 

echo "[Server wrapper] Starting wrapper."

SERVER_DATA_DIR="/server/data"
SERVER_PROPERTIES_FILE="server.properties"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-changeme_in_production}"
RCON_CONFIG_FILE="rcon.yaml"
SERVER_PORT="${SERVER_PORT:-25565}"
SERVER_IP="${SERVER_IP:-}" # Default is empty (bind to all interfaces)
JAVA_PID=0 # define globally

mkdir -p "$SERVER_DATA_DIR"
cd "$SERVER_DATA_DIR"

echo "[Server wrapper] Applying configuration..."

cat > "$RCON_CONFIG_FILE" <<EOF
default:
  address: "localhost:$RCON_PORT"
  password: "$RCON_PASSWORD"
  log: "rcon-default.log"
  timeout: "10s"
EOF

if [ ! -f "$SERVER_PROPERTIES_FILE" ]; then
    echo "[Server wrapper] No Minecraft server properties file found, generating a new one..."
    echo "# Minecraft server properties - Generated on $(date)" > "$SERVER_PROPERTIES_FILE"
fi

echo "[Server wrapper] Ensuring correct parameters in server properties file..."

awk -v rcon_port="$RCON_PORT" \
    -v rcon_pass="$RCON_PASSWORD" \
    -v srv_port="$SERVER_PORT" \
    -v srv_ip="$SERVER_IP" '
BEGIN {
    FS=OFS="=";
    
    # List of settings to ENFORCE
    enforce["enable-rcon"] = "true";
    enforce["rcon.port"] = rcon_port;
    enforce["rcon.password"] = rcon_pass;

    # List of settings to DEFAULT if missing
    defaults["server-port"] = srv_port;
    defaults["server-ip"] = srv_ip;
}
{
    # Trim whitespace from the key for robust matching
    key = $1;
    gsub(/^[ \t]+|[ \t]+$/, "", key);

    # If the key is one we want to enforce, print our version and remove from the list
    if (key in enforce) {
        print key, enforce[key];
        delete enforce[key];
        # Also remove from defaults list in case it overlaps
        if (key in defaults) delete defaults[key]; 
    }
    # If the key is one we want to default, just remove it from the list and print the original line
    else if (key in defaults) {
        delete defaults[key];
        print $0;
    }
    # Otherwise, it is an unrelated key, so just print the original line
    else {
        print $0;
    }
}
END {
    # After checking all lines, add any ENFORCED settings that were missing
    for (key in enforce) {
        print key, enforce[key];
    }
    # Add any DEFAULT settings that were missing
    for (key in defaults) {
        print key, defaults[key];
    }
}' "$SERVER_PROPERTIES_FILE" > "${SERVER_PROPERTIES_FILE}.tmp" && mv "${SERVER_PROPERTIES_FILE}.tmp" "$SERVER_PROPERTIES_FILE"

if [ "${EULA:-false}" != "true" ]; then
    echo >&2 "[Server wrapper] ERROR: You must accept the Minecraft EULA to run the server."
    echo >&2 "[Server wrapper] Please set the environment variable EULA=true to indicate your agreement."
    exit 1
fi

echo "[Server wrapper] EULA accepted. Creating eula.txt file..."
echo "eula=true" > "eula.txt"

# Function to handle signals and gracefully stop server
stop-server() {
    echo "[Server wrapper] Caught signal! Gracefully stopping server..."
    rcon-cli --config "$RCON_CONFIG_FILE" "kick @a GTFO, Server is shutting down! Have a nice day!" stop

    wait $JAVA_PID  # Wait for Java process to fully exit
    echo "[Server wrapper] Shutdown complete."
    exit 0
}

# Trap SIGINT (Ctrl+C) and SIGTERM (kill -15)
trap stop-server SIGINT SIGTERM

echo "[Server wrapper] Starting server with params: $@"

java "$@" &

# Get the Java process PID
JAVA_PID=$!

echo "[Server wrapper] Minecraft server (PID: $JAVA_PID) is now running!"

# Keep script alive to handle termination signals properly
wait $JAVA_PID

# When Java process exits (manually via rcon, in-game comamand or crash), stop tail to let the container exit properly
echo "[Server wrapper] Minecraft server process has stopped. Exiting wrapper."