#!/bin/bash

# Set the port
PORT=${EMBEDDING_PORT:-6000}

# Check if venv is available
if [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Check if requirements are installed
if ! python -c "import transformers" &>/dev/null; then
    echo "Installing requirements..."
    pip install -r requirements.txt
fi

# Start the Flask app
echo "Starting embedding service on port $PORT..."
if command -v gunicorn &>/dev/null; then
    # Start with gunicorn if available
    echo "Using gunicorn server..."
    gunicorn --bind 0.0.0.0:$PORT app:app --workers 1 --timeout 120
else
    # Fall back to Flask development server
    echo "Using Flask development server..."
    export FLASK_APP=app.py
    export PORT=$PORT
    python app.py
fi 