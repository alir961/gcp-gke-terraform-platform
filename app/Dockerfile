FROM python:3.11-slim

# Set workdir
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY app/ ./app

# Copy env folder
COPY .env/ ./.env/

# Expose port
EXPOSE 8080

# Commande par défaut, ENV_FILE peut être surchargé
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port 8080"]
