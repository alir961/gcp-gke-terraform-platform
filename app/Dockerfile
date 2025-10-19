FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN addgroup --system app && adduser --system --ingroup app --home /app app

COPY --chown=app:app . .

EXPOSE 8080

USER app

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
