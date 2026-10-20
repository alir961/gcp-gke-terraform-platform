from pydantic import BaseModel, ConfigDict, field_validator
from datetime import date, datetime, timezone
from typing import Optional


def to_naive_utc(value: datetime) -> datetime:
    """Store and compare timestamps as naive UTC, like the DateTime columns."""
    if value.tzinfo is not None:
        value = value.astimezone(timezone.utc).replace(tzinfo=None)
    return value


class TaskCreate(BaseModel):
    title: str
    content: str
    due_date: date
    request_timestamp: datetime

    _naive_timestamp = field_validator("request_timestamp")(to_naive_utc)


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    done: Optional[bool] = None
    request_timestamp: datetime

    _naive_timestamp = field_validator("request_timestamp")(to_naive_utc)


class Task(TaskCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    done: bool
