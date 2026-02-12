from sqlalchemy import text
from app.db.session import engine
from app.db.base import Base
import sys


def fix_db():
    print(f"Connecting to database: {engine.url}", flush=True)
    try:
        with engine.connect() as conn:
            print("Successfully connected.", flush=True)
            # Force commit to ensure we aren't in a stalled transaction
            conn.commit()

            print("Attempting to DROP table 'users'...", flush=True)
            conn.execute(text("DROP TABLE IF EXISTS users CASCADE"))
            conn.commit()
            print("DROP command executed.", flush=True)

        print("Recreating tables via metadata...", flush=True)
        Base.metadata.create_all(bind=engine)
        print("Tables recreated.", flush=True)

        # Verify
        with engine.connect() as conn:
            result = conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns WHERE table_name = 'users'"
                )
            )
            cols = [row[0] for row in result]
            print(f"Columns in 'users' table: {cols}", flush=True)
            if "is_active" in cols:
                print("SUCCESS: 'is_active' column exists!", flush=True)
            else:
                print("FAILURE: 'is_active' column STILL MISSING!", flush=True)

    except Exception as e:
        print(f"ERROR: {e}", flush=True)
        sys.exit(1)


if __name__ == "__main__":
    fix_db()
