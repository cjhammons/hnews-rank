#!/bin/bash

# Don't exit on error to ensure all cleanup steps are attempted
set +e

echo "Stopping all services..."

stop_port_processes() {
    local PORT=$1
    local DESCRIPTION=$2
    
    echo "Checking for any processes on port $PORT ($DESCRIPTION)..."
    # Find processes listening on the port
    PORT_PIDS=$(lsof -i :$PORT -t 2>/dev/null)
    if [ -n "$PORT_PIDS" ]; then
        echo "Found processes still listening on port $PORT. Stopping them..."
        for PID in $PORT_PIDS; do
            echo "Stopping process $PID"
            kill -15 $PID 2>/dev/null
            sleep 1
            # Check if process is still running
            if kill -0 $PID 2>/dev/null; then
                echo "Process $PID still running, forcing termination..."
                kill -9 $PID 2>/dev/null
                sleep 1
            fi
        done
        
        # Double-check if the port is really free now
        if lsof -i :$PORT -t &>/dev/null; then
            echo "WARNING: Port $PORT is still in use after kill attempts"
            echo "Attempting more aggressive termination..."
            # Try a more aggressive approach
            fuser -k $PORT/tcp 2>/dev/null
            sleep 1
        fi
        
        # Final verification
        if lsof -i :$PORT -t &>/dev/null; then
            echo "ERROR: Failed to free port $PORT. Manual intervention may be required."
            echo "You can try: sudo lsof -i :$PORT"
        else
            echo "Port $PORT is now free"
        fi
    else
        echo "No processes found on port $PORT"
    fi
}

# Stop processes on specific ports
stop_port_processes 8082 "API server"
stop_port_processes 8080 "API server"
stop_port_processes 6000 "Python embedding service"

# Check for any local Go processes that might be our application
echo "Checking for any running Go processes for our application..."
GO_PIDS=$(pgrep -f "go run cmd/(api|worker)/main.go" 2>/dev/null)
if [ -n "$GO_PIDS" ]; then
    echo "Found Go processes. Stopping them..."
    for PID in $GO_PIDS; do
        echo "Stopping process $PID"
        kill -15 $PID 2>/dev/null
        sleep 1
        kill -9 $PID 2>/dev/null 2>/dev/null || echo "Process $PID already terminated"
    done
    echo "Go processes stopped"
else
    echo "No Go processes found"
fi

# Check for Python embedding service
echo "Checking for Python embedding service..."
PYTHON_PIDS=$(pgrep -f "python(_embedding)?/app.py" 2>/dev/null)
if [ -n "$PYTHON_PIDS" ]; then
    echo "Found Python processes. Stopping them..."
    for PID in $PYTHON_PIDS; do
        echo "Stopping process $PID"
        kill -15 $PID 2>/dev/null
        sleep 1
        kill -9 $PID 2>/dev/null 2>/dev/null || echo "Process $PID already terminated"
    done
    echo "Python processes stopped"
else
    echo "No Python processes found"
fi

# Final cleanup using pkill as a last resort
echo "Performing final cleanup..."
pkill -f "go run cmd/api/main.go" 2>/dev/null || true
pkill -f "go run cmd/worker/main.go" 2>/dev/null || true
pkill -f "python(_embedding)?/app.py" 2>/dev/null || true

# One final verification for critical port 8082
if lsof -i :8082 -t &>/dev/null; then
    echo "WARNING: Port 8082 is still in use after all attempts!"
    echo "Running processes on port 8082:"
    lsof -i :8082
    echo "You may need to manually kill these processes or restart your machine."
else
    echo "Port 8082 is free"
fi

echo "All services stopped successfully!" 