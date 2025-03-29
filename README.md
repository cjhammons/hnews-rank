# HN Story Ranker

A service that ranks Hacker News stories based on user interests using vector similarity search.

## Features

- Periodically fetches top stories from Hacker News
- Generates embeddings for stories using Google's VertexAI
- Stores story embeddings in Milvus vector database
- Provides an API to rank stories based on user interests
- Simple web interface for interacting with the service

## Architecture

The service consists of two main components:

1. **Worker**: A background process that:
   - Fetches top stories from Hacker News every 5 minutes
   - Generates embeddings for each story using VertexAI
   - Stores stories and their embeddings in Milvus

2. **API Server**: An HTTP server that:
   - Serves a web interface for users to input their bio
   - Generates embeddings for user bios
   - Finds similar stories using vector similarity search
   - Returns ranked stories to the user

## Prerequisites

- Go 1.21 or later
- Google Cloud Platform account with VertexAI enabled
- Milvus vector database instance
- Kubernetes cluster (for deployment)

## Environment Variables

- `VERTEX_AI_PROJECT`: GCP project ID
- `VERTEX_AI_LOCATION`: GCP region for VertexAI
- `VECTOR_DB_URL`: Milvus server URL

## Development

1. Install dependencies:
   ```bash
   go mod download
   ```

2. Run the worker:
   ```bash
   go run cmd/worker/main.go
   ```

3. Run the API server:
   ```bash
   go run cmd/api/main.go
   ```

4. Visit http://localhost:8080 in your browser

## Deployment

1. Build the Docker image:
   ```bash
   docker build -t hn-rank:latest .
   ```

2. Deploy to Kubernetes:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```

3. Create a secret with your credentials:
   ```bash
   kubectl create secret generic hn-rank-secrets \
     --from-literal=vertex-ai-project=your-project \
     --from-literal=vertex-ai-location=your-location \
     --from-literal=vector-db-url=your-milvus-url
   ```

## API

### POST /rank

Request:
```json
{
  "bio": "Your bio here..."
}
```

Response:
```json
{
  "stories": [
    {
      "id": 123,
      "title": "Story Title",
      "url": "https://example.com",
      "score": 100,
      "text": "Story text..."
    }
  ]
}
```

## License

MIT 