# HN Story Ranker

A service that ranks Hacker News stories based on user interests using vector similarity search.

## Features

- Periodically fetches top stories from Hacker News
- Generates embeddings for stories using transformer models
- Stores story embeddings in SQLite database
- Provides an API to rank stories based on user interests
- Simple web interface for interacting with the service

## Architecture

The HN Story Ranker is a distributed system comprised of three primary components:

1. **Worker Service** (Go)
2. **API Service** (Go)
3. **Python Embedding Service** (Python)

Each component is designed to fulfill a specific role while working together to deliver the complete functionality of ranking Hacker News stories based on user interests.

### Component Details

#### 1. Worker Service (Go)

The Worker Service is responsible for data collection and preparation:

- Periodically fetches top stories from the Hacker News API
- Communicates with the Python Embedding Service to generate embeddings for each story
- Stores stories along with their vector embeddings in the SQLite database

**Implementation Choice**: We chose Go for the Worker Service due to its:
- Efficiency in handling concurrent network requests with goroutines
- Low memory footprint for a service that runs continuously
- Strong standard library for working with HTTP clients and JSON parsing
- Excellent performance for long-running background processes without garbage collection pauses

The Worker runs as a continuous process, fetching new stories every 5 minutes and processing them in a controlled manner to avoid overwhelming the embedding service.

#### 2. API Service (Go)

The API Service serves as the interface between users and the story ranking system:

- Provides HTTP endpoints for user interaction
- Serves the static web interface
- Processes user queries (bios) by generating embeddings via the Python Embedding Service
- Performs vector similarity search to find relevant stories
- Returns ranked stories to the user

**Implementation Choice**: Go was selected for the API Service because of its:
- Fast HTTP request handling capabilities
- Low latency response times
- Concurrent request handling with minimal resource usage
- Simplicity in building and deploying web servers
- Cross-platform compatibility

The API server uses the Gin web framework to provide a clean, performant interface while keeping the codebase simple and maintainable.

#### 3. Python Embedding Service

The Python Embedding Service is dedicated to generating vector embeddings:

- Provides a REST API for text embedding generation
- Uses transformer models for semantic text understanding
- Creates consistent vector representations of both stories and user bios

**Implementation Choice**: Python was the clear choice for the embedding service due to:
- Extensive ecosystem of machine learning libraries (transformers, PyTorch)
- Native support for the most advanced embedding models
- Rich tooling for text processing and natural language understanding
- Flexibility for future ML model upgrades without changing the other components
- Community support for AI/ML tasks

While Go excels at performance and concurrency, Python's mature ML ecosystem makes it the optimal choice for the embedding functionality, where we can leverage pre-trained models and fine-tune them as needed.

### Communication Flow

1. The **Worker Service** fetches stories from Hacker News API, then calls the **Python Embedding Service** to generate vectors for each story, and stores them in the database.

2. When a user provides their bio through the web interface, the **API Service** receives the request, forwards the text to the **Python Embedding Service** for embedding generation, then performs a similarity search against stored story embeddings.

3. The **API Service** returns the ranked stories to the user based on the similarity scores.

### Design Considerations

#### Polyglot Architecture

The system intentionally uses a polyglot architecture (Go + Python) to leverage the strengths of each language:

- **Go**: Efficient, concurrent system processes with low overhead
- **Python**: Rich ecosystem for ML/AI tasks with minimal development effort

This separation allows each component to be developed, scaled, and maintained independently while communicating through well-defined interfaces.

#### Modular Design

The separation of concerns between components enables:

- Independent scaling of components based on load
- Focused development teams for each component
- Flexibility to replace any component without affecting others
- Easier testing and debugging

#### Future Extensibility

The architecture supports several evolution paths:

1. Replacing the embedding implementation with more advanced models
2. Scaling the worker to process more stories or sources beyond Hacker News
3. Adding more sophisticated ranking algorithms in the API service
4. Migrating from SQLite to a dedicated vector database for larger scale deployments

## Prerequisites

- Go 1.21 or later
- Python 3.8 or later with transformers library
- SQLite database

## Environment Variables

- `SQLITE_DB_PATH`: Path to SQLite database file

## Setup & Running

1. Run the setup script to prepare your environment:
   ```bash
   ./scripts/setup.sh
   ```
   
   This script will:
   - Install Go dependencies
   - Set up a Python virtual environment and install requirements
   - Create necessary directories (data, run)
   - Create a default .env file if needed

2. Choose how to start the services based on your needs:

   **Option A: Basic Local Setup** - For development with core services only
   ```bash
   ./scripts/run-local.sh
   ```
   
   This starts:
   - API server on port 8082
   - Worker service for fetching and processing HN stories
   - Both accessible via localhost only

   **Option B: Complete Environment** - For full functionality with domain access
   ```bash
   ./scripts/start-all.sh
   ```
   
   This starts:
   - Python embedding service
   - API server and Worker service (via run-local.sh)
   - Reverse proxy for domain access
   - Makes the application available at a configured domain with both HTTP and HTTPS

3. Access the application:
   - When using run-local.sh: http://localhost:8082
   - When using start-all.sh: http://hn.cjhammons.com:90 or https://hn.cjhammons.com:150

4. To stop services:
   ```bash
   # If using run-local.sh
   ./scripts/stop-local.sh
   
   # If using start-all.sh
   ./scripts/stop-all.sh
   ```

5. View logs:
   ```bash
   # API logs
   tail -f run/api.log
   
   # Worker logs
   tail -f run/worker.log
   
   # Embedding service logs
   tail -f run/embedding.log
   ```

6. Check service status:
   ```bash
   # If using run-local.sh
   ./scripts/status-local.sh
   
   # If using start-all.sh
   ./scripts/status-all.sh
   ```

## Access

The service is accessible at:
```
https://hn.cjhammons.com
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