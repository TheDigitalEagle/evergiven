package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
	"github.com/shopspring/decimal"
)

var db *sql.DB

type Order struct {
	OrderId             int             `json:"orderId"`
	DateOfOrder         time.Time       `json:"dateOfOrder"`
	TrackingNumber      string          `json:"trackingNumber"`
	ShortDescriptOfItem string          `json:"shortDescriptOfItem"`
	OrderQuantity       int             `json:"orderQuantity"`
	CostPerItemCNY      decimal.Decimal `json:"costPerItemCNY"`
	TotalPerItemCNY     decimal.Decimal `json:"totalPerItemCNY"`
	CostPerItemUSD      decimal.Decimal `json:"costPerItemUSD"`
	TotalPerItemUSD     decimal.Decimal `json:"totalPerItemUSD"`
}

type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
	Database  string `json:"database"`
}

func main() {
	// Configure logging
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	var err error
	databaseURL := os.Getenv("DATABASE_URL")

	// Determine database driver based on URL
	var driver string
	if strings.HasPrefix(databaseURL, "sqlite") {
		driver = "sqlite3"
		// Convert sqlite:///path to just path for sqlite3 driver
		databaseURL = strings.TrimPrefix(databaseURL, "sqlite://")
	} else {
		driver = "postgres"
	}

	db, err = sql.Open(driver, databaseURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Test database connection
	if err := db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	// Ensure china_orders table exists
	ensureTableExists()

	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RealIP)
	r.Use(middleware.RequestID)

	// Optional API Key Authentication
	if apiKey := os.Getenv("API_KEY"); apiKey != "" {
		r.Use(apiKeyMiddleware(apiKey))
		log.Println("🔐 API Key authentication enabled")
	}

	// CORS configuration for GPT access
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"}, // Configure this properly for production
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token", "X-API-Key"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Routes
	r.Get("/health", healthCheck)
	r.Get("/orders", listOrders)
	r.Post("/orders", createOrder)
	r.Put("/orders/{id}", updateOrder)
	r.Delete("/orders/{id}", deleteOrder)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("EverGiven API starting on port %s with %s database", port, driver)
	log.Printf("Health check available at http://localhost:%s/health", port)

	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	status := "healthy"
	dbStatus := "connected"

	// Check database connection
	if err := db.Ping(); err != nil {
		status = "unhealthy"
		dbStatus = "disconnected"
		log.Printf("Database health check failed: %v", err)
	}

	response := HealthResponse{
		Status:    status,
		Timestamp: time.Now().Format(time.RFC3339),
		Database:  dbStatus,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func listOrders(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT * FROM china_orders ORDER BY DateOfOrder DESC")
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	defer rows.Close()

	var orders []Order
	for rows.Next() {
		var o Order
		err := rows.Scan(
			&o.OrderId,
			&o.DateOfOrder,
			&o.TrackingNumber,
			&o.ShortDescriptOfItem,
			&o.OrderQuantity,
			&o.CostPerItemCNY,
			&o.TotalPerItemCNY,
			&o.CostPerItemUSD,
			&o.TotalPerItemUSD,
		)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		orders = append(orders, o)
	}
	json.NewEncoder(w).Encode(orders)
}

func createOrder(w http.ResponseWriter, r *http.Request) {
	var o Order
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	err := db.QueryRow(`
		INSERT INTO china_orders 
		(DateOfOrder, TrackingNumber, ShortDescriptOfItem, OrderQuantity, 
		CostPerItemCNY, TotalPerItemCNY, CostPerItemUSD, TotalPerItemUSD)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING OrderId
	`, o.DateOfOrder, o.TrackingNumber, o.ShortDescriptOfItem, o.OrderQuantity,
		o.CostPerItemCNY, o.TotalPerItemCNY, o.CostPerItemUSD, o.TotalPerItemUSD).Scan(&o.OrderId)

	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	json.NewEncoder(w).Encode(o)
}

func updateOrder(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var o Order
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	_, err := db.Exec(`
		UPDATE china_orders SET 
			DateOfOrder = $1,
			TrackingNumber = $2,
			ShortDescriptOfItem = $3,
			OrderQuantity = $4,
			CostPerItemCNY = $5,
			TotalPerItemCNY = $6,
			CostPerItemUSD = $7,
			TotalPerItemUSD = $8
		WHERE OrderId = $9
	`, o.DateOfOrder, o.TrackingNumber, o.ShortDescriptOfItem, o.OrderQuantity,
		o.CostPerItemCNY, o.TotalPerItemCNY, o.CostPerItemUSD, o.TotalPerItemUSD, id)

	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	o.OrderId, _ = strconv.Atoi(id)
	json.NewEncoder(w).Encode(o)
}

func deleteOrder(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	_, err := db.Exec("DELETE FROM china_orders WHERE OrderId = $1", id)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func ensureTableExists() {
	var query string

	// Check if we're using SQLite or PostgreSQL
	if strings.Contains(os.Getenv("DATABASE_URL"), "sqlite") {
		query = `
		CREATE TABLE IF NOT EXISTS china_orders (
			OrderId INTEGER PRIMARY KEY AUTOINCREMENT,
			DateOfOrder DATETIME NOT NULL,
			TrackingNumber TEXT,
			ShortDescriptOfItem TEXT,
			OrderQuantity INTEGER,
			CostPerItemCNY REAL,
			TotalPerItemCNY REAL,
			CostPerItemUSD REAL,
			TotalPerItemUSD REAL
		)`
	} else {
		query = `
		CREATE TABLE IF NOT EXISTS china_orders (
			OrderId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
			DateOfOrder TIMESTAMP NOT NULL,
			TrackingNumber VARCHAR(50),
			ShortDescriptOfItem TEXT,
			OrderQuantity INT,
			CostPerItemCNY NUMERIC(10, 2),
			TotalPerItemCNY NUMERIC(10, 2),
			CostPerItemUSD NUMERIC(10, 2),
			TotalPerItemUSD NUMERIC(10, 2)
		)`
	}

	if _, err := db.Exec(query); err != nil {
		log.Fatalf("Failed to create table: %v", err)
	}
}

// API Key middleware for optional authentication
func apiKeyMiddleware(apiKey string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Skip auth for health check
			if r.URL.Path == "/health" {
				next.ServeHTTP(w, r)
				return
			}

			// Check for API key in header
			providedKey := r.Header.Get("X-API-Key")
			if providedKey == "" {
				// Also check Authorization header
				authHeader := r.Header.Get("Authorization")
				if strings.HasPrefix(authHeader, "Bearer ") {
					providedKey = strings.TrimPrefix(authHeader, "Bearer ")
				}
			}

			if providedKey != apiKey {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
