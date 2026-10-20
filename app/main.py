import os
import uuid
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from fastapi import FastAPI, HTTPException, Request, Response, Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from redis.asyncio import Redis
import jwt
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.depends import RateLimiter
from prometheus_fastapi_instrumentator import Instrumentator
from typing import Callable, Optional

try:
    from app.database import AsyncSessionLocal, engine, Base  # type: ignore
    from app.models import Task
    from app.schemas import TaskCreate, TaskUpdate, Task as TaskSchema, to_naive_utc
except ImportError:  # pragma: no cover - fallback when running as module
    from database import AsyncSessionLocal, engine, Base  # type: ignore
    from models import Task
    from schemas import TaskCreate, TaskUpdate, Task as TaskSchema, to_naive_utc

# Environment (the ENV_FILE dotenv file is loaded by database.py, imported above)
DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")
DB_PORT = int(os.getenv("DB_PORT", 5432))
REDIS_URL = os.getenv("REDIS_URL")
SECRET_KEY = os.getenv("SECRET_KEY")
ENVIRONMENT = os.getenv("ENVIRONMENT")

logger = logging.getLogger("uvicorn.error")
logger.info(
    "FastAPI starting in %s mode, connecting to DB %s:%s", ENVIRONMENT, DB_HOST, DB_PORT
)


# -----------------------------
# Startup
# -----------------------------
@asynccontextmanager
async def lifespan(_: FastAPI):
    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    try:
        logger.info("Connecting to Redis at %s", REDIS_URL)
        redis_client = Redis.from_url(
            REDIS_URL, encoding="utf-8", decode_responses=True
        )
        await redis_client.ping()
        await FastAPILimiter.init(redis_client)
        logger.info(f"Rate limiter initialized for {ENVIRONMENT}")
    except Exception as exc:
        logger.warning("Redis not ready, rate limiting disabled: %s", exc)
    yield


# -----------------------------
# FastAPI init
# -----------------------------
app = FastAPI(title="FastAPI GCP-ready Backend", lifespan=lifespan)

# Prometheus metrics on /metrics, scraped by the ServiceMonitor.
Instrumentator().instrument(app).expose(app, include_in_schema=False)


# -----------------------------
# Correlation ID middleware
# -----------------------------
@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    correlation_id = request.headers.get("correlation_id", f"gen-{uuid.uuid4()}")
    request.state.correlation_id = correlation_id
    response = await call_next(request)
    response.headers["correlation_id"] = correlation_id
    return response


# -----------------------------
# DB dependency
# -----------------------------
async def get_session() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session


# -----------------------------
# JWT verification
# -----------------------------
def verify_token(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    return payload


def rate_limit_or_skip(times: int, seconds: int) -> Callable:
    limiter = RateLimiter(times=times, seconds=seconds)

    async def dependency(request: Request, response: Response):
        if FastAPILimiter.redis:
            return await limiter(request, response)

    return dependency


# -----------------------------
# Status endpoint
# -----------------------------
@app.get("/status")
async def status():
    return {"status": "ok", "env": ENVIRONMENT}


# -----------------------------
# CRUD endpoints
# -----------------------------
@app.post(
    "/tasks",
    response_model=TaskSchema,
    status_code=201,
    dependencies=[Depends(rate_limit_or_skip(times=5, seconds=10))],
)
async def create_task(
    task: TaskCreate,
    request: Request,
    token: dict = Depends(verify_token),
    session: AsyncSession = Depends(get_session),
):
    db_task = Task(
        title=task.title,
        content=task.content,
        due_date=task.due_date,
        done=False,
        request_timestamp=task.request_timestamp,
    )
    session.add(db_task)
    await session.commit()
    await session.refresh(db_task)
    logger.info(f"[{request.state.correlation_id}] Task created: {db_task.id}")
    return db_task


@app.get(
    "/tasks",
    response_model=list[TaskSchema],
    dependencies=[Depends(rate_limit_or_skip(times=10, seconds=60))],
)
async def get_tasks(
    session: AsyncSession = Depends(get_session), token: dict = Depends(verify_token)
):
    result = await session.execute(select(Task))
    return result.scalars().all()


@app.get("/tasks/{task_id}", response_model=TaskSchema)
async def get_task(
    task_id: int,
    session: AsyncSession = Depends(get_session),
    token: dict = Depends(verify_token),
):
    task = await session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.put("/tasks/{task_id}", response_model=TaskSchema)
async def update_task(
    task_id: int,
    task: TaskUpdate,
    request: Request,
    session: AsyncSession = Depends(get_session),
    token: dict = Depends(verify_token),
):
    db_task = await session.get(Task, task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.request_timestamp < db_task.request_timestamp:
        raise HTTPException(status_code=409, detail="Conflict: outdated timestamp")
    for field, value in task.model_dump(exclude_unset=True).items():
        setattr(db_task, field, value)
    await session.commit()
    await session.refresh(db_task)
    logger.info(f"[{request.state.correlation_id}] Task updated: {db_task.id}")
    return db_task


@app.delete("/tasks/{task_id}")
async def delete_task(
    task_id: int,
    request_timestamp: datetime,
    request: Request,
    session: AsyncSession = Depends(get_session),
    token: dict = Depends(verify_token),
):
    db_task = await session.get(Task, task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    if to_naive_utc(request_timestamp) < db_task.request_timestamp:
        raise HTTPException(status_code=409, detail="Conflict: outdated timestamp")
    await session.delete(db_task)
    await session.commit()
    logger.info(f"[{request.state.correlation_id}] Task deleted: {db_task.id}")
    return {"detail": "Task deleted"}


# -----------------------------
# Run locally
# -----------------------------
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
