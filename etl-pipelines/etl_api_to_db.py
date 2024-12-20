import requests
import psycopg2
import json

# Database connection details
DB_CONFIG = {
    "host": "localhost",
    "database": "etl_db",
    "user": "postgres",
    "password": "password"
}

# API endpoint
API_URL = "https://jsonplaceholder.typicode.com/posts"

def extract_data():
    """Extract data from the API."""
    response = requests.get(API_URL)
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"API call failed with status code {response.status_code}")

def transform_data(data):
    """Transform data into a database-friendly format."""
    transformed = []
    for item in data:
        transformed.append((item["id"], item["title"], item["body"]))
    return transformed

def load_data_to_db(data):
    """Load data into the PostgreSQL database."""
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS posts (
            id SERIAL PRIMARY KEY,
            title TEXT,
            body TEXT
        )
    """)
    cursor.executemany("INSERT INTO posts (id, title, body) VALUES (%s, %s, %s)", data)
    conn.commit()
    conn.close()

def main():
    """ETL Pipeline execution."""
    print("Starting ETL pipeline...")
    data = extract_data()
    transformed_data = transform_data(data)
    load_data_to_db(transformed_data)
    print("ETL pipeline completed successfully.")

if __name__ == "__main__":
    main()