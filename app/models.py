from sqlalchemy import Column, Integer, String, Boolean, Date, DateTime
from datetime import datetime

try:
    from app.database import Base  # type: ignore
except ImportError:  # pragma: no cover - fallback when running as module
    from database import Base


class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(String, nullable=False)
    due_date = Column(Date, nullable=False)
    done = Column(Boolean, default=False)
    request_timestamp = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)
