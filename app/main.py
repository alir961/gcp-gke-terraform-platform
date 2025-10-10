from fastapi import FastAPI, HTTPException, Request, Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from database import AsyncSessionLocal, engine, Base
from models import Task
from schemas import TaskCreate, TaskUpdate, Task as TaskSchema
from datetime import datetime
import uuid
from typing import Optional

app = FastAPI()

# Startup event for DB
@app.on_event("startup")
async def startup_event():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# Status endpoint
@app.get("/status")
async def status():
    return {"status": "ok"}

# Middleware for correlation_id
@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    correlation_id = request.headers.get("correlation_id", f"gen-{uuid.uuid4()}")
    request.state.correlation_id = correlation_id
    response = await call_next(request)
    response.headers["correlation_id"] = correlation_id
    return response

# Dependency
async def get_session() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session

# JWT placeholder
def verify_token(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    return authorization

# POST /tasks
@app.post("/tasks", response_model=TaskSchema, status_code=201)
async def create_task(task: TaskCreate, request: Request, token: str = Depends(verify_token), session: AsyncSession = Depends(get_session)):
    db_task = Task(
        title=task.title,
        content=task.content,
        due_date=task.due_date,
        done=False,
        request_timestamp=task.request_timestamp
    )
    session.add(db_task)
    await session.commit()
    await session.refresh(db_task)
    print(f"[{request.state.correlation_id}] Task created: {db_task.id}")
    return db_task

# GET /tasks
@app.get("/tasks", response_model=list[TaskSchema])
async def get_tasks(session: AsyncSession = Depends(get_session), token: str = Depends(verify_token)):
    result = await session.execute(select(Task))
    return result.scalars().all()

# GET /tasks/{id}
@app.get("/tasks/{task_id}", response_model=TaskSchema)
async def get_task(task_id: int, session: AsyncSession = Depends(get_session), token: str = Depends(verify_token)):
    task = await session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

# PUT /tasks/{id}
@app.put("/tasks/{task_id}", response_model=TaskSchema)
async def update_task(task_id: int, task: TaskUpdate, request: Request, session: AsyncSession = Depends(get_session), token: str = Depends(verify_token)):
    db_task = await session.get(Task, task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.request_timestamp < db_task.request_timestamp:
        raise HTTPException(status_code=409, detail="Conflict: outdated timestamp")
    for field, value in task.dict(exclude_unset=True).items():
        setattr(db_task, field, value)
    await session.commit()
    await session.refresh(db_task)
    print(f"[{request.state.correlation_id}] Task updated: {db_task.id}")
    return db_task

# DELETE /tasks/{id}
@app.delete("/tasks/{task_id}")
async def delete_task(task_id: int, request_timestamp: datetime, request: Request, session: AsyncSession = Depends(get_session), token: str = Depends(verify_token)):
    db_task = await session.get(Task, task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    if request_timestamp < db_task.request_timestamp:
        raise HTTPException(status_code=409, detail="Conflict: outdated timestamp")
    await session.delete(db_task)
    await session.commit()
    print(f"[{request.state.correlation_id}] Task deleted: {db_task.id}")
    return {"detail": "Task deleted"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
