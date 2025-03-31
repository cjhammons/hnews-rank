package embedding

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

// Client handles communication with the Python embedding service.
type Client struct {
	baseURL    string
	httpClient *http.Client
}

// NewClient creates a new embedding client.
// It uses EMBEDDING_SERVICE_URL environment variable or falls back to a default.
func NewClient() (*Client, error) {
	baseURL := os.Getenv("EMBEDDING_SERVICE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:6000"
	}

	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}, nil
}

// EmbedRequest is the request structure for the embedding service.
type EmbedRequest struct {
	Text string `json:"text"`
}

// EmbedResponse is the response structure from the embedding service.
type EmbedResponse struct {
	Embedding []float32 `json:"embedding"`
	Error     string    `json:"error,omitempty"`
}

// GenerateEmbedding creates a vector embedding for the given text using the Python service.
// Returns a slice of float32 values representing the text embedding and any error encountered.
func (c *Client) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	reqBody := EmbedRequest{
		Text: text,
	}

	reqJSON, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		"POST",
		fmt.Sprintf("%s/embed", c.baseURL),
		bytes.NewBuffer(reqJSON),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("embedding service returned non-200 status: %d, body: %s", resp.StatusCode, body)
	}

	var embedResp EmbedResponse
	if err := json.Unmarshal(body, &embedResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if embedResp.Error != "" {
		return nil, fmt.Errorf("embedding service error: %s", embedResp.Error)
	}

	return embedResp.Embedding, nil
}

// Close is a no-op in this client but is provided for API compatibility with the vertex client.
func (c *Client) Close() {
	// Nothing to close
}
