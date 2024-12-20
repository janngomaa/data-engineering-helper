# Data Engineering Use Cases

This repository contains a collection of useful code snippets and scripts for various data engineering tasks. Each script is categorized based on its use case and includes a description of its functionality.

---

## Table of Contents
- [ETL Pipelines](#etl-pipelines)
  - [API to PostgreSQL](etl-pipelines/README.md)
  - [CSV to Parquet Conversion](etl-pipelines/README.md)
  - [Batch Processing with Apache Spark](etl-pipelines/README.md)

- [Cognos Lineage](#cognos-lineage)
- [Useful Regex](#regular-expression)

---
## ETL Pipelines
Scripts to extract, transform, and load (ETL) data effectively.

- [API to PostgreSQL](etl-pipelines/README.md): Extract data from a public API, transform it, and load it into a PostgreSQL database.
- [CSV to Parquet Conversion](etl-pipelines/README.md): Extract data from a CSV file, clean and filter it, and save it as a Parquet file.
- [Batch Processing with Apache Spark](etl-pipelines/README.md): Process large datasets using Apache Spark to compute aggregated metrics.


---
## Cognos Lineage
Scripts for extracting lineage and metadata from Cognos Framework Manager models.

- [Extract Framework Manager Models](cognos-lineage/ExtractFrameWorkManager.ps1): A PowerShell script that processes all `model.xml` files in a given folder (`$ModelsPath`) and extracts Framework Manager model information into CSV files. The results are saved in a folder named `result`.

---
## Regular Expressions
Scripts that use regular expressions to manipulate or analyze data.

- [Extract Tables from SQL Query](regular-expression/extract_tables_from_sql_query.py): A Python script that extracts table names from SQL queries using regular expressions.

---

## How to Use
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/data-engineering-usecases.git
   ```

2. Navigate to the specific use case folder:
   ```bash
   cd data-engineering-usecases/cognos-lineage
   ```

3. Run the script:
   ```bash
   ./ExtractFrameWorkManager.ps1
   ```

4. Follow the prompts to specify the input folder and output folder.

5. The script will process all `model.xml` files in the specified folder and save the results in the specified output folder.   

---

## Contributing

Feel free to contribute by submitting pull requests with additional use cases or improvements.

---

## License

This project is open-sourced under the MIT License - see the [LICENSE](LICENSE) file for details.

