import re


def get_tables_from_sql(sql_query: str,) -> str:
    """
    Extract tables from a QSL query given in parameter

    Args: 
        sql_query(str): The SQL query string

    Returns:
        Set: list of extracted tables
    
    """
    # Remove comments
    normalized_sql = re.sub(r"--.*?(?=\n|$)", "", sql_query)
    normalized_sql = re.sub(r"/\*.*?\*/", "", normalized_sql, flags=re.DOTALL).replace("\n", "")

    # Normalize whitespace and convert the query to lowercase
    normalized_sql = re.sub(r"\s+", " ", normalized_sql).strip().lower()

    print(f"Normalized query is: {normalized_sql};")

    tables = set()

    match_pattern = r"from(\s+.*?)(?=\s+group\s+|\s+limit\s+|\s+having\s+|\s+where\s+|\s+union\s+|;|\)|$)"
    tables_location = re.findall(match_pattern, normalized_sql)

    table_pattern = r"(^[\[\w.\]]+)|, *([\[\w.\]]+)|\s+join\s+([\[\w.\]]+)"

    for tl in tables_location:
        tables_names = re.findall(table_pattern, tl.strip())
        new_tables = {word.upper() for match in tables_names for word in match if word}
        tables.update(new_tables)

        # print(f"Location: {tl} - New tables {new_tables}:")


    return tables


sql_query = """
SELECT * FROM dbo.X WHERE N=1 UNION ALL select * from     a,b 
where a.id=b.key;
--This is the first comment
select col1, col2 from tA inner join TB on tA.id =tB.id /* Remove this comment toooo */;
select a.id, b.name, c.sex, d.age from a,b,    c, d, k, m where a.id=b.id
-- Another complex query
select a.id, b.name, c.sex, d.age from [dbo].[a] aT inner join b right join c full join d cross join k

-- End of query
"""


tables = get_tables_from_sql(sql_query)
print(tables)