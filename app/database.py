import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker, declarative_base

Base = declarative_base()

# Load the env file before reading DB_* (main.py imports this module first).
# Variables already set in the environment (Kubernetes, compose) take precedence.
load_dotenv(os.getenv("ENV_FILE", ".env/dev.env"))

DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")

DATABASE_URL = f"postgresql+asyncpg://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# SQL echo logs every query (and its parameters): opt-in only.
engine: AsyncEngine = create_async_engine(
    DATABASE_URL, echo=os.getenv("DB_ECHO", "false").lower() == "true"
)
AsyncSessionLocal = sessionmaker(
    bind=engine, class_=AsyncSession, expire_on_commit=False
)
