#!/bin/bash

# Exit on error
set -e

# Configuration
PROJECT_ID="rpg-vector-doc"
WORKER_REGISTRY="us-west1-docker.pkg.dev/rpg-vector-doc/hn-news-worker"
API_REGISTRY="us-west1-docker.pkg.dev/rpg-vector-doc/hn-news-api"
VERSION=$(git rev-parse --short HEAD)

# Default image names
WORKER_IMAGE="hn-news-worker"
API_IMAGE="hn-news-api"

# Set Google Cloud project
echo "Setting Google Cloud project: ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}

# Refresh Google Cloud authentication
echo "Refreshing Google Cloud authentication..."
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us-west1-docker.pkg.dev

echo "Building and pushing images to Google Cloud..."
echo "Worker Registry: ${WORKER_REGISTRY}"
echo "API Registry: ${API_REGISTRY}"
echo "Version: ${VERSION}"
echo "----------------------------------------"

# Create repositories if they don't exist
echo "Ensuring repositories exist..."
gcloud artifacts repositories describe hn-news-api --location=us-west1 > /dev/null 2>&1 || \
  gcloud artifacts repositories create hn-news-api --repository-format=docker --location=us-west1 --description="HN News API"

gcloud artifacts repositories describe hn-news-worker --location=us-west1 > /dev/null 2>&1 || \
  gcloud artifacts repositories create hn-news-worker --repository-format=docker --location=us-west1 --description="HN News Worker"

# Build API
echo "Building Docker image: ${API_IMAGE} using Dockerfile..."
docker build -t ${API_REGISTRY}:${VERSION} -f Dockerfile .
docker tag ${API_REGISTRY}:${VERSION} ${API_REGISTRY}:latest

echo "Pushing API image to Google Cloud..."
# Retry mechanism for push
for i in {1..3}; do
  echo "Push attempt $i for API image..."
  if docker push ${API_REGISTRY}:${VERSION} && docker push ${API_REGISTRY}:latest; then
    echo "Successfully pushed ${API_IMAGE}"
    break
  elif [ $i -eq 3 ]; then
    echo "Failed to push ${API_IMAGE} after 3 attempts. Check your network connection and permissions."
    exit 1
  else
    echo "Push failed, retrying in 5 seconds..."
    sleep 5
  fi
done
echo "----------------------------------------"

# Build worker
echo "Building Docker image: ${WORKER_IMAGE} using Dockerfile.worker..."
docker build -t ${WORKER_REGISTRY}:${VERSION} -f Dockerfile.worker .
docker tag ${WORKER_REGISTRY}:${VERSION} ${WORKER_REGISTRY}:latest

echo "Pushing worker image to Google Cloud..."
# Retry mechanism for push
for i in {1..3}; do
  echo "Push attempt $i for worker image..."
  if docker push ${WORKER_REGISTRY}:${VERSION} && docker push ${WORKER_REGISTRY}:latest; then
    echo "Successfully pushed ${WORKER_IMAGE}"
    break
  elif [ $i -eq 3 ]; then
    echo "Failed to push ${WORKER_IMAGE} after 3 attempts. Check your network connection and permissions."
    exit 1
  else
    echo "Push failed, retrying in 5 seconds..."
    sleep 5
  fi
done
echo "----------------------------------------"

echo "All images built and pushed successfully. You can now deploy to Kubernetes:"
echo "./scripts/deploy.sh"

# Verify the pushed images are accessible
echo "Verifying pushed images..."
gcloud artifacts docker images list ${API_REGISTRY} --include-tags
gcloud artifacts docker images list ${WORKER_REGISTRY} --include-tags 