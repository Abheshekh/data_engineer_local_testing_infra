# Default container name if not provided
CONTAINER_NAME ?= 3.4.0

# Generate timestamp in YYYY-MM-DD-HH-MM-SS format
TIMESTAMP := $(shell date +%Y-%m-%d-%H-%M-%S)
CONTAINER_TIMESTAMP := $(CONTAINER_NAME)-$(TIMESTAMP)

.PHONY: build run delete build-notebook run-notebook setup check-env help

help:
	@echo "Available commands:"
	@echo "  make setup                         - Copy env.example to .env (skips if .env exists)"
	@echo "  make build                         - Build Docker images"
	@echo "  make run CONTAINER_NAME=<name>     - Run ALL services (notebook + mongodb + localstack)"
	@echo "  make build-notebook                - Build and start ONLY pyspark-notebook (no dependencies)"
	@echo "  make run-notebook                  - Start ONLY pyspark-notebook (no build, no dependencies)"
	@echo "  make delete CONTAINER_NAME=<name>  - Delete containers by name pattern"
	@echo ""
	@echo "First time? Run:"
	@echo "  make setup   # then edit .env and add your LOCALSTACK_AUTH_TOKEN"
	@echo "  make build"
	@echo "  make run CONTAINER_NAME=dev"
	@echo ""
	@echo "Get your LocalStack auth token at: https://app.localstack.cloud → Workspace → Auth Token"

setup:
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo ".env created from env.example."; \
	else \
		echo ".env already exists — will update any unset paths."; \
	fi
	@echo ""
	@echo "=== Volume Path Configuration ==="
	@echo "These local directories are mounted into the containers."
	@echo ""
	@printf "Notebook work path — maps to /home/jovyan/work\n(e.g. $(HOME)/Documents/my-projects)\n> "; \
	read val; \
	if [ -n "$$val" ]; then \
		sed -i '' "s|NOTEBOOK_WORK_PATH=.*|NOTEBOOK_WORK_PATH=$$val|" .env; \
		mkdir -p "$$val"; \
		echo "  -> NOTEBOOK_WORK_PATH=$$val"; \
	fi
	@printf "\nVolumes base path — s3/, delta/, mongodb/ will be created inside it\n(e.g. $(HOME)/Documents/volumes)\n> "; \
	read val; \
	if [ -n "$$val" ]; then \
		sed -i '' "s|VOLUMES_BASE_PATH=.*|VOLUMES_BASE_PATH=$$val|" .env; \
		mkdir -p "$$val/s3" "$$val/delta" "$$val/mongodb"; \
		echo "  -> VOLUMES_BASE_PATH=$$val"; \
	fi
	@echo ""
	@echo "=== LocalStack Auth Token ==="
	@echo "Get your token at: https://app.localstack.cloud -> Workspace -> Auth Token"
	@printf "Paste your LocalStack auth token (leave blank to skip): "; \
	read val; \
	if [ -n "$$val" ]; then \
		sed -i '' "s|LOCALSTACK_AUTH_TOKEN=.*|LOCALSTACK_AUTH_TOKEN=$$val|" .env; \
		echo "  -> LOCALSTACK_AUTH_TOKEN set."; \
	fi
	@echo ""
	@echo "Setup complete. Run 'make build && make run CONTAINER_NAME=dev' to start."

check-env:
	@if [ ! -f .env ]; then \
		echo "Error: .env not found. Run 'make setup' first."; exit 1; \
	fi
	@if grep -q "your-localstack-auth-token-here" .env 2>/dev/null; then \
		echo "Error: LOCALSTACK_AUTH_TOKEN is not set."; \
		echo "Get your token at: https://app.localstack.cloud -> Workspace -> Auth Token"; \
		exit 1; \
	fi
	@if grep -q "your-notebook-work-path-here" .env 2>/dev/null || grep -q "your-volumes-base-path-here" .env 2>/dev/null; then \
		echo "Error: Volume paths are not configured in .env."; \
		echo "Run 'make setup' to set NOTEBOOK_WORK_PATH and VOLUMES_BASE_PATH."; \
		exit 1; \
	fi

build:
	@echo "Building Docker images..."
	docker-compose build

run: check-env
	@echo "Running containers with name: $(CONTAINER_TIMESTAMP)"
	@echo "Checking for existing containers..."
	@VOLUMES_BASE_PATH=$$(grep '^VOLUMES_BASE_PATH=' .env | cut -d= -f2); \
	NOTEBOOK_WORK_PATH=$$(grep '^NOTEBOOK_WORK_PATH=' .env | cut -d= -f2); \
	mkdir -p "$$NOTEBOOK_WORK_PATH" "$$VOLUMES_BASE_PATH/s3" "$$VOLUMES_BASE_PATH/delta" "$$VOLUMES_BASE_PATH/mongodb"
	@docker ps -a --filter "name=pyspark-notebook-container-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@docker ps -a --filter "name=mongodb-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@echo "Starting new containers..."
	CONTAINER_TIMESTAMP=$(CONTAINER_TIMESTAMP) docker-compose --profile full-stack up -d
	@echo "Containers started successfully!"
	@echo "Jupyter Notebook: http://localhost:10000"
	@echo "MongoDB: localhost:27017"

build-notebook: check-env
	@echo "Building and starting pyspark-notebook service (no dependencies)..."
	@NOTEBOOK_WORK_PATH=$$(grep '^NOTEBOOK_WORK_PATH=' .env | cut -d= -f2); \
	VOLUMES_BASE_PATH=$$(grep '^VOLUMES_BASE_PATH=' .env | cut -d= -f2); \
	mkdir -p "$$NOTEBOOK_WORK_PATH" "$$VOLUMES_BASE_PATH/delta"
	CONTAINER_TIMESTAMP=$(CONTAINER_TIMESTAMP) docker compose -f 'docker-compose.yml' up -d --build 'pyspark-notebook'

run-notebook: check-env
	@echo "Starting pyspark-notebook service (no dependencies)..."
	@NOTEBOOK_WORK_PATH=$$(grep '^NOTEBOOK_WORK_PATH=' .env | cut -d= -f2); \
	VOLUMES_BASE_PATH=$$(grep '^VOLUMES_BASE_PATH=' .env | cut -d= -f2); \
	mkdir -p "$$NOTEBOOK_WORK_PATH" "$$VOLUMES_BASE_PATH/delta"
	CONTAINER_TIMESTAMP=$(CONTAINER_TIMESTAMP) docker compose -f 'docker-compose.yml' up -d 'pyspark-notebook'

delete:
	@echo "Deleting containers with name pattern: $(CONTAINER_NAME)"
	@docker ps -a --filter "name=pyspark-notebook-container-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@docker ps -a --filter "name=mongodb-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@echo "Containers deleted successfully!"
