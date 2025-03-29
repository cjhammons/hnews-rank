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

	// Create HackerNews client
	hnClient := hn.NewClient()

	// Process stories
	for {
		// Get top stories
		storyIDs, err := hnClient.GetTopStories()
		if err != nil {
			log.Printf("Error getting top stories: %v", err)
			time.Sleep(5 * time.Minute) // Wait 5 minutes before retrying
			continue
		}

		// Process each story
		for _, id := range storyIDs {
			// Get story details
			story, err := hnClient.GetStory(id)
			if err != nil {
				log.Printf("Error fetching story %d: %v", id, err)
				continue
			}

			// Skip non-story items
			if story.Type != "story" {
				continue
			}

			// Generate embedding for the story
			text := story.Title
			if story.Text != "" {
				text += " " + story.Text
			}

			embedding, err := vertexClient.GenerateEmbedding(ctx, text)
			if err != nil {
				log.Printf("Error generating embedding for story %d: %v", id, err)
				// If we hit the quota, wait longer before retrying
				if err.Error() == "rpc error: code = ResourceExhausted" {
					log.Println("Hit model quota, waiting 5 minutes before retrying...")
					time.Sleep(5 * time.Minute)
					continue
				}
				continue
			}

			// Store the story with its embedding
			storyWithEmbedding := &hn.StoryWithEmbedding{
				Story:     *story,
				Embedding: embedding,
			}
			if err := vectorDB.StoreStory(ctx, storyWithEmbedding); err != nil {
				log.Printf("Error storing story %d: %v", id, err)
				continue
			}

			log.Printf("Successfully processed story %d", id)

			// Sleep for 1 second between stories to avoid hitting the quota
			time.Sleep(time.Second)
		}

		// Wait 5 minutes before checking for new stories
		log.Println("Waiting 5 minutes before checking for new stories...")
		time.Sleep(5 * time.Minute)
	}
}
