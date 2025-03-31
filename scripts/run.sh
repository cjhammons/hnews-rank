#!/bin/bash

# Exit on error
set -e

# Check if we need to stop existing instances first
if [ "$1" == "clean" ]; then
    echo "Stopping any existing services..."
    ./scripts/stop.sh
fi

# Check if ports are already in use
if lsof -i :8082 -t &>/dev/null; then
    echo "Error: Port 8082 is already in use. Run ./scripts/stop.sh first or use './scripts/run.sh clean'"
    exit 1
fi

if lsof -i :8080 -t &>/dev/null; then
    echo "Error: Port 8080 is already in use. Run ./scripts/stop.sh first or use './scripts/run.sh clean'"
    exit 1
fi

if lsof -i :6000 -t &>/dev/null; then
    echo "Error: Port 6000 is already in use. Run ./scripts/stop.sh first or use './scripts/run.sh clean'"
    exit 1
fi

# Create data directory if it doesn't exist
mkdir -p ./data

# Start Python embedding service
echo "Starting Python embedding service..."
if [ -d "python_embedding/venv" ]; then
    (cd python_embedding && source venv/bin/activate && python app.py > ../run/embedding.log 2>&1) &
    echo "Python embedding service started on port 6000"
else
    echo "Error: Python virtual environment not found. Please set it up first:"
    echo "cd python_embedding && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Wait for embedding service to start
echo "Waiting for embedding service to start..."
sleep 3

# Start Worker
echo "Starting Worker service..."
mkdir -p run
go run cmd/worker/main.go > run/worker.log 2>&1 &
WORKER_PID=$!
echo "Worker service started (PID: $WORKER_PID)"

# Start API server
echo "Starting API server..."
go run cmd/api/main.go > run/api.log 2>&1 &
API_PID=$!
echo "API server started on port 8080 (PID: $API_PID)"

echo "----------------------------------------"
echo "All services started successfully!"
echo "  API server: http://localhost:8080"
echo "  Embedding service: http://localhost:6000"
echo ""
echo "To view logs:"
echo "  API logs: tail -f run/api.log"
echo "  Worker logs: tail -f run/worker.log"
echo "  Embedding logs: tail -f run/embedding.log"
echo ""
echo "To stop all services:"
echo "  ./scripts/stop.sh"
echo ""
echo "PIDs for reference:"
echo "  API server: $API_PID"
echo "  Worker: $WORKER_PID"
ps aux | grep -E "python app.py|python_embedding" | grep -v grep 