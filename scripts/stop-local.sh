#!/bin/bash

echo "Stopping locally running services..."

# Configuration
EXTERNAL_PORT=90  # Updated to port 90 for external access

# Check for PID file
if [ -f ./run/pids.txt ]; then
    # Read PIDs
    read API_PID WORKER_PID SOCAT_PID < ./run/pids.txt
    
    # Stop API service
    if [ -n "$API_PID" ]; then
        echo "Stopping API service (PID: $API_PID)..."
        kill $API_PID 2>/dev/null || true
    fi
    
    # Stop worker service
    if [ -n "$WORKER_PID" ]; then
        echo "Stopping worker service (PID: $WORKER_PID)..."
        kill $WORKER_PID 2>/dev/null || true
    fi
    
    # Stop port forwarding
    if [ -n "$SOCAT_PID" ]; then
        echo "Stopping port forwarding (PID: $SOCAT_PID)..."
        if [ $(id -u) -eq 0 ] || [ $(ps -p $SOCAT_PID -o user= 2>/dev/null) = $(whoami) ]; then
            kill $SOCAT_PID 2>/dev/null || true
        else
            echo "Port forwarding was started with sudo, stopping with sudo..."
            sudo kill $SOCAT_PID 2>/dev/null || true
        fi
    fi
    
    # Remove PID file
    rm ./run/pids.txt
else
    # Fallback to killing by process name
    echo "PID file not found, stopping processes by name..."
    pkill -f "go run ./cmd/api" || true
    pkill -f "go run ./cmd/worker" || true
    
    # Check if we need sudo for socat
    if sudo lsof -i:${EXTERNAL_PORT} | grep -q socat; then
        echo "Stopping socat with sudo..."
        sudo pkill socat || true
    else
        pkill socat || true
    fi
fi

echo "All services stopped." 