package routes

import (
	"net/http"

	"github.com/cjhammons/hacker-news-rank/internal/db"
	"github.com/cjhammons/hacker-news-rank/internal/embedding"
	"github.com/gin-gonic/gin"
)

// SearchHandler handles the /search endpoint.
// It generates embeddings for the query and finds similar stories.
type SearchHandler struct {
	embeddingClient *embedding.Client
	vectorDB        db.VectorDB
}

// NewSearchHandler creates a new SearchHandler instance.
func NewSearchHandler(embeddingClient *embedding.Client, vectorDB db.VectorDB) *SearchHandler {
	return &SearchHandler{
		embeddingClient: embeddingClient,
		vectorDB:        vectorDB,
	}
}

// HandleSearch processes the search request.
// It expects a query parameter 'q' and returns similar stories.
func (h *SearchHandler) HandleSearch(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query parameter 'q' is required"})
		return
	}

	// Generate embedding for the query
	embedding, err := h.embeddingClient.GenerateEmbedding(c.Request.Context(), query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate embedding"})
		return
	}

	// Search for similar stories
	stories, err := h.vectorDB.SearchSimilarStories(c.Request.Context(), embedding, 10)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search stories"})
		return
	}

	c.JSON(http.StatusOK, stories)
}
