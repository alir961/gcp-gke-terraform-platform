FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Fixed numeric IDs so Kubernetes can enforce runAsNonRoot.
RUN addgroup --system --gid 10001 app && adduser --system --uid 10001 --ingroup app --home /app app

COPY --chown=app:app . .

EXPOSE 8080

USER 10001

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
