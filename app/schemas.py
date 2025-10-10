from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class TaskCreate(BaseModel):
    title: str
    content: str
    due_date: date
    request_timestamp: datetime

class TaskUpdate(BaseModel):
    title: Optional[str]
    content: Optional[str]
    done: Optional[bool]
    request_timestamp: datetime

class Task(TaskCreate):
    id: int
    done: bool
