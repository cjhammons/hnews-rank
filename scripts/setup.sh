#!/bin/bash

# Exit on error
set -e

echo "Setting up HN Story Ranker environment..."

# Create necessary directories
mkdir -p data
mkdir -p run

# Install Go dependencies
echo "Installing Go dependencies..."
go mod download
go mod tidy

# Set up Python environment
echo "Setting up Python environment..."
if [ ! -d "python_embedding/venv" ]; then
    echo "Creating Python virtual environment..."
    cd python_embedding
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
    echo "Python environment set up successfully."
else
    echo "Python virtual environment already exists."
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    echo "# Database Configuration" > .env
    echo "SQLITE_DB_PATH=./data/stories.db" >> .env
    echo ".env file created."
else
    echo ".env file already exists."
fi

echo "Setup completed successfully!"
echo "To run the application, use: ./scripts/run.sh" 