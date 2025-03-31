#!/bin/bash

# Exit on error
set -e

# Configuration
PROJECT_ID="rpg-vector-doc"
WORKER_REPO="hn-news-worker"
API_REPO="hn-news-api"
LOCATION="us-west1"

echo "Verifying Google Cloud authentication and permissions..."
echo "Project: ${PROJECT_ID}"
echo "Location: ${LOCATION}"
echo "----------------------------------------"

# Check if gcloud is installed
echo "Checking gcloud installation..."
if ! command -v gcloud &> /dev/null; then
    echo "ERROR: gcloud CLI is not installed or not in PATH"
    echo "Please install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check gcloud auth status
echo "Checking authentication status..."
if ! gcloud auth list --format="value(account)" | grep -q "@"; then
    echo "ERROR: Not authenticated with Google Cloud"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Set and verify project
echo "Setting project to ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}

# Check if user has permission to use the project
echo "Verifying project access..."
if ! gcloud projects describe ${PROJECT_ID} &> /dev/null; then
    echo "ERROR: Cannot access project ${PROJECT_ID}"
    echo "Please verify you have sufficient permissions"
    exit 1
fi

# Verify repository permissions
echo "Verifying repository permissions..."

# API repository
echo "Checking API repository (${API_REPO})..."
if ! gcloud artifacts repositories describe ${API_REPO} --location=${LOCATION} &> /dev/null; then
    echo "Repository ${API_REPO} not found or no access."
    echo "Creating repository..."
    gcloud artifacts repositories create ${API_REPO} --repository-format=docker --location=${LOCATION} --description="HN News API"
fi

# Worker repository
echo "Checking worker repository (${WORKER_REPO})..."
if ! gcloud artifacts repositories describe ${WORKER_REPO} --location=${LOCATION} &> /dev/null; then
    echo "Repository ${WORKER_REPO} not found or no access."
    echo "Creating repository..."
    gcloud artifacts repositories create ${WORKER_REPO} --repository-format=docker --location=${LOCATION} --description="HN News Worker"
fi

# Test Docker authentication
echo "Testing Docker authentication to Artifact Registry..."
echo "Refreshing auth token and configuring Docker..."
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${LOCATION}-docker.pkg.dev

echo "----------------------------------------"
echo "Authentication verification completed."
echo "If all steps passed, you should be able to push to Google Cloud Artifact Registry."
echo "To deploy images, run: ./scripts/build-and-push.sh" 