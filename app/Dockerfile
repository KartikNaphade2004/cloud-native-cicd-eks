# ---- Build stage ----
# Install dependencies into a venv so we can copy only what's needed.
FROM python:3.12-slim AS build

WORKDIR /app
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install -r requirements.txt

# ---- Runtime stage ----
FROM python:3.12-slim

# Create a non-root user to run the app.
RUN useradd --create-home --uid 10001 appuser

WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Copy the prepared virtualenv and the application code.
COPY --from=build /opt/venv /opt/venv
COPY main.py .

ARG VERSION=dev
ENV APP_VERSION=${VERSION}

USER appuser
EXPOSE 8080

# Bind to 0.0.0.0 so the container is reachable; single worker is fine and
# horizontal scaling is handled by Kubernetes.
ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
