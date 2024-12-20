import pandas as pd

def extract_csv(file_path):
    """Extract data from a CSV file."""
    return pd.read_csv(file_path)

def transform_data(df):
    """Transform data: clean and filter."""
    df = df.dropna()  # Remove rows with missing values
    df = df[df["value"] > 10]  # Filter rows where "value" > 10
    return df

def load_to_parquet(df, output_path):
    """Load data into a Parquet file."""
    df.to_parquet(output_path, index=False)
    print(f"Data successfully saved to {output_path}")

def main():
    input_csv = "input_data.csv"
    output_parquet = "output_data.parquet"
    df = extract_csv(input_csv)
    transformed_df = transform_data(df)
    load_to_parquet(transformed_df, output_parquet)

if __name__ == "__main__":
    main()