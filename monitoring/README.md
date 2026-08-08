# Monitoring (Prometheus + Grafana)

Turns the app's `/metrics` (built in Phase 1) into live dashboards and alerts,
using the standard **kube-prometheus-stack** (Prometheus Operator + Grafana +
Alertmanager).

```
monitoring/
├── values.yaml            # Helm values for kube-prometheus-stack
├── servicemonitor.yaml    # tells Prometheus to scrape the app
├── prometheus-rules.yaml  # alerts: high error rate, high latency, app absent
├── grafana-dashboard.yaml # auto-imported Grafana dashboard (ConfigMap)
└── README.md
```

## How it fits together

```
app /metrics  <──scrape──  Prometheus  ──queries──>  Grafana dashboard
                                │
                                └──> Alertmanager (fires alerts)
```

The app pods already expose `/metrics` and carry the `prometheus.io/*` annotations.
The `ServiceMonitor` makes the Prometheus Operator discover and scrape them.

## Install

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring
helm install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  -n monitoring -f monitoring/values.yaml

# app-specific scrape config, alerts, and dashboard:
kubectl apply -f monitoring/servicemonitor.yaml
kubectl apply -f monitoring/prometheus-rules.yaml
kubectl apply -f monitoring/grafana-dashboard.yaml
```

> Prefer GitOps? Point an ArgoCD Application at this folder instead of running
> `kubectl apply` by hand.

## Open Grafana

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# open http://localhost:3000  (user: admin, password: admin — change it!)
```

Find the dashboard under **Dashboards → Cloud Platform - App Overview**. It shows
request rate, 5xx error ratio, and p50/p95 latency.

## Generate some traffic for the graphs

```bash
# via the app's public ALB URL, or a local port-forward:
for i in $(seq 1 500); do curl -s localhost:8080/ >/dev/null; done
```
