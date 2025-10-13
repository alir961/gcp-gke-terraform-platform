# 🧩 Task Manager API

A simple **FastAPI** application for creating, reading, updating, and deleting tasks, with data stored in a **PostgreSQL** database.

---

## 🚀 Run Locally

You can run the API either with **Docker Compose** or with a **Python virtual environment (venv)**.

---

### 🐳 Option 1: Run with Docker Compose

#### 🧰 Requirements
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)

#### ▶️ Start the Project
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

### 🐍 Option 2: Run with Python venv (recommended for local dev)

#### 🧰 Requirements
- Python 3.10+ (3.12 recommended)
- [pip](https://pip.pypa.io/en/stable/)

> We use a virtual environment to isolate dependencies from your system Python.

#### ▶️ Steps
1. **Clone the repository**
   ```bash
   git clone <repo_url>
   cd <project_folder>/app
   ```

2. **Create a virtual environment**
   ```bash
   python3 -m venv venv
   ```

3. **Activate the virtual environment**
- On macOS / Linux:
  ```bash
  source venv/bin/activate
  ```
- On Windows (PowerShell):
  ```powershell
  .\venv\Scripts\Activate.ps1
  ```
- On Windows (cmd):
  ```cmd
  venv\Scripts\activate.bat
  ```

4. **Upgrade pip and install dependencies**
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

5. **Set environment variables (choose dev or prod .env file)**  
   Dev example:
   ```bash
   export ENV_FILE=.env/dev.env
   ```
   Prod example:
   ```bash
   export ENV_FILE=.env/prod.env
   ```
   - On Windows PowerShell:
     ```powershell
     $env:ENV_FILE = ".env\dev.env"
     ```

6. **Run the application**
   ```bash
   python -m main
   ```
   The app will start on `http://0.0.0.0:8080` by default.

7. **Verify the API**
   ```bash
   curl http://localhost:8080/status
   ```
   Expected response:
   ```json
   {"status": "ok", "env": "dev"}
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
├── requirements.txt       # Python dependencies
├── .env/                  # Environment variables for dev/prod
├── openapi.yaml           # OpenAPI Swagger
└── README.md
```

---

## ⚙️ Configuration

The API connects to the database using environment variables defined in `.env/dev.env` or `.env/prod.env`. You can either set `ENV_FILE` to point to the desired file or export the individual variables.

**Example dev `.env/dev.env`:**
```bash
ENVIRONMENT=dev
DB_USER=tasks_user
DB_PASS=DevSecret444!
DB_NAME=tasks_db
DB_HOST=localhost
DB_PORT=5432
REDIS_URL=redis://localhost:6379
SECRET_KEY=DevSecretKey
```

**Example prod `.env/prod.env`:**
```bash
ENVIRONMENT=prod
DB_USER=tasks_user
DB_PASS=ProdSecret444!
DB_NAME=tasks_db
DB_HOST=fastapi-db.prod.svc.cluster.local
DB_PORT=5432
REDIS_URL=redis://fastapi-redis.prod.svc.cluster.local:6379
SECRET_KEY=ProdSecretKey
```

---

## 🔐 Authentication

All endpoints except `/status` require a header:

```
Authorization: Bearer <your_token>
```

> Token validation in this repository uses a simple JWT check against `SECRET_KEY`. In production, store `SECRET_KEY` in Secret Manager and use Workload Identity / K8s secrets for injection.

---

## 🧭 Main Endpoints

| Method | Route | Description |
|--------|-------|-------------|
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

- **Docker Compose**
```bash
docker compose down -v
```
(`-v` removes the PostgreSQL volume.)

- **Python venv**
```bash
deactivate
rm -rf venv
```

---

## 🧠 Technical Notes

- Fully **asynchronous stack** using `asyncpg` and SQLAlchemy async ORM  
- Custom middleware that generates a unique `correlation_id` per request  
- Basic `Bearer token` protection  
- Conflict handling using `request_timestamp`  
- Ready to be deployed on GKE with Helm (Cloud SQL private IP / proxy, Redis, K8s Secrets)