package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/shopspring/decimal"
	_ "github.com/lib/pq"
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

func main() {
	var err error
	db, err = sql.Open("postgres", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}

	r := chi.NewRouter()

	r.Get("/orders", listOrders)
	r.Post("/orders", createOrder)
	r.Put("/orders/{id}", updateOrder)
	r.Delete("/orders/{id}", deleteOrder)

	log.Println("EverGiven API listening on :8080")
	http.ListenAndServe(":8080", r)
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

