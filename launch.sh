#!/bin/bash
cd "$(dirname "$0")"

# Kill any existing server on 8080
fuser -k 8080/tcp 2>/dev/null

# Start local server serving the Flutter web build
python3 -m http.server 8080 --directory build/web > /dev/null 2>&1 &
SERVER_PID=$!

echo "🚀 FlowMD launched at http://localhost:8080 (PID: $SERVER_PID)"
sleep 1

# Open Chrome on desktop
DISPLAY=:0 flatpak run com.google.Chrome http://localhost:8080 > /dev/null 2>&1 &

echo "App opened in Google Chrome!"
