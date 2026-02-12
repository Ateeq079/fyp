import logging
from sqlalchemy import text
from app.db.session import engine
from app.db.base import Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def reset_schema():
    logger.info("Dropping 'users' table to force schema update...")
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS users CASCADE;"))
        conn.commit()
    logger.info("'users' table dropped.")

    logger.info("Recreating tables...")
    Base.metadata.create_all(bind=engine)
    logger.info("Tables recreated successfully.")


if __name__ == "__main__":
    reset_schema()
