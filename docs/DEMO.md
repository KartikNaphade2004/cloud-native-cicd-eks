# End-to-end demo runbook

Bring the whole platform up on AWS, deploy the app via GitOps, watch it on
Grafana, then tear it all down. Great to rehearse before an interview.

> 💰 **Cost:** the EKS cluster bills while running. Do the whole run in one
> sitting and `terraform destroy` at the end. Budget ~$1–2 for an hour.

## Prerequisites

- AWS account + `aws configure` done
- `terraform`, `kubectl`, `helm`, `docker` installed

## 1. Provision the infrastructure (~15 min)

```bash
cd infra
terraform init
terraform apply            # creates VPC, EKS, ECR, GitHub OIDC role
aws eks update-kubeconfig --region us-east-1 --name cloud-native-cicd-dev
kubectl get nodes          # should list the worker nodes
```

Note the outputs: `ecr_repository_url` and `github_ci_role_arn`.

## 2. Wire CI to push images

Add `github_ci_role_arn` as a repo secret named `AWS_ROLE_ARN`
(GitHub → Settings → Secrets and variables → Actions). Push any change to
`app/` — CI builds, scans, and pushes the image to ECR automatically.

## 3. Install the platform add-ons

```bash
# GitOps
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server

# Monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update
kubectl create namespace monitoring
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f monitoring/values.yaml
```

## 4. Deploy the app via GitOps

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/root-app.yaml
# ArgoCD now deploys k8s/overlays/dev and prod automatically
kubectl get applications -n argocd
kubectl get pods -n cloud-platform-dev -w
```

## 5. Observe

```bash
# App metrics + alerts + dashboard:
kubectl apply -f monitoring/servicemonitor.yaml -f monitoring/prometheus-rules.yaml -f monitoring/grafana-dashboard.yaml

kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# open http://localhost:3000 -> "Cloud Platform - App Overview"
```

## 6. The money shot: GitOps self-heal

```bash
# Manually scale the deployment - ArgoCD will revert it within seconds.
kubectl -n cloud-platform-dev scale deploy/cloud-platform --replicas=5
watch kubectl -n cloud-platform-dev get pods    # back to 1, as defined in Git
```

## 7. Tear down (stop billing!)

```bash
kubectl delete -f argocd/root-app.yaml
cd infra && terraform destroy
```
