package main

import (
	"database/sql"
	"encoding/json"
	"io/ioutil"
	"log"

	_ "github.com/lib/pq"
)

type Product struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Price       float64 `json:"price"`
	Description string  `json:"description"`
}

func main() {
	// Читаем JSON файл
	data, err := ioutil.ReadFile("../products.json")
	if err != nil {
		log.Fatal("Ошибка при чтении JSON файла:", err)
	}

	var products []Product
	if err := json.Unmarshal(data, &products); err != nil {
		log.Fatal("Ошибка при парсинге JSON:", err)
	}

	// Подключаемся к базе данных
	connStr := "postgresql://postgres.rvgdrypryfksytkjbthl:cskaalwaysbefirst@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Ошибка подключения к базе данных:", err)
	}
	defer db.Close()

	// Загружаем данные в базу
	for _, product := range products {
		query := `
			INSERT INTO products (name, price, description)
			VALUES ($1, $2, $3)
			RETURNING id::text`

		var id string
		err := db.QueryRow(query, product.Name, product.Price, product.Description).Scan(&id)
		if err != nil {
			log.Printf("Ошибка при загрузке продукта %s: %v", product.Name, err)
			continue
		}
		log.Printf("Продукт %s успешно загружен с ID: %s", product.Name, id)
	}
}
