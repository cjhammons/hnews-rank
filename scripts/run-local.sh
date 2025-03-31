#!/bin/bash

# Exit on error
set -e

# Configuration
API_PORT=8081
EXTERNAL_PORT=90  # Updated to port 90 for external access

echo "Setting up local environment..."
echo "API will be accessible at port ${EXTERNAL_PORT}"
echo "----------------------------------------"

# Check if required tools are installed
command -v go >/dev/null 2>&1 || { echo "Go is required but not installed. Aborting."; exit 1; }

# Clean up any previous processes
pkill -f "go run ./cmd/api" || true
pkill -f "go run ./cmd/worker" || true
sleep 1

# Create run directory for logs
mkdir -p ./run

# Start API service in background with log output
echo "Starting API service..."
nohup go run ./cmd/api > ./run/api.log 2>&1 &
API_PID=$!
echo "API service started with PID: $API_PID"

# Start worker service in background with log output
echo "Starting worker service..."
nohup go run ./cmd/worker > ./run/worker.log 2>&1 &
WORKER_PID=$!
echo "Worker service started with PID: $WORKER_PID"

# Set up port forwarding for external access
if [ $API_PORT -ne $EXTERNAL_PORT ]; then
    if [ $EXTERNAL_PORT -lt 1024 ]; then
        echo "Setting up port forwarding from ${EXTERNAL_PORT} to ${API_PORT} (requires sudo)..."
        sudo nohup socat TCP-LISTEN:${EXTERNAL_PORT},fork TCP:localhost:${API_PORT} > ./run/socat.log 2>&1 &
        SOCAT_PID=$!
        echo "Port forwarding set up with PID: $SOCAT_PID"
    else
        echo "Setting up port forwarding from ${EXTERNAL_PORT} to ${API_PORT}..."
        nohup socat TCP-LISTEN:${EXTERNAL_PORT},fork TCP:localhost:${API_PORT} > ./run/socat.log 2>&1 &
        SOCAT_PID=$!
        echo "Port forwarding set up with PID: $SOCAT_PID"
    fi
fi

# Write PIDs to file for cleanup script
echo "${API_PID} ${WORKER_PID} ${SOCAT_PID:-''}" > ./run/pids.txt

echo "----------------------------------------"
echo "Services are now running locally!"
echo "API is accessible at: http://localhost:${API_PORT} (internal)"
echo "API is accessible at: http://localhost:${EXTERNAL_PORT} (external)"
echo "External IP: $(curl -s ifconfig.me)"
echo "----------------------------------------"
echo "Live logs:"
echo "API logs: tail -f ./run/api.log"
echo "Worker logs: tail -f ./run/worker.log"
echo "----------------------------------------"
echo "To stop all services, run: ./scripts/stop-local.sh"

# Show API logs in real-time
echo "Showing API logs (Press Ctrl+C to stop viewing logs, services will continue running)..."
sleep 2
tail -f ./run/api.log 