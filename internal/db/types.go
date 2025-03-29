package db

import (
	"context"
	"github.com/cjhammons/hacker-news-rank/internal/hn"
)

// VectorDB defines the interface for vector database operations.
// This abstraction allows for different vector database implementations
// while maintaining a consistent API for the application.
type VectorDB interface {
	// StoreStory stores a story with its embedding in the vector database.
	// The story's content and embedding are indexed for later similarity search.
	StoreStory(ctx context.Context, story *hn.StoryWithEmbedding) error

	// SearchSimilarStories finds stories similar to the given embedding.
	// It performs a similarity search using cosine similarity.
	// Returns a slice of stories sorted by similarity and any error encountered.
	SearchSimilarStories(ctx context.Context, embedding []float32, limit int) ([]*hn.Story, error)

	// Close closes the database connection and performs any necessary cleanup.
	Close() error
}
