#!/bin/bash

# Exit on error
set -e

check_port() {
    local PORT=$1
    local DESCRIPTION=$2
    echo "Checking if port $PORT ($DESCRIPTION) is available..."
    
    if lsof -i :$PORT -t &>/dev/null; then
        echo "Error: Port $PORT is already in use."
        echo "Running processes on port $PORT:"
        lsof -i :$PORT
        echo "Run './scripts/stop.sh' first or use './scripts/run.sh clean'"
        return 1
    fi
    echo "Port $PORT is available"
    return 0
}

# Check if we need to stop existing instances first
if [ "$1" == "clean" ]; then
    echo "Stopping any existing services..."
    ./scripts/stop.sh
fi

# Check if critical ports are already in use
check_port 8082 "API server" || exit 1
check_port 8080 "Web server" || exit 1
check_port 6000 "Python embedding service" || exit 1

# Create required directories
mkdir -p ./data
mkdir -p ./run

# Start Python embedding service
echo "Starting Python embedding service..."
if [ -d "python_embedding/venv" ]; then
    (cd python_embedding && source venv/bin/activate && python app.py > ../run/embedding.log 2>&1) &
    EMBEDDING_PID=$!
    echo "Python embedding service started on port 6000 (PID: $EMBEDDING_PID)"
else
    echo "Error: Python virtual environment not found. Please set it up first:"
    echo "cd python_embedding && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    echo "Or simply run: ./scripts/setup.sh"
    exit 1
fi

# Wait for embedding service to start
echo "Waiting for embedding service to start..."
for i in {1..10}; do
    if curl -s http://localhost:6000/health &>/dev/null; then
        echo "Embedding service is responsive!"
        break
    fi
    
    if [ $i -eq 10 ]; then
        echo "WARNING: Embedding service did not respond in time, but continuing anyway..."
    else
        echo "Waiting for embedding service... (attempt $i/10)"
        sleep 1
    fi
done

# Start Worker
echo "Starting Worker service..."
go run cmd/worker/main.go > run/worker.log 2>&1 &
WORKER_PID=$!
echo "Worker service started (PID: $WORKER_PID)"

# Start API server
echo "Starting API server..."
go run cmd/api/main.go > run/api.log 2>&1 &
API_PID=$!
echo "API server started on port 8082 (PID: $API_PID)"

# Wait a moment to see if the API starts successfully
sleep 2
if ! ps -p $API_PID > /dev/null; then
    echo "ERROR: API server process exited immediately. Check logs for details:"
    tail -n 20 run/api.log
    echo "Stopping other services..."
    kill $WORKER_PID $EMBEDDING_PID 2>/dev/null || true
    exit 1
fi

echo "----------------------------------------"
echo "All services started successfully!"
echo "  API server: http://localhost:8082"
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
echo "  Embedding service: $EMBEDDING_PID" 