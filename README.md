# Cloud-Native CI/CD Platform on AWS EKS

An end-to-end DevOps project demonstrating the full software delivery lifecycle:
a containerized Go microservice built, tested, scanned, and shipped through
GitHub Actions, provisioned on **AWS EKS** with **Terraform**, deployed via
**GitOps (ArgoCD)**, and observed with **Prometheus + Grafana**.

> Built as a portfolio project to showcase production-grade DevOps practices.

## Architecture

```mermaid
flowchart TD
    Dev["👩‍💻 Developer<br/>write code · git push"] --> CI

    subgraph GH["GitHub Actions — CI"]
        CI["test → lint → Trivy scan → build image"]
    end

    CI -->|push image| ECR["Amazon ECR<br/>container registry"]

    subgraph AWS["AWS Cloud — provisioned by Terraform (VPC · IAM)"]
        ECR --> Argo["ArgoCD — GitOps<br/>syncs Git → cluster"]
        Argo -->|auto-deploy| EKS
        subgraph EKS["AWS EKS cluster (Kubernetes)"]
            App["Deployment + Service<br/>Ingress + HPA"]
            Prom["Prometheus"] --> Graf["Grafana<br/>dashboards & alerts"]
            App -->|scrape metrics| Prom
        end
    end
```

**Flow:** you push code → CI tests, scans, and builds a container → the image lands in
Amazon ECR → ArgoCD notices and deploys it to the EKS cluster → Prometheus scrapes
metrics and Grafana visualizes them. No manual steps after `git push`.

## Tech stack

| Layer          | Tool                          |
|----------------|-------------------------------|
| Application    | Python (FastAPI + Prometheus) |
| Containers     | Docker (multi-stage)          |
| CI             | GitHub Actions                |
| Registry       | Amazon ECR                    |
| IaC            | Terraform                     |
| Orchestration  | AWS EKS (Kubernetes)          |
| CD / GitOps    | ArgoCD                        |
| Observability  | Prometheus + Grafana          |
| Security       | Trivy image scanning          |

## Repository layout

```
.
├── app/            # Go microservice + Dockerfile
├── .github/        # CI workflows
├── infra/          # Terraform: VPC, EKS, ECR, IAM
├── k8s/            # Kubernetes manifests (Kustomize)
├── argocd/         # ArgoCD Application definitions
├── monitoring/     # Prometheus + Grafana config
└── Makefile        # Common commands
```

## Build phases

- [x] **Phase 1** — App, Docker, CI pipeline
- [x] **Phase 2** — Terraform infra (VPC, EKS, ECR, GitHub OIDC)
- [ ] **Phase 3** — Kubernetes manifests (Kustomize)
- [ ] **Phase 4** — GitOps with ArgoCD
- [ ] **Phase 5** — Monitoring (Prometheus + Grafana)
- [ ] **Phase 6** — Polish, diagrams, DevSecOps

## Cost control

EKS incurs cost while running (~$0.10/hr control plane + node costs). Provision
only when demoing:

```bash
make infra-up      # terraform apply
make infra-down    # terraform destroy  — run when done to stop billing
```

## Quick start (local)

```bash
make install       # install Python deps (use a virtualenv)
make run           # run the app locally on :8080
make test          # run tests
make docker-build  # build the container image
curl localhost:8080/healthz
curl localhost:8080/metrics
```
