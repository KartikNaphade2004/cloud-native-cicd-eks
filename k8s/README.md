# Kubernetes manifests (Kustomize)

How the app runs on the cluster. Organized as a shared **base** plus per-environment
**overlays** so dev and prod differ only where they need to.

```
k8s/
├── base/                 # shared definition of the app
│   ├── deployment.yaml   # pods, health probes, resource limits, security context
│   ├── service.yaml      # stable in-cluster address (ClusterIP)
│   ├── ingress.yaml      # public URL via AWS ALB
│   ├── hpa.yaml          # auto-scale on CPU (2 → 5 pods)
│   └── kustomization.yaml
└── overlays/
    ├── dev/              # 1 replica, APP_VERSION=dev, namespace cloud-platform-dev
    └── prod/            # 3 replicas, APP_VERSION=prod, namespace cloud-platform
```

## Highlights (production practices)

- **Health probes** — `livenessProbe` (`/healthz`) restarts a stuck pod;
  `readinessProbe` (`/readyz`) keeps traffic away until the pod is ready and during
  graceful shutdown.
- **Resource requests/limits** — lets the scheduler pack pods and HPA scale sanely.
- **Hardened security context** — non-root, read-only root filesystem, all Linux
  capabilities dropped, `seccomp: RuntimeDefault`.
- **Topology spread** — pods spread across nodes so one node failure isn't an outage.
- **HPA** — horizontal auto-scaling on CPU (needs metrics-server in-cluster).

## Preview the rendered manifests (no cluster needed)

```bash
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/prod
```

## Apply to a cluster (after Phase 2 `terraform apply`)

```bash
# point kubectl at the EKS cluster first (see infra/README.md)
kubectl apply -k k8s/overlays/dev
kubectl get pods -n cloud-platform-dev -w
```

> The `ingress.yaml` needs the **AWS Load Balancer Controller** installed in the
> cluster to provision the ALB. In Phase 4, ArgoCD applies these manifests for us
> automatically instead of running `kubectl apply` by hand.
