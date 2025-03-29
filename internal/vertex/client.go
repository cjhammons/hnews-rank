package vertex

import (
	"context"
	"fmt"
	"os"

	aiplatform "cloud.google.com/go/aiplatform/apiv1"
	"cloud.google.com/go/aiplatform/apiv1/aiplatformpb"
	"google.golang.org/api/option"
	"google.golang.org/protobuf/types/known/structpb"
)

// Client wraps the VertexAI client and provides methods for generating embeddings.
// It uses the text-embedding-005 model for generating embeddings.
type Client struct {
	client *aiplatform.PredictionClient
}

// NewClient creates a new VertexAI client using environment variables for configuration.
// It requires VERTEX_AI_PROJECT and VERTEX_AI_LOCATION to be set.
// Returns a new Client instance and any error encountered during initialization.
func NewClient(ctx context.Context) (*Client, error) {
	projectID := os.Getenv("VERTEX_AI_PROJECT")
	location := os.Getenv("VERTEX_AI_LOCATION")
	credentialsFile := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")

	if projectID == "" || location == "" {
		return nil, fmt.Errorf("VERTEX_AI_PROJECT and VERTEX_AI_LOCATION environment variables must be set")
	}

	if credentialsFile == "" {
		credentialsFile = "vector-user.json" // Default to the credentials file in the project root
	}

	apiEndpoint := fmt.Sprintf("%s-aiplatform.googleapis.com:443", location)
	client, err := aiplatform.NewPredictionClient(ctx,
		option.WithEndpoint(apiEndpoint),
		option.WithCredentialsFile(credentialsFile),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create VertexAI client: %w", err)
	}

	return &Client{
		client: client,
	}, nil
}

// GenerateEmbedding creates a vector embedding for the given text using VertexAI.
// The embedding can be used for similarity search and comparison.
// Returns a slice of float32 values representing the text embedding and any error encountered.
func (c *Client) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	projectID := os.Getenv("VERTEX_AI_PROJECT")
	location := os.Getenv("VERTEX_AI_LOCATION")

	// Create the endpoint path for the text-embedding-005 model
	endpoint := fmt.Sprintf("projects/%s/locations/%s/publishers/google/models/text-embedding-005", projectID, location)

	// Create the instance for the text
	instance := structpb.NewStructValue(&structpb.Struct{
		Fields: map[string]*structpb.Value{
			"content": structpb.NewStringValue(text),
		},
	})

	// Create the prediction request
	req := &aiplatformpb.PredictRequest{
		Endpoint:  endpoint,
		Instances: []*structpb.Value{instance},
	}

	// Call the Predict API
	resp, err := c.client.Predict(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to generate embedding: %w", err)
	}

	if len(resp.Predictions) == 0 {
		return nil, fmt.Errorf("no embedding generated")
	}

	// Extract the embedding values from the response
	prediction := resp.Predictions[0]
	values := prediction.GetStructValue().Fields["embeddings"].GetStructValue().Fields["values"].GetListValue().Values

	// Convert the values to float32
	embedding := make([]float32, len(values))
	for i, value := range values {
		embedding[i] = float32(value.GetNumberValue())
	}

	return embedding, nil
}

// Close closes the VertexAI client connection.
// This should be called when the client is no longer needed.
func (c *Client) Close() {
	c.client.Close()
}
