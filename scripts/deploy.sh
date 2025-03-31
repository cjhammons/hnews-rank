#!/bin/bash

# Exit on error
set -e

# Configuration
PROJECT_ID="rpg-vector-doc"
WORKER_REGISTRY="us-west1-docker.pkg.dev/rpg-vector-doc/hn-news-worker"
API_REGISTRY="us-west1-docker.pkg.dev/rpg-vector-doc/hn-news-api"
NAMESPACE=hn-news       
VERSION=${1:-"latest"}  # Default to latest, but allow version override

# Set Google Cloud project
echo "Setting Google Cloud project: ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}

echo "Deploying to Kubernetes cluster..."
echo "Worker Registry: ${WORKER_REGISTRY}"
echo "API Registry: ${API_REGISTRY}"
echo "Namespace: ${NAMESPACE}"
echo "Version: ${VERSION}"
echo "----------------------------------------"

# Create namespace if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Clean up any existing deployments
echo "Cleaning up existing deployments..."
kubectl delete deployment api worker -n ${NAMESPACE} --ignore-not-found

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/services.yaml -n ${NAMESPACE}

# Apply deployments with the correct version
echo "Applying deployments with version: ${VERSION}..."
if [ "$VERSION" != "latest" ]; then
    # Use sed to replace the image version in the deployment file and apply it
    sed "s|${API_REGISTRY}:latest|${API_REGISTRY}:${VERSION}|g; s|${WORKER_REGISTRY}:latest|${WORKER_REGISTRY}:${VERSION}|g" k8s/deployments.yaml | kubectl apply -f -
else
    # Use the deployment file as is
    kubectl apply -f k8s/deployments.yaml -n ${NAMESPACE}
fi

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/api -n ${NAMESPACE} || true
kubectl wait --for=condition=available --timeout=300s deployment/worker -n ${NAMESPACE} || true

# Get service information
echo "----------------------------------------"
echo "Deployment complete! Service information:"
kubectl get service api -n ${NAMESPACE} -o wide
echo "----------------------------------------"

# Get pod status
echo "Pod status:"
kubectl get pods -n ${NAMESPACE}

# Show pod logs if there are any issues
echo "----------------------------------------"
echo "Checking pod logs for any issues..."
for pod in $(kubectl get pods -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}'); do
    echo "Logs for pod: $pod"
    kubectl logs $pod -n ${NAMESPACE} --all-containers=true || true
    echo "----------------------------------------"
done 