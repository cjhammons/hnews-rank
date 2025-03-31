#!/bin/bash

echo "Checking status of embedding service..."
echo "----------------------------------------"

EMBEDDING_PORT=6000

# Check if PID file exists
if [ -f "./run/embedding.pid" ]; then
    PID=$(cat ./run/embedding.pid)
    
    # Check if process is running
    if ps -p $PID > /dev/null; then
        echo "✅ Embedding service is running (PID: $PID)"
        
        # Check if the service is responding
        if curl -s http://localhost:$EMBEDDING_PORT/health | grep -q "ok"; then
            echo "✅ Embedding service health check passed"
        else
            echo "❌ Embedding service health check failed! Service may be starting up or having issues."
        fi
    else
        echo "❌ Embedding service is NOT running (PID: $PID not found)"
    fi
else
    # Try to find by pattern if PID file doesn't exist
    PID=$(pgrep -f "gunicorn --bind 0.0.0.0:$EMBEDDING_PORT app:app" 2>/dev/null)
    if [ -n "$PID" ]; then
        echo "✅ Embedding service is running (PID: $PID, no PID file)"
        # Check if the service is responding
        if curl -s http://localhost:$EMBEDDING_PORT/health | grep -q "ok"; then
            echo "✅ Embedding service health check passed"
        else
            echo "❌ Embedding service health check failed! Service may be starting up or having issues."
        fi
    else
        echo "❌ Embedding service is NOT running"
    fi
fi

echo "----------------------------------------"
echo "Log file: ./run/embedding.log"
echo "----------------------------------------"
echo "To start embedding service: ./scripts/start-embedding.sh"
echo "To stop embedding service:  ./scripts/stop-embedding.sh" 