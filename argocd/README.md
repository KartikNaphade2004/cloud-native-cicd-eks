# GitOps with ArgoCD

ArgoCD continuously reconciles the cluster to match Git. After this is set up,
**deploying = merging to `main`** — no manual `kubectl apply`.

```
argocd/
├── project.yaml       # AppProject: guardrails (allowed repo, destinations)
├── root-app.yaml      # "app of apps" — manages everything below
└── apps/
    ├── dev.yaml       # Application -> k8s/overlays/dev
    └── prod.yaml      # Application -> k8s/overlays/prod
```

## How it works

```
git push  ──>  ArgoCD notices new commit  ──>  syncs cluster to match Git
                                               (prune removed, self-heal drift)
```

- **`prune: true`** — anything deleted from Git is deleted from the cluster.
- **`selfHeal: true`** — if someone edits the cluster by hand, ArgoCD reverts it.
- **app-of-apps** — apply `root-app.yaml` once; it pulls in `apps/dev.yaml` and
  `apps/prod.yaml`, so new environments are just new files in `apps/`.

## Install ArgoCD (once, after the cluster exists)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server
```

## Bootstrap this project

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/root-app.yaml
```

That's it — ArgoCD now deploys `dev` and `prod` and keeps them in sync.

## Open the ArgoCD UI

```bash
# initial admin password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
# port-forward the UI to your laptop:
kubectl -n argocd port-forward svc/argocd-server 8081:443
# then open https://localhost:8081  (user: admin)
```

## The demo that wins interviews

1. Change something in `k8s/` (e.g. bump replicas) and `git push`.
2. Watch ArgoCD auto-sync the change in the UI — no manual deploy.
3. Delete a pod or edit the Deployment by hand → ArgoCD **self-heals** it back.
