package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cjhammons/hacker-news-rank/cmd/api/routes"
	"github.com/cjhammons/hacker-news-rank/internal/db"
	"github.com/cjhammons/hacker-news-rank/internal/embedding"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

// main starts the API server that handles story search requests.
// It initializes all necessary clients and sets up the HTTP routes.
func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: Error loading .env file: %v", err)
	}

	// Create embedding client
	embeddingClient, err := embedding.NewClient()
	if err != nil {
		log.Fatalf("Failed to create embedding client: %v", err)
	}
	defer embeddingClient.Close()

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

	// Serve static files
	router.Static("/static", "./static")
	router.GET("/", func(c *gin.Context) {
		c.File("./static/index.html")
	})

	// Initialize route handlers
	searchHandler := routes.NewSearchHandler(embeddingClient, vectorDB)

	// Define routes
	router.GET("/search", searchHandler.HandleSearch)

	// Start server
	srv := &http.Server{
		Addr:    ":8082",
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

	log.Println("Server starting on :" + srv.Addr)
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatalf("Server failed: %v", err)
	}
}
