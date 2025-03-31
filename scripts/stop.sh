#!/bin/bash

# Exit on error
set -e

echo "Stopping all services..."

echo "Checking for any processes on port 8082..."
# Find processes listening on port 8082
PORT_PIDS=$(lsof -i :8082 -t 2>/dev/null)
if [ -n "$PORT_PIDS" ]; then
    echo "Found processes still listening on port 8082. Stopping them..."
    for PID in $PORT_PIDS; do
        echo "Stopping process $PID"
        kill -15 $PID 2>/dev/null || kill -9 $PID 2>/dev/null || echo "Could not kill process $PID"
    done
    echo "Processes stopped"
else
    echo "No processes found on port 8082"
fi

# Also check port 8080 for the API server
echo "Checking for any processes on port 8080..."
PORT_PIDS=$(lsof -i :8080 -t 2>/dev/null)
if [ -n "$PORT_PIDS" ]; then
    echo "Found processes still listening on port 8080. Stopping them..."
    for PID in $PORT_PIDS; do
        echo "Stopping process $PID"
        kill -15 $PID 2>/dev/null || kill -9 $PID 2>/dev/null || echo "Could not kill process $PID"
    done
    echo "Processes stopped"
else
    echo "No processes found on port 8080"
fi

# Check port 6000 for Python embedding service
echo "Checking for any processes on port 6000..."
PORT_PIDS=$(lsof -i :6000 -t 2>/dev/null)
if [ -n "$PORT_PIDS" ]; then
    echo "Found processes still listening on port 6000. Stopping them..."
    for PID in $PORT_PIDS; do
        echo "Stopping process $PID"
        kill -15 $PID 2>/dev/null || kill -9 $PID 2>/dev/null || echo "Could not kill process $PID"
    done
    echo "Processes stopped"
else
    echo "No processes found on port 6000"
fi

# Check for any local Go processes that might be our application
echo "Checking for any running Go processes for our application..."
GO_PIDS=$(pgrep -f "go run cmd/(api|worker)/main.go" 2>/dev/null)
if [ -n "$GO_PIDS" ]; then
    echo "Found Go processes. Stopping them..."
    for PID in $GO_PIDS; do
        echo "Stopping process $PID"
        kill -15 $PID 2>/dev/null || kill -9 $PID 2>/dev/null || echo "Could not kill process $PID"
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
        kill -15 $PID 2>/dev/null || kill -9 $PID 2>/dev/null || echo "Could not kill process $PID"
    done
    echo "Python processes stopped"
else
    echo "No Python processes found"
fi

echo "All services stopped successfully!" 