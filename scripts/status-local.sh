#!/bin/bash

echo "Checking status of locally running services..."
echo "----------------------------------------"

API_PORT=8080
EXTERNAL_PORT=90  # Updated to port 90 for external access

# Check API service
if pgrep -f "go run ./cmd/api" > /dev/null; then
    API_PID=$(pgrep -f "go run ./cmd/api")
    echo "✅ API service is running (PID: $API_PID)"
    
    # Check if API is actually responding
    if curl -s http://localhost:${API_PORT}/health 2>&1 | grep -q "ok"; then
        echo "   API health check: OK"
    else
        echo "❌ API health check failed! Service may be starting up or having issues."
        echo "   Check logs: tail -f ./run/api.log"
    fi
else
    echo "❌ API service is NOT running"
fi

# Check worker service
if pgrep -f "go run ./cmd/worker" > /dev/null; then
    WORKER_PID=$(pgrep -f "go run ./cmd/worker")
    echo "✅ Worker service is running (PID: $WORKER_PID)"
else
    echo "❌ Worker service is NOT running"
fi

# Check port forwarding
if lsof -i:${EXTERNAL_PORT} | grep -q socat; then
    SOCAT_PID=$(lsof -i:${EXTERNAL_PORT} | grep socat | awk '{print $2}')
    echo "✅ Port forwarding is active (PID: $SOCAT_PID)"
    EXTERNAL_IP=$(curl -s ifconfig.me)
    echo "   External access URL: http://${EXTERNAL_IP}:${EXTERNAL_PORT}"
else
    echo "❌ Port forwarding is NOT active (port ${EXTERNAL_PORT})"
    if sudo lsof -i:${EXTERNAL_PORT} 2>/dev/null | grep -q "."; then
        echo "   Note: Port ${EXTERNAL_PORT} is in use by another application"
    fi
fi

echo "----------------------------------------"
echo "Log file locations:"
echo "API logs:    ./run/api.log"
echo "Worker logs: ./run/worker.log"
echo "----------------------------------------"
echo "To restart all services: ./scripts/run-local.sh"
echo "To stop all services:    ./scripts/stop-local.sh" 