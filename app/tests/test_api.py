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
os.environ.setdefault("SECRET_KEY", "test-secret")
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
