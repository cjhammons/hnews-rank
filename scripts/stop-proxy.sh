#!/bin/bash

echo "Stopping Caddy reverse proxy..."

# Check for PID file
if [ -f ./run/caddy.pid ]; then
    # Read PID
    CADDY_PID=$(cat ./run/caddy.pid)
    
    # Stop Caddy
    if [ -n "$CADDY_PID" ]; then
        echo "Stopping Caddy (PID: $CADDY_PID)..."
        kill $CADDY_PID 2>/dev/null || true
    fi
    
    # Remove PID file
    rm ./run/caddy.pid
else
    # Fallback to killing by process name
    echo "PID file not found, stopping processes by name..."
    pkill caddy || true
fi

echo "Caddy reverse proxy stopped." 