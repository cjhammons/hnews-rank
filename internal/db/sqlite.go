package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"

	"github.com/cjhammons/hacker-news-rank/internal/hn"
	_ "github.com/mattn/go-sqlite3"
)

// storyWithSimilarity represents a story with its similarity score
type storyWithSimilarity struct {
	story      *hn.Story
	similarity float64
}

// SQLiteDB implements the VectorDB interface using SQLite.
// It handles all vector database operations including storage and similarity search.
type SQLiteDB struct {
	db *sql.DB
}

// NewSQLiteDB creates a new SQLite database connection.
// The database file will be created if it doesn't exist.
func NewSQLiteDB(dbPath string) (*SQLiteDB, error) {
	// Create the data directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(dbPath), 0755); err != nil {
		return nil, fmt.Errorf("failed to create data directory: %w", err)
	}

	// Open the SQLite database
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Drop the existing table if it exists
	_, err = db.Exec(`DROP TABLE IF EXISTS stories`)
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to drop stories table: %w", err)
	}

	// Create the stories table with the correct schema
	_, err = db.Exec(`
		CREATE TABLE stories (
			id INTEGER PRIMARY KEY,
			title TEXT NOT NULL,
			url TEXT NOT NULL,
			text TEXT,
			embedding BLOB NOT NULL
		)
	`)
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to create stories table: %w", err)
	}

	return &SQLiteDB{db: db}, nil
}

// StoreStory stores a story with its embedding in the SQLite database.
// It combines the story's title and text for better search results.
// Returns any error encountered during storage.
func (db *SQLiteDB) StoreStory(ctx context.Context, story *hn.StoryWithEmbedding) error {
	// Convert embedding to JSON for storage
	embeddingJSON, err := json.Marshal(story.Embedding)
	if err != nil {
		return fmt.Errorf("failed to marshal embedding: %w", err)
	}

	// Insert or update story
	_, err = db.db.ExecContext(ctx, `
		INSERT OR REPLACE INTO stories (id, title, url, text, embedding)
		VALUES (?, ?, ?, ?, ?)
	`, story.ID, story.Title, story.URL, story.Text, embeddingJSON)

	if err != nil {
		return fmt.Errorf("failed to insert story: %w", err)
	}

	return nil
}

// SearchSimilarStories finds stories similar to the given embedding.
// It performs a similarity search using cosine similarity.
// Returns a slice of stories sorted by similarity and any error encountered.
func (db *SQLiteDB) SearchSimilarStories(ctx context.Context, embedding []float32, limit int) ([]*hn.Story, error) {
	// Get all stories
	rows, err := db.db.QueryContext(ctx, `
		SELECT id, title, url, text, embedding
		FROM stories
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to query stories: %w", err)
	}
	defer rows.Close()

	// Calculate similarities and store results
	var results []storyWithSimilarity
	for rows.Next() {
		var story hn.Story
		var embeddingJSON []byte
		if err := rows.Scan(&story.ID, &story.Title, &story.URL, &story.Text, &embeddingJSON); err != nil {
			return nil, fmt.Errorf("failed to scan story: %w", err)
		}

		var storyEmbedding []float32
		if err := json.Unmarshal(embeddingJSON, &storyEmbedding); err != nil {
			return nil, fmt.Errorf("failed to unmarshal embedding: %w", err)
		}

		similarity := cosineSimilarity(embedding, storyEmbedding)
		results = append(results, storyWithSimilarity{
			story:      &story,
			similarity: similarity,
		})
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating results: %w", err)
	}

	// Sort by similarity and take top results
	sortBySimilarity(results)
	if len(results) > limit {
		results = results[:limit]
	}

	// Convert to final format
	stories := make([]*hn.Story, len(results))
	for i, r := range results {
		stories[i] = r.story
	}

	return stories, nil
}

// cosineSimilarity calculates the cosine similarity between two vectors.
// Returns a value between -1 and 1, where 1 means the vectors are identical.
func cosineSimilarity(a, b []float32) float64 {
	if len(a) != len(b) {
		return 0
	}

	var dotProduct, normA, normB float64
	for i := range a {
		dotProduct += float64(a[i] * b[i])
		normA += float64(a[i] * a[i])
		normB += float64(b[i] * b[i])
	}

	if normA == 0 || normB == 0 {
		return 0
	}

	return dotProduct / (math.Sqrt(normA) * math.Sqrt(normB))
}

// sortBySimilarity sorts the results by similarity in descending order.
func sortBySimilarity(results []storyWithSimilarity) {
	// Simple bubble sort for small datasets
	for i := 0; i < len(results)-1; i++ {
		for j := 0; j < len(results)-i-1; j++ {
			if results[j].similarity < results[j+1].similarity {
				results[j], results[j+1] = results[j+1], results[j]
			}
		}
	}
}

// Close closes the database connection.
// This should be called when the database connection is no longer needed.
func (db *SQLiteDB) Close() error {
	return db.db.Close()
}
