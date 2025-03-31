#!/bin/bash

# Set the port
PORT=${EMBEDDING_PORT:-5000}

# Start the Flask app with gunicorn
echo "Starting embedding service on port $PORT..."
gunicorn --bind 0.0.0.0:$PORT app:app --workers 1 --timeout 120 