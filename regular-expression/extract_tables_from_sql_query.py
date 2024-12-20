import re

def get_tables_from_sql(sql_query: str,) -> str:
    """
    Extract tables from a QSL query given in parameter

    Args: 
        sql_query(str): The SQL query string

    Returns:
        List: list of extracted tables
    
    """
    # Remove comments
    normalized_sql = re.sub(r"--.*?(?=\n|$)", "", sql_query)
    normalized_sql = re.sub(r"/\*.*?\*/", "", normalized_sql, flags=re.DOTALL).replace("\n", "")

    # Normalize whitespace and convert the query to lowercase
    normalized_sql = re.sub(r"\s+", " ", normalized_sql).strip().lower()

    # Get table names

    table_names = set()

    location_pattern = r"from\s+(?!\()(.*?)(?=\s+group\s+|\s+limit\s+|\s+having\s+|\s+where\s+|\s+union\s+|;|\)|$)"
    table_locations = re.findall(location_pattern, normalized_sql)

    single_table_pattern = r"(^[\[\w.\]]+)|, *([\[\w.\]]+)|\s+join\s+([\[\w.\]]+)"

    for tl in table_locations:
        tnames_matches = re.findall(single_table_pattern, tl.strip())
        new_tables = {table.upper() for match in tnames_matches for table in match if table}
        table_names.update(new_tables)

    # Exclue CTE names
    cte_names = set()
    cte_pattern = r"\bwith\s+([\w_]+)\s+as\s+\(|,\s*([\w_]+)\s+as\s+\("
    cte_matches = re.findall(cte_pattern, normalized_sql)
    ctes = {cte.upper() for match in cte_matches for cte in match if cte}
    cte_names.update(ctes)

    table_names = sorted(table_names - cte_names)

    return table_names


# Example of usage
# Example SQL query
sql_query = """
WITH CTE_Name AS (
    SELECT col1 AS id, col2 AS fname FROM table1
),
Another_CTE AS (
    SELECT col2 FROM table2
),Yet_Another_CTE AS (
    SELECT col3 FROM table3
)
SELECT id, a_ad AS a_id cte FROM CTE_Name;
select a, colb from tablez union select c, d from tableK;
"""

tables = get_tables_from_sql(sql_query)
print(tables)