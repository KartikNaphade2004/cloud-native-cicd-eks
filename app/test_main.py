"""Unit tests for the cloud-platform service."""
import main
from fastapi.testclient import TestClient

client = TestClient(main.app)


def test_healthz():
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    body = resp.json()
    assert body["service"] == "cloud-platform"


def test_readyz_ready():
    main._ready = True
    resp = client.get("/readyz")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ready"


def test_readyz_draining():
    main._ready = False
    resp = client.get("/readyz")
    assert resp.status_code == 503
    main._ready = True  # restore for other tests


def test_metrics_exposed():
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert "app_http_requests_total" in resp.text
