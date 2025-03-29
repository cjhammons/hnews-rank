package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/cjhammons/hacker-news-rank/internal/db"
	"github.com/cjhammons/hacker-news-rank/internal/hn"
	"github.com/cjhammons/hacker-news-rank/internal/vertex"
	"github.com/joho/godotenv"
)

// main starts the background worker that processes HN stories.
// It initializes all necessary clients and runs the processing loop.
func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: Error loading .env file: %v", err)
	}

	ctx := context.Background()

	// Initialize clients
	hnClient := hn.NewClient()
	vertexClient, err := vertex.NewClient(ctx)
	if err != nil {
		log.Fatalf("Failed to create VertexAI client: %v", err)
	}
	defer vertexClient.Close()

	dbPath := os.Getenv("SQLITE_DB_PATH")
	if dbPath == "" {
		dbPath = "./data/stories.db"
	}
	vectorDB, err := db.NewSQLiteDB(dbPath)
	if err != nil {
		log.Fatalf("Failed to create vector database client: %v", err)
	}
	defer vectorDB.Close()

	// Run the worker loop
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		if err := processStories(ctx, hnClient, vertexClient, vectorDB); err != nil {
			log.Printf("Error processing stories: %v", err)
		}

		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			continue
		}
	}
}

// processStories handles the main processing loop for HN stories.
// It fetches top stories, generates embeddings, and stores them in the vector database.
// Returns any error encountered during processing.
func processStories(ctx context.Context, hnClient hn.Client, vertexClient *vertex.Client, vectorDB db.VectorDB) error {
	// Get top stories
	storyIDs, err := hnClient.GetTopStories()
	if err != nil {
		return err
	}

	// Process each story
	for _, id := range storyIDs {
		story, err := hnClient.GetStory(id)
		if err != nil {
			log.Printf("Error fetching story %d: %v", id, err)
			continue
		}

		// Skip non-story items
		if story.Type != "story" {
			continue
		}

		// Generate embedding
		text := story.Title
		if story.Text != "" {
			text += " " + story.Text
		}

		embedding, err := vertexClient.GenerateEmbedding(ctx, text)
		if err != nil {
			log.Printf("Error generating embedding for story %d: %v", id, err)
			continue
		}

		// Store in vector database
		storyWithEmbedding := &hn.StoryWithEmbedding{
			Story:     *story,
			Embedding: embedding,
		}

		if err := vectorDB.StoreStory(ctx, storyWithEmbedding); err != nil {
			log.Printf("Error storing story %d: %v", id, err)
			continue
		}

		log.Printf("Successfully processed story %d", id)
	}

	return nil
}
