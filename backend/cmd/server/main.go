package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
	"github.com/DCCXXV/Nemsy/backend/internal/auth"
	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/DCCXXV/Nemsy/backend/internal/resources"
	"github.com/DCCXXV/Nemsy/backend/internal/storage"
	"github.com/DCCXXV/Nemsy/backend/internal/studies"
	"github.com/DCCXXV/Nemsy/backend/internal/universities"
	"github.com/DCCXXV/Nemsy/backend/internal/users"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL not set")
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer pool.Close()

	queries := db.New(pool)

	s3Endpoint := os.Getenv("S3_ENDPOINT")
	s3AccessKey := os.Getenv("S3_ACCESS_KEY")
	s3SecretKey := os.Getenv("S3_SECRET_KEY")
	s3Bucket := os.Getenv("S3_BUCKET")
	s3UseSSL := os.Getenv("S3_USE_SSL") != "false"

	if s3Endpoint == "" || s3AccessKey == "" || s3SecretKey == "" || s3Bucket == "" {
		log.Fatal("S3_ENDPOINT, S3_ACCESS_KEY, S3_SECRET_KEY, and S3_BUCKET must be set")
	}

	s3Client, err := storage.NewS3Client(s3Endpoint, s3AccessKey, s3SecretKey, s3Bucket, s3UseSSL)
	if err != nil {
		log.Fatalf("Failed to create S3 client: %v", err)
	}

	myApp := &app.App{
		Queries: queries,
		DB:      pool,
		Storage: s3Client,
	}

	secret := []byte(os.Getenv("JWT_SECRET"))
	if len(secret) == 0 {
		log.Fatal("JWT_SECRET not set")
	}

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	store := auth.NewStateStore(5 * time.Minute)

	authHandler := auth.NewHandler(auth.GoogleOAuthConfig(), secret, store, myApp.Queries)
	studiesHandler := studies.NewHandler(myApp)
	universitiesHandler := universities.NewHandler(myApp)
	usersHandler := users.NewHandler(myApp)
	resourcesHandler := resources.NewHandler(myApp)

	r.Get("/auth/login", authHandler.LoginHandler)
	r.Get("/auth/callback", authHandler.CallbackHandler)

	mw := &auth.AuthMiddleware{Secret: secret}
	r.Group(func(protected chi.Router) {
		protected.Use(mw.Middleware)

		protected.Get("/api/me", usersHandler.MeHandler)
		protected.Put("/api/me/study", usersHandler.UpdateUserStudy)
		protected.Put("/api/me/university", usersHandler.UpdateUserUniversity)
		protected.Get("/api/me/subjects", usersHandler.MySubjects)
		protected.Post("/api/me/subjects/{id}/pin", usersHandler.PinSubject)
		protected.Delete("/api/me/subjects/{id}/pin", usersHandler.UnpinSubject)

		protected.Get("/api/users/{id}", usersHandler.Get)
		protected.Get("/api/users/by/{username}", usersHandler.GetByUsername)

		protected.Get("/api/resources/search", resourcesHandler.Search)
		protected.Get("/api/resources/by/{username}", resourcesHandler.ListByUser)

		protected.Get("/api/studies", studiesHandler.ListStudies)
		protected.Get("/api/universities/search", universitiesHandler.Search)
		protected.Get("/api/universities/{universityId}/studies", studiesHandler.ListByUniversity)

		protected.Post("/api/resources", resourcesHandler.Create)
		protected.Get("/api/resources/{id}", resourcesHandler.Get)
		protected.Delete("/api/resources/{id}", resourcesHandler.Delete)
		protected.Get("/api/resources/{id}/download", resourcesHandler.Download)
		protected.Get("/api/resources/{id}/files/{fileId}/download", resourcesHandler.DownloadFile)
		protected.Get("/api/subjects/{id}/resources", resourcesHandler.ListBySubject)
	})

	srv := &http.Server{Addr: ":8080", Handler: r}
	go func() {
		log.Println("Server starting on :8080...")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("HTTP server error: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	<-stop
	log.Println("Shutting down...")
	srv.Close() // TODO: use Shutdown for prod
}
