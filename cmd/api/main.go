package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cjhammons/hacker-news-rank/internal/db"
	"github.com/cjhammons/hacker-news-rank/internal/hn"
	"github.com/cjhammons/hacker-news-rank/internal/vertex"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

// Request represents the JSON request body for the /rank endpoint.
// It contains the user's bio text that will be used for story ranking.
type Request struct {
	Bio string `json:"bio"` // User's bio text for story ranking
}

// Response represents the JSON response from the /rank endpoint.
// It contains a list of stories ranked by relevance to the user's bio.
type Response struct {
	Stories []*Story `json:"stories"` // List of ranked stories
}

// Story represents a story in the API response.
// It contains the essential information about a HN story.
type Story struct {
	ID    int    `json:"id"`    // Story ID
	Title string `json:"title"` // Story title
	URL   string `json:"url"`   // Story URL
	Score int    `json:"score"` // Story score (upvotes)
	Text  string `json:"text"`  // Story text content
}

// main starts the API server that handles story search requests.
// It initializes all necessary clients and sets up the HTTP routes.
func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: Error loading .env file: %v", err)
	}

	// Create VertexAI client
	ctx := context.Background()
	vertexClient, err := vertex.NewClient(ctx)
	if err != nil {
		log.Fatalf("Failed to create VertexAI client: %v", err)
	}
	defer vertexClient.Close()

	// Create SQLite database
	dbPath := os.Getenv("SQLITE_DB_PATH")
	if dbPath == "" {
		dbPath = "./data/stories.db"
	}
	vectorDB, err := db.NewSQLiteDB(dbPath)
	if err != nil {
		log.Fatalf("Failed to create vector database client: %v", err)
	}
	defer vectorDB.Close()

	// Create HackerNews client
	hnClient := hn.NewClient()

	// Create Gin router
	router := gin.Default()

	// Add CORS middleware
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// Define routes
	router.GET("/search", func(c *gin.Context) {
		query := c.Query("q")
		if query == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Query parameter 'q' is required"})
			return
		}

		// Generate embedding for the query
		embedding, err := vertexClient.GenerateEmbedding(c.Request.Context(), query)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate embedding"})
			return
		}

		// Search for similar stories
		stories, err := vectorDB.SearchSimilarStories(c.Request.Context(), embedding, 10)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search stories"})
			return
		}

		c.JSON(http.StatusOK, stories)
	})

	// Start server
	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	// Graceful shutdown
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan

		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if err := srv.Shutdown(shutdownCtx); err != nil {
			log.Printf("Server forced to shutdown: %v", err)
		}
	}()

	log.Println("Server starting on :8080")
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatalf("Server failed: %v", err)
	}
}

// handleRank creates an HTTP handler for the /rank endpoint.
// It processes user bios, generates embeddings, and finds similar stories.
// Returns an http.HandlerFunc that handles the ranking request.
func handleRank(vertexClient *vertex.Client, vectorDB db.VectorDB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req Request
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Generate embedding for user's bio
		embedding, err := vertexClient.GenerateEmbedding(r.Context(), req.Bio)
		if err != nil {
			log.Printf("Error generating embedding: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		// Search for similar stories
		stories, err := vectorDB.SearchSimilarStories(r.Context(), embedding, 500)
		if err != nil {
			log.Printf("Error searching stories: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		// Convert stories to response format
		resp := Response{
			Stories: make([]*Story, len(stories)),
		}

		for i, story := range stories {
			resp.Stories[i] = &Story{
				ID:    story.ID,
				Title: story.Title,
				URL:   story.URL,
				Score: story.Score,
				Text:  story.Text,
			}
		}

		// Send response
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(resp); err != nil {
			log.Printf("Error encoding response: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
	}
}
