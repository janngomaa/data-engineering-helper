# ETL: API to PostgreSQL

This pipeline extracts data from a public API, transforms it into a structured format, and loads it into a PostgreSQL database.

## Steps
1. **Extract**: Retrieve data from an API endpoint.
2. **Transform**: Format the data for database compatibility.
3. **Load**: Insert the data into a PostgreSQL table.

## Prerequisites
- Python 3.x
- PostgreSQL installed and running.
- Required Python libraries:
  ```bash
  pip install requests psycopg2
  ```

## How to Run
1. Update the database credentials in the script.
2. Run the script:
   ```bash
   python etl_api_to_db.py
   ```
3.	Verify the data in your PostgreSQL database.

---
# CSV to Parquet ETL Pipeline

This pipeline converts a CSV file into a Parquet file after applying data cleaning and filtering.

## Steps
1. **Extract**: Load data from a CSV file.
2. **Transform**: Apply cleaning and filtering logic.
3. **Load**: Save the data to a Parquet file.

## Prerequisites
- Python 3.x
- Required Python libraries:
  ```bash
  pip install pandas pyarrow
  ```

## How to Run
	1.	Place your CSV file in the working directory and update the file path in the script.
	2.	Run the script:
		```bash
		python csv_to_parquet.py
		```
3.	The cleaned data will be saved as a Parquet file in the specified location.

---
# Spark Batch Processing ETL Pipeline

This pipeline processes large datasets using Apache Spark, computing aggregated metrics for analysis.

## Steps
1. **Extract**: Load data into a Spark DataFrame.
2. **Transform**: Apply group-by and aggregation to compute metrics.
3. **Load**: Save the results into a CSV file.

## Prerequisites
- Python 3.x
- Apache Spark installed and configured.
- Required Python libraries:
  ```bash
  pip install pyspark
  ```

## How to Run
1.	Place the input dataset in the working directory.
2.	Run the script:
	```bash
	python spark_batch_processing.py
	```
3.	The aggregated results will be saved in the specified output directory.