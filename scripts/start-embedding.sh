#!/bin/bash

# Exit on error
set -e

# Configuration
EMBEDDING_PORT=6000

echo "Starting embedding service..."
echo "----------------------------------------"

# Check if required tools are installed
command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required but not installed. Aborting."; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "pip3 is required but not installed. Aborting."; exit 1; }

# Create run directory for logs
mkdir -p ./run

# Check if we need to install dependencies
if [ ! -d "python_embedding/venv" ]; then
    echo "Setting up Python virtual environment and installing dependencies..."
    cd python_embedding
    python3 -m venv venv
    source venv/bin/activate
    pip3 install -r requirements.txt
    deactivate
    cd ..
fi

# Make sure start.sh is executable
chmod +x python_embedding/start.sh

# Check if service is already running
if pgrep -f "gunicorn --bind 0.0.0.0:$EMBEDDING_PORT app:app" > /dev/null; then
    echo "Embedding service is already running. Stopping it first..."
    pkill -f "gunicorn --bind 0.0.0.0:$EMBEDDING_PORT app:app" || true
    sleep 2
fi

# Start embedding service in background
echo "Starting embedding service on port $EMBEDDING_PORT..."
cd python_embedding
source venv/bin/activate
export EMBEDDING_PORT=$EMBEDDING_PORT
nohup ./start.sh > ../run/embedding.log 2>&1 &
EMBEDDING_PID=$!
cd ..

echo "Embedding service started with PID: $EMBEDDING_PID"
echo "$EMBEDDING_PID" > ./run/embedding.pid

echo "----------------------------------------"
echo "Embedding service is now running!"
echo "Service is accessible at: http://localhost:$EMBEDDING_PORT"
echo "----------------------------------------"
echo "To stop the service: ./scripts/stop-embedding.sh"
echo "To view logs: tail -f ./run/embedding.log" 