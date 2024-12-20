from pyspark.sql import SparkSession

def create_spark_session():
    """Initialize Spark session."""
    return SparkSession.builder \
        .appName("BatchProcessing") \
        .getOrCreate()

def extract_data(spark, input_path):
    """Load data into a Spark DataFrame."""
    return spark.read.csv(input_path, header=True, inferSchema=True)

def transform_data(df):
    """Apply transformations and aggregations."""
    return df.groupBy("category").agg({"value": "mean"})

def load_data(df, output_path):
    """Save the processed data."""
    df.write.csv(output_path, header=True)
    print(f"Data saved to {output_path}")

def main():
    spark = create_spark_session()
    input_path = "large_dataset.csv"
    output_path = "aggregated_results.csv"
    df = extract_data(spark, input_path)
    transformed_df = transform_data(df)
    load_data(transformed_df, output_path)
    spark.stop()

if __name__ == "__main__":
    main()