# Common developer + ops commands.
APP_DIR   := app
IMAGE     := cloud-platform
VERSION   ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)

.PHONY: help install run test lint docker-build docker-run \
        infra-up infra-down tf-validate k8s-render \
        argocd-install monitoring-install security-scan

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  %-18s %s\n", $$1, $$2}'

## ---- App ----
install: ## Install Python dev dependencies
	cd $(APP_DIR) && pip install -r requirements-dev.txt

run: ## Run the app locally on :8080
	cd $(APP_DIR) && uvicorn main:app --reload --port 8080

test: ## Run tests
	cd $(APP_DIR) && pytest -v

lint: ## Lint the app
	cd $(APP_DIR) && ruff check .

## ---- Docker ----
docker-build: ## Build the container image
	cd $(APP_DIR) && docker build --build-arg VERSION=$(VERSION) -t $(IMAGE):$(VERSION) .

docker-run: docker-build ## Build then run the image
	docker run --rm -p 8080:8080 $(IMAGE):$(VERSION)

## ---- Infra (Terraform) ----
infra-up: ## terraform apply (creates AWS infra - costs money)
	cd infra && terraform init && terraform apply

infra-down: ## terraform destroy (stops billing)
	cd infra && terraform destroy

tf-validate: ## Validate Terraform
	cd infra && terraform init -backend=false && terraform validate

## ---- Kubernetes / GitOps ----
k8s-render: ## Preview rendered manifests (dev overlay)
	kubectl kustomize k8s/overlays/dev

argocd-install: ## Install ArgoCD + bootstrap the project
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl apply -f argocd/project.yaml -f argocd/root-app.yaml

## ---- Monitoring ----
monitoring-install: ## Install kube-prometheus-stack + app monitoring
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f monitoring/values.yaml
	kubectl apply -f monitoring/servicemonitor.yaml -f monitoring/prometheus-rules.yaml -f monitoring/grafana-dashboard.yaml

## ---- Security ----
security-scan: ## Run Trivy fs + config scans locally (needs trivy)
	trivy fs --scanners vuln,secret --severity HIGH,CRITICAL .
	trivy config --severity HIGH,CRITICAL .
