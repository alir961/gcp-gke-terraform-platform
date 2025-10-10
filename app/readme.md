# 🧩 Task Manager API

A simple **FastAPI** application for creating, reading, updating, and deleting tasks, with data stored in a **PostgreSQL** database.

---

## 🚀 Run Locally (with Docker Compose)

### 🧰 Requirements
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- (Optional) [Python 3.12+](https://www.python.org/downloads/) if you want to run it without Docker.

---

### ▶️ Start the Project

1. **Clone the repository**
   ```bash
   git clone <repo_url>
   cd <project_folder>
   cd app
   ```

2. **Start the services**
   ```bash
   docker compose up --build
   ```
   This launches:
   - A **PostgreSQL** container (`postgres:16`)
   - A **FastAPI** container (`uvicorn`)

3. **Check that everything is running**
   ```bash
   docker ps
   ```
   You should see two containers: `postgres` and `fastapi_app`.

4. **Verify the API is up**
   ```bash
   curl http://localhost:8080/status
   ```
   Expected response:
   ```json
   {"status": "ok"}
   ```

---

## 🧱 Project Structure

```
.
├── main.py                # FastAPI entry point
├── database.py            # Async SQLAlchemy setup
├── models.py              # SQLAlchemy models
├── schemas.py             # Pydantic request/response schemas
├── Dockerfile             # API container definition
├── docker-compose.yml     # Docker Compose configuration
├── requirements.txt       # Project prerequesites
├── openapi.yaml           # OpenAPI Swagger
└── readme.md
```

---

## ⚙️ Configuration

The API connects to the database via the `DATABASE_URL` environment variable.

Default value (defined in `docker-compose.yml`):
```bash
DATABASE_URL=postgresql+asyncpg://postgres:mypassword@postgres:5432/tasks
```

### 📦 PostgreSQL connection details
| Parameter | Value |
|------------|--------|
| **Host** | `localhost` |
| **Port** | `5432` |
| **User** | `postgres` |
| **Password** | `mypassword` |
| **Database** | `tasks` |

---

## 🔐 Authentication

All endpoints except `/status` require a header:
```
Authorization: Bearer <your_token>
```

> Token validation isn’t implemented yet — this is just a placeholder for future JWT authentication.

---

## 🧭 Main Endpoints

| Method | Route | Description |
|---------|--------|-------------|
| `GET` | `/status` | Health check |
| `POST` | `/tasks` | Create a new task |
| `GET` | `/tasks` | List all tasks |
| `GET` | `/tasks/{id}` | Get a task by ID |
| `PUT` | `/tasks/{id}` | Update a task |
| `DELETE` | `/tasks/{id}` | Delete a task |

---

## 🧪 Quick Example

```bash
curl -X POST http://localhost:8080/tasks   -H "Content-Type: application/json"   -H "Authorization: Bearer testtoken"   -d '{
        "title": "Buy coffee",
        "content": "Organic arabica 1kg",
        "due_date": "2025-10-20T00:00:00",
        "request_timestamp": "2025-10-10T10:00:00"
      }'
```

---

## 🧹 Stop and Clean Up

```bash
docker compose down -v
```
(`-v` also removes the PostgreSQL volume.)

---

## 🧠 Technical Notes

- Fully **asynchronous stack** using `asyncpg` and SQLAlchemy async ORM  
- Custom middleware that generates a unique `correlation_id` per request  
- Basic `Bearer token` protection  
- Conflict handling using `request_timestamp`

---
