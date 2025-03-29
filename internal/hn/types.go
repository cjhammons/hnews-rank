package hn

// Story represents a Hacker News story item with all its metadata.
// This struct matches the JSON structure returned by the HN API.
type Story struct {
	ID          int    `json:"id"`          // Unique identifier for the story
	Title       string `json:"title"`       // Title of the story
	URL         string `json:"url"`         // URL of the story (if external link)
	Score       int    `json:"score"`       // Number of upvotes
	Time        int64  `json:"time"`        // Unix timestamp of submission
	Text        string `json:"text"`        // Text content (for text posts)
	By          string `json:"by"`          // Username of the submitter
	Type        string `json:"type"`        // Type of item (e.g., "story", "comment")
	Descendants int    `json:"descendants"` // Number of comments
}

// StoryWithEmbedding extends Story to include a vector embedding.
// This is used when storing stories in the vector database.
type StoryWithEmbedding struct {
	Story
	Embedding []float32 `json:"embedding"` // Vector embedding of the story's content
}

// Client defines the interface for interacting with the Hacker News API.
// This abstraction allows for easier testing and potential API changes.
type Client interface {
	// GetTopStories retrieves the IDs of the current top stories from HN.
	GetTopStories() ([]int, error)

	// GetStory fetches the full details of a specific story by its ID.
	GetStory(id int) (*Story, error)
}
