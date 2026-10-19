from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional


class TaskCreate(BaseModel):
    title: str
    content: str
    due_date: date
    request_timestamp: datetime


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    done: Optional[bool] = None
    request_timestamp: datetime


class Task(TaskCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    done: bool
