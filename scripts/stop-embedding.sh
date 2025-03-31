#!/bin/bash

echo "Stopping embedding service..."
echo "----------------------------------------"

# Check if PID file exists
if [ -f "./run/embedding.pid" ]; then
    PID=$(cat ./run/embedding.pid)
    
    # Check if process is running
    if ps -p $PID > /dev/null; then
        echo "Stopping embedding service (PID: $PID)..."
        kill $PID
    else
        echo "Process with PID $PID is not running."
    fi
    
    # Remove PID file
    rm ./run/embedding.pid
else
    # Try to find and kill by pattern if PID file doesn't exist
    echo "PID file not found, trying to stop by process pattern..."
    if pgrep -f "gunicorn --bind 0.0.0.0" > /dev/null; then
        pkill -f "gunicorn --bind 0.0.0.0"
        echo "Embedding service stopped."
    else
        echo "No embedding service found running."
    fi
fi

echo "----------------------------------------" 