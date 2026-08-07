"""Cloud-platform microservice.

A small FastAPI service used to demonstrate a full CI/CD + GitOps +
observability pipeline. Exposes health/readiness probes for Kubernetes
and Prometheus metrics for monitoring.
"""
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)

VERSION = os.getenv("APP_VERSION", "dev")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage startup/shutdown. On shutdown, flip readiness to False so the
    load balancer drains this pod before the process exits."""
    global _ready
    _ready = True
    yield
    _ready = False


app = FastAPI(title="cloud-platform", version=VERSION, lifespan=lifespan)

# --- Prometheus metrics ---------------------------------------------------
HTTP_REQUESTS = Counter(
    "app_http_requests_total",
    "Total number of HTTP requests.",
    ["path", "method", "status"],
)
HTTP_DURATION = Histogram(
    "app_http_request_duration_seconds",
    "HTTP request latency in seconds.",
    ["path", "method"],
)

# Readiness flag; flipped to False during shutdown so the load balancer
# stops routing traffic before the process exits.
_ready = True


@app.middleware("http")
async def record_metrics(request: Request, call_next):
    """Record request count and latency for every request."""
    start = time.perf_counter()
    response = await call_next(request)
    elapsed = time.perf_counter() - start

    path = request.url.path
    HTTP_REQUESTS.labels(path, request.method, response.status_code).inc()
    HTTP_DURATION.labels(path, request.method).observe(elapsed)
    return response


@app.get("/")
async def root():
    return {
        "service": "cloud-platform",
        "version": VERSION,
        "message": "hello from the CI/CD pipeline",
    }


@app.get("/healthz")
async def healthz():
    """Liveness probe: process is up."""
    return {"status": "ok"}


@app.get("/readyz")
async def readyz():
    """Readiness probe: ready to serve traffic."""
    if not _ready:
        return JSONResponse(
            status_code=503, content={"status": "draining"}
        )
    return {"status": "ready"}


@app.get("/metrics")
async def metrics():
    """Prometheus scrape endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
