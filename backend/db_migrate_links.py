from sqlalchemy import text
from app.db.session import engine

def alter_schema():
    with engine.begin() as conn:
        print("Adding related_links JSONB column to vocabularies table...")
        try:
            # PostgreSQL uses JSONB for optimized JSON storage
            conn.execute(text("ALTER TABLE vocabularies ADD COLUMN related_links JSONB;"))
            print("Successfully added columns!")
        except Exception as e:
            print(f"Error (columns might already exist or DB is SQLite): {e}")
            # Fallback for SQLite in tests/dev if needed, though production is Postgres
            try:
                conn.execute(text("ALTER TABLE vocabularies ADD COLUMN related_links JSON;"))
                print("Added column as JSON (fallback).")
            except Exception as e2:
                print(f"Fallback failed: {e2}")

if __name__ == "__main__":
    alter_schema()
