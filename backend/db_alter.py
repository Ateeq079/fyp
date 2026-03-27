from sqlalchemy import text
from app.db.session import engine

def alter_schema():
    with engine.begin() as conn:
        print("Adding source_name and source_url columns to vocabularies table...")
        try:
            conn.execute(text("ALTER TABLE vocabularies ADD COLUMN source_name VARCHAR;"))
            conn.execute(text("ALTER TABLE vocabularies ADD COLUMN source_url VARCHAR;"))
            print("Successfully added columns!")
        except Exception as e:
            print(f"Error (columns might already exist): {e}")

if __name__ == "__main__":
    alter_schema()
