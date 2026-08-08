# Cloud-Native CI/CD Platform on AWS EKS

[![CI](https://github.com/KartikNaphade2004/cloud-native-cicd-eks/actions/workflows/ci.yaml/badge.svg)](https://github.com/KartikNaphade2004/cloud-native-cicd-eks/actions/workflows/ci.yaml)
[![Security](https://github.com/KartikNaphade2004/cloud-native-cicd-eks/actions/workflows/security.yaml/badge.svg)](https://github.com/KartikNaphade2004/cloud-native-cicd-eks/actions/workflows/security.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

![Python](https://img.shields.io/badge/Python-FastAPI-3776AB?logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-multi--stage-2496ED?logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Kustomize-326CE5?logo=kubernetes&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-Grafana-E6522C?logo=prometheus&logoColor=white)

An end-to-end DevOps project demonstrating the full software delivery lifecycle:
a containerized Python (FastAPI) microservice built, tested, scanned, and shipped
through GitHub Actions, provisioned on **AWS EKS** with **Terraform**, deployed via
**GitOps (ArgoCD)**, and observed with **Prometheus + Grafana**.

> Built as a portfolio project to showcase production-grade DevOps practices.
> **▶ Full end-to-end demo runbook: [docs/DEMO.md](docs/DEMO.md)**

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
| Security       | Trivy + Checkov (image, deps, IaC) |

## Repository layout

```
.
├── app/            # Python (FastAPI) microservice + tests + Dockerfile
├── .github/        # CI + security workflows, Dependabot
├── infra/          # Terraform: VPC, EKS, ECR, GitHub OIDC/IAM
├── k8s/            # Kubernetes manifests (Kustomize base + overlays)
├── argocd/         # ArgoCD Applications (app-of-apps)
├── monitoring/     # Prometheus + Grafana + alerts
├── docs/           # End-to-end demo runbook
└── Makefile        # Common commands (run `make help`)
```

## Build phases

- [x] **Phase 1** — App, Docker, CI pipeline
- [x] **Phase 2** — Terraform infra (VPC, EKS, ECR, GitHub OIDC)
- [x] **Phase 3** — Kubernetes manifests (Kustomize base + dev/prod overlays)
- [x] **Phase 4** — GitOps with ArgoCD (app-of-apps)
- [x] **Phase 5** — Monitoring (Prometheus + Grafana + alerts)
- [x] **Phase 6** — Polish, badges, LICENSE, DevSecOps (Trivy/Checkov), demo runbook

**✅ All phases complete.** See **[docs/DEMO.md](docs/DEMO.md)** to run the whole
thing end-to-end on AWS.

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
