package hn

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// baseURL is the root URL for the Hacker News Firebase API
const baseURL = "https://hacker-news.firebaseio.com/v0"

// client implements the Client interface for interacting with the HN API
type client struct {
	httpClient *http.Client // HTTP client with configured timeout
}

// NewClient creates a new HN API client with a configured HTTP client.
// The HTTP client has a 10-second timeout to prevent hanging requests.
func NewClient() Client {
	return &client{
		httpClient: &http.Client{
			Timeout: time.Second * 10,
		},
	}
}

// GetTopStories retrieves the IDs of the current top stories from HN.
// It makes a GET request to the HN API and decodes the JSON response.
// Returns a slice of story IDs and any error encountered.
func (c *client) GetTopStories() ([]int, error) {
	resp, err := c.httpClient.Get(fmt.Sprintf("%s/topstories.json", baseURL))
	if err != nil {
		return nil, fmt.Errorf("failed to fetch top stories: %w", err)
	}
	defer resp.Body.Close()

	var stories []int
	if err := json.NewDecoder(resp.Body).Decode(&stories); err != nil {
		return nil, fmt.Errorf("failed to decode top stories: %w", err)
	}

	return stories, nil
}

// GetStory fetches the full details of a specific story by its ID.
// It makes a GET request to the HN API and decodes the JSON response.
// Returns a pointer to a Story struct and any error encountered.
func (c *client) GetStory(id int) (*Story, error) {
	resp, err := c.httpClient.Get(fmt.Sprintf("%s/item/%d.json", baseURL, id))
	if err != nil {
		return nil, fmt.Errorf("failed to fetch story %d: %w", id, err)
	}
	defer resp.Body.Close()

	var story Story
	if err := json.NewDecoder(resp.Body).Decode(&story); err != nil {
		return nil, fmt.Errorf("failed to decode story %d: %w", id, err)
	}

	return &story, nil
}
