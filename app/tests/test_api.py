import os
import asyncio
import jwt
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

os.environ.setdefault("DB_USER", "test")
os.environ.setdefault("DB_PASS", "test")
os.environ.setdefault("DB_NAME", "test")
os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_PORT", "5432")
os.environ.setdefault("SECRET_KEY", "test-secret-key-at-least-32-bytes-long")
os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")

from app import database  # noqa: E402
from app import main  # noqa: E402

DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(DATABASE_URL, echo=False, future=True)
TestingSessionLocal = sessionmaker(
    bind=test_engine, class_=AsyncSession, expire_on_commit=False
)

database.engine = test_engine
database.AsyncSessionLocal = TestingSessionLocal
main.engine = test_engine
main.AsyncSessionLocal = TestingSessionLocal


async def override_get_session():
    async with TestingSessionLocal() as session:
        yield session


main.app.dependency_overrides[main.get_session] = override_get_session


@pytest_asyncio.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(autouse=True, scope="module")
async def setup_database():
    async with test_engine.begin() as conn:
        await conn.run_sync(database.Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(database.Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client():
    transport = ASGITransport(app=main.app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as ac:
        yield ac


def _make_token():
    return jwt.encode({"sub": "tester"}, os.environ["SECRET_KEY"], algorithm="HS256")


@pytest.mark.asyncio
async def test_status_endpoint(client):
    response = await client.get("/status")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["env"] == os.environ["ENVIRONMENT"]


@pytest.mark.asyncio
async def test_tasks_requires_authorization(client):
    response = await client.get("/tasks", headers={"Authorization": "Bearer invalid"})
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid token"


@pytest.mark.asyncio
async def test_get_task_not_found_returns_404(client):
    token = _make_token()
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/tasks/1", headers=headers)
    assert response.status_code == 404
    assert response.json()["detail"] == "Task not found"


@pytest.mark.asyncio
async def test_tasks_without_authorization_header_returns_401(client):
    response = await client.get("/tasks")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_partial_update_keeps_other_fields(client):
    headers = {"Authorization": f"Bearer {_make_token()}"}
    created = await client.post(
        "/tasks",
        headers=headers,
        json={
            "title": "write tests",
            "content": "cover the update endpoint",
            "due_date": "2026-12-01",
            "request_timestamp": "2026-10-20T10:00:00",
        },
    )
    assert created.status_code == 201
    task_id = created.json()["id"]

    updated = await client.put(
        f"/tasks/{task_id}",
        headers=headers,
        json={"done": True, "request_timestamp": "2026-10-20T11:00:00"},
    )
    assert updated.status_code == 200
    body = updated.json()
    assert body["done"] is True
    assert body["title"] == "write tests"


@pytest.mark.asyncio
async def test_timezone_aware_timestamps_are_accepted(client):
    headers = {"Authorization": f"Bearer {_make_token()}"}
    created = await client.post(
        "/tasks",
        headers=headers,
        json={
            "title": "utc",
            "content": "timestamps sent by JavaScript end with Z",
            "due_date": "2026-12-01",
            "request_timestamp": "2026-10-20T10:00:00Z",
        },
    )
    assert created.status_code == 201
    task_id = created.json()["id"]

    stale = await client.put(
        f"/tasks/{task_id}",
        headers=headers,
        json={"done": True, "request_timestamp": "2026-10-20T11:00:00+02:00"},
    )
    assert stale.status_code == 409

    updated = await client.put(
        f"/tasks/{task_id}",
        headers=headers,
        json={"done": True, "request_timestamp": "2026-10-20T11:00:00Z"},
    )
    assert updated.status_code == 200

    deleted = await client.delete(
        f"/tasks/{task_id}",
        headers=headers,
        params={"request_timestamp": "2026-10-20T12:00:00Z"},
    )
    assert deleted.status_code == 200


@pytest.mark.asyncio
async def test_metrics_endpoint_exposes_prometheus_format(client):
    await client.get("/status")
    response = await client.get("/metrics")
    assert response.status_code == 200
    assert "http_request" in response.text


@pytest.mark.asyncio
async def test_rate_limited_routes_work_when_redis_is_up(client, monkeypatch):
    calls = []

    async def fake_limiter_call(self, request, response):
        calls.append((request.url.path, response))

    monkeypatch.setattr(main.FastAPILimiter, "redis", object())
    monkeypatch.setattr(main.RateLimiter, "__call__", fake_limiter_call)
    response = await client.get(
        "/tasks", headers={"Authorization": f"Bearer {_make_token()}"}
    )
    assert response.status_code == 200
    assert calls and calls[0][0] == "/tasks"
