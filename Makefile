# Common developer + ops commands.
APP_DIR   := app
IMAGE     := cloud-platform
VERSION   ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)

.PHONY: install run test lint docker-build docker-run infra-up infra-down

## App
install:
	cd $(APP_DIR) && pip install -r requirements-dev.txt

run:
	cd $(APP_DIR) && uvicorn main:app --reload --port 8080

test:
	cd $(APP_DIR) && pytest -v

lint:
	cd $(APP_DIR) && ruff check .

## Docker
docker-build:
	cd $(APP_DIR) && docker build --build-arg VERSION=$(VERSION) -t $(IMAGE):$(VERSION) .

docker-run: docker-build
	docker run --rm -p 8080:8080 $(IMAGE):$(VERSION)

## Infra (Phase 2)
infra-up:
	cd infra && terraform init && terraform apply -auto-approve

infra-down:
	cd infra && terraform destroy -auto-approve
