import duckdb

conn = duckdb.connect("ndt.db")

def run_sql_file(conn, filepath):
    with open(filepath) as f:
        sql = f.read()
    statements = [s.strip() for s in sql.split(";") if s.strip()]
    for statement in statements:
        try:
            conn.execute(statement)
        except Exception as e:
            print(f"Error: {e}")
            print(f"Statement: {statement[:80]}")

conn.execute("DROP TABLE IF EXISTS fact_inspections")
conn.execute("DROP TABLE IF EXISTS dim_inspector")
conn.execute("DROP TABLE IF EXISTS dim_equipment")
conn.execute("DROP TABLE IF EXISTS dim_method")
conn.execute("DROP TABLE IF EXISTS dim_workorder")
conn.execute("DROP TABLE IF EXISTS dim_component")
conn.execute("DROP TABLE IF EXISTS dim_date")
conn.execute("DROP TABLE IF EXISTS dim_facility")

run_sql_file(conn, "schema/ndt_star_schema_duckdb.sql")
run_sql_file(conn, "schema/sample_data.sql")

print("Database setup complete.")
print(conn.execute("SHOW TABLES").df())
conn.close()