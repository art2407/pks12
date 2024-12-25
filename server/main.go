package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	_ "github.com/lib/pq"
)

type Product struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	ImageURL    string    `json:"image_url"`
	Description string    `json:"description"`
	Price       float64   `json:"price"`
	CreatedAt   time.Time `json:"created_at"`
}

type Customer struct {
	ID        string    `json:"id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

type CartItem struct {
	ID         string    `json:"id"`
	CustomerID string    `json:"customer_id"`
	ProductID  string    `json:"product_id"`
	Quantity   int       `json:"quantity"`
	CreatedAt  time.Time `json:"created_at"`
	Product    Product   `json:"product,omitempty"`
}

type Order struct {
	ID         string         `json:"id"`
	CustomerID string         `json:"customer_id"`
	Status     string         `json:"status"`
	TotalPrice float64        `json:"total_price"`
	CreatedAt  time.Time      `json:"created_at"`
	Items      []OrderProduct `json:"items,omitempty"`
}

type OrderProduct struct {
	ID        string  `json:"id"`
	OrderID   string  `json:"order_id"`
	ProductID string  `json:"product_id"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
	Product   Product `json:"product,omitempty"`
}

type Favorite struct {
	ID         string    `json:"id"`
	CustomerID string    `json:"customer_id"`
	ProductID  string    `json:"product_id"`
	CreatedAt  time.Time `json:"created_at"`
	Product    Product   `json:"product,omitempty"`
}

var db *sql.DB

func init() {
	var err error
	
	connStr := "postgresql://postgres.rvgdrypryfksytkjbthl:cskaalwaysbefirst@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Ошибка подключения к базе данных:", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatal("Ошибка проверки подключения:", err)
	}
	// Настройка пула соединений
	db.SetMaxOpenConns(10)                 // Максимум 10 открытых соединений
	db.SetMaxIdleConns(5)                  // Максимум 5 простаивающих соединений
	db.SetConnMaxLifetime(5 * time.Minute) // Максимальное время жизни соединения - 5 минут
}

func getProducts(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
		SELECT id::text, name, image_url, description, price, created_at 
		FROM products
	`)
	if err != nil {
		http.Error(w, "Ошибка при получении продуктов", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var products []Product
	for rows.Next() {
		var p Product
		if err := rows.Scan(&p.ID, &p.Name, &p.ImageURL, &p.Description,
			&p.Price, &p.CreatedAt); err != nil {
			log.Printf("Ошибка сканирования: %v", err)
			http.Error(w, "Ошибка при сканировании данных", http.StatusInternalServerError)
			return
		}
		products = append(products, p)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(products)
}

func createProduct(w http.ResponseWriter, r *http.Request) {
	var product Product
	if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	query := `
		INSERT INTO products (name, price, description)
		VALUES ($1, $2, $3)
		RETURNING id`

	err := db.QueryRow(query, product.Name, product.Price, product.Description).Scan(&product.ID)
	if err != nil {
		http.Error(w, "Ошибка при создании продукта", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

func updateProduct(w http.ResponseWriter, r *http.Request) {
	var product Product
	if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	query := `
		UPDATE products 
		SET name = $1, price = $2, description = $3
		WHERE id = $4`

	result, err := db.Exec(query, product.Name, product.Price, product.Description, product.ID)
	if err != nil {
		http.Error(w, "Ошибка при обновлении продукта", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Продукт не найден", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

func deleteProduct(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, "ID не указан", http.StatusBadRequest)
		return
	}

	query := "DELETE FROM products WHERE id = $1"
	result, err := db.Exec(query, id)
	if err != nil {
		http.Error(w, "Ошибка при удалении продукта", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Продукт не найден", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func addToFavorites(w http.ResponseWriter, r *http.Request) {
	var favorite Favorite
	if err := json.NewDecoder(r.Body).Decode(&favorite); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	query := `
		INSERT INTO favorites (customer_id, product_id)
		VALUES ($1, $2)
		RETURNING id, created_at`

	err := db.QueryRow(query, favorite.CustomerID, favorite.ProductID).Scan(&favorite.ID, &favorite.CreatedAt)
	if err != nil {
		http.Error(w, "Ошибка при добавлении в избранное", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(favorite)
}

func getFavorites(w http.ResponseWriter, r *http.Request) {
	customerID := r.URL.Query().Get("customer_id")
	if customerID == "" {
		http.Error(w, "ID пользователя не указан", http.StatusBadRequest)
		return
	}

	query := `
		SELECT f.id, f.customer_id, f.product_id, f.created_at,
			   p.id, p.name, p.image_url, p.description, p.price, p.created_at
		FROM favorites f
		JOIN products p ON f.product_id = p.id
		WHERE f.customer_id = $1`

	rows, err := db.Query(query, customerID)
	if err != nil {
		http.Error(w, "Ошибка при получении избранного", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var favorites []Favorite
	for rows.Next() {
		var f Favorite
		if err := rows.Scan(
			&f.ID, &f.CustomerID, &f.ProductID, &f.CreatedAt,
			&f.Product.ID, &f.Product.Name, &f.Product.ImageURL,
			&f.Product.Description, &f.Product.Price,
			&f.Product.CreatedAt); err != nil {
			http.Error(w, "Ошибка при сканировании данных", http.StatusInternalServerError)
			return
		}
		favorites = append(favorites, f)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(favorites)
}

func addToCart(w http.ResponseWriter, r *http.Request) {
	var item CartItem
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	query := `
		INSERT INTO cart (customer_id, product_id, quantity)
		VALUES ($1, $2, $3)
		RETURNING id, created_at`

	err := db.QueryRow(query, item.CustomerID, item.ProductID, item.Quantity).
		Scan(&item.ID, &item.CreatedAt)
	if err != nil {
		http.Error(w, "Ошибка при добавлении в корзину", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(item)
}

func getCart(w http.ResponseWriter, r *http.Request) {
	customerID := r.URL.Query().Get("customer_id")
	if customerID == "" {
		http.Error(w, "ID пользователя не указан", http.StatusBadRequest)
		return
	}

	query := `
		SELECT c.id, c.customer_id, c.product_id, c.quantity, c.created_at,
			   p.id, p.name, p.image_url, p.description, p.price, p.created_at
		FROM cart c
		JOIN products p ON c.product_id = p.id
		WHERE c.customer_id = $1`

	rows, err := db.Query(query, customerID)
	if err != nil {
		http.Error(w, "Ошибка при получении корзины", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var items []CartItem
	for rows.Next() {
		var item CartItem
		if err := rows.Scan(
			&item.ID, &item.CustomerID, &item.ProductID, &item.Quantity, &item.CreatedAt,
			&item.Product.ID, &item.Product.Name, &item.Product.ImageURL,
			&item.Product.Description, &item.Product.Price,
			&item.Product.CreatedAt); err != nil {
			http.Error(w, "Ошибка при сканировании данных", http.StatusInternalServerError)
			return
		}
		items = append(items, item)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(items)
}

func createOrder(w http.ResponseWriter, r *http.Request) {
	var order Order
	if err := json.NewDecoder(r.Body).Decode(&order); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	tx, err := db.Begin()
	if err != nil {
		http.Error(w, "Ошибка при создании транзакции", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Создаем заказ
	query := `
		INSERT INTO orders (customer_id, status, total_price)
		VALUES ($1, $2, $3)
		RETURNING id, created_at`

	err = tx.QueryRow(query, order.CustomerID, "new", order.TotalPrice).
		Scan(&order.ID, &order.CreatedAt)
	if err != nil {
		http.Error(w, "Ошибка при создании заказа", http.StatusInternalServerError)
		return
	}

	// Добавляем элементы заказа
	for _, item := range order.Items {
		_, err = tx.Exec(`
			INSERT INTO orders_products (order_id, product_id, quantity, price)
			VALUES ($1, $2, $3, $4)
			RETURNING id`,
			order.ID, item.ProductID, item.Quantity, item.Price)
		if err != nil {
			http.Error(w, "Ошибка при добавлении элементов заказа", http.StatusInternalServerError)
			return
		}
	}

	// Очищаем корзину пользователя
	_, err = tx.Exec("DELETE FROM cart WHERE customer_id = $1", order.CustomerID)
	if err != nil {
		http.Error(w, "Ошибка при очистке корзины", http.StatusInternalServerError)
		return
	}

	if err = tx.Commit(); err != nil {
		http.Error(w, "Ошибка при подтверждении транзакции", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(order)
}

func getOrders(w http.ResponseWriter, r *http.Request) {
	customerID := r.URL.Query().Get("customer_id")
	if customerID == "" {
		http.Error(w, "ID пользователя не указан", http.StatusBadRequest)
		return
	}

	query := `
		SELECT o.id, o.customer_id, o.status, o.total_price, o.created_at
		FROM orders o
		WHERE o.customer_id = $1
		ORDER BY o.created_at DESC`

	rows, err := db.Query(query, customerID)
	if err != nil {
		http.Error(w, "Ошибка при получении заказов", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var orders []Order
	for rows.Next() {
		var order Order
		if err := rows.Scan(
			&order.ID, &order.CustomerID, &order.Status,
			&order.TotalPrice, &order.CreatedAt); err != nil {
			http.Error(w, "Ошибка при сканировании данных заказа", http.StatusInternalServerError)
			return
		}

		// Получаем элементы заказа
		itemsQuery := `
			SELECT op.id, op.order_id, op.product_id, op.quantity, op.price,
				   p.id, p.name, p.image_url, p.description, p.price, p.created_at
			FROM orders_products op
			JOIN products p ON op.product_id = p.id
			WHERE op.order_id = $1`

		itemRows, err := db.Query(itemsQuery, order.ID)
		if err != nil {
			http.Error(w, "Ошибка при получении элементов заказа", http.StatusInternalServerError)
			return
		}
		defer itemRows.Close()

		var items []OrderProduct
		for itemRows.Next() {
			var item OrderProduct
			if err := itemRows.Scan(
				&item.ID, &item.OrderID, &item.ProductID, &item.Quantity, &item.Price,
				&item.Product.ID, &item.Product.Name, &item.Product.ImageURL,
				&item.Product.Description, &item.Product.Price,
				&item.Product.CreatedAt); err != nil {
				http.Error(w, "Ошибка при сканировании данных элемента заказа", http.StatusInternalServerError)
				return
			}
			items = append(items, item)
		}
		order.Items = items
		orders = append(orders, order)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(orders)
}

func enableCORS(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.Header().Set("Content-Type", "application/json; charset=utf-8")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		handler(w, r)
	}
}

func main() {
	productsHandler := func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			getProducts(w, r)
		case http.MethodPost:
			createProduct(w, r)
		case http.MethodPut:
			updateProduct(w, r)
		case http.MethodDelete:
			deleteProduct(w, r)
		default:
			if r.Method != "OPTIONS" {
				http.Error(w, "Метод не поддерживается", http.StatusMethodNotAllowed)
			}
		}
	}

	http.HandleFunc("/api/products", enableCORS(productsHandler))

	http.HandleFunc("/api/favorites", enableCORS(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			getFavorites(w, r)
		case http.MethodPost:
			addToFavorites(w, r)
		default:
			if r.Method != "OPTIONS" {
				http.Error(w, "Метод не поддерживается", http.StatusMethodNotAllowed)
			}
		}
	}))

	http.HandleFunc("/api/cart", enableCORS(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			getCart(w, r)
		case http.MethodPost:
			addToCart(w, r)
		default:
			if r.Method != "OPTIONS" {
				http.Error(w, "Метод не поддерживается", http.StatusMethodNotAllowed)
			}
		}
	}))

	http.HandleFunc("/api/orders", enableCORS(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			getOrders(w, r)
		case http.MethodPost:
			createOrder(w, r)
		default:
			if r.Method != "OPTIONS" {
				http.Error(w, "Метод не поддерживается", http.StatusMethodNotAllowed)
			}
		}
	}))

	log.Println("Сервер запущен на порту 8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
