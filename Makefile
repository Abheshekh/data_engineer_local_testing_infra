# Default container name if not provided
CONTAINER_NAME ?= default

# Generate timestamp in YYYY-MM-DD-HH-MM-SS format
TIMESTAMP := $(shell date +%Y-%m-%d-%H-%M-%S)
CONTAINER_TIMESTAMP := $(CONTAINER_NAME)-$(TIMESTAMP)

.PHONY: build run delete build-notebook run-notebook help

help:
	@echo "Available commands:"
	@echo "  make build                    - Build Docker images"
	@echo "  make run CONTAINER_NAME=<name> - Run ALL services (notebook + mongodb + localstack)"
	@echo "  make build-notebook          - Build and start ONLY pyspark-notebook (no dependencies)"
	@echo "  make run-notebook            - Start ONLY pyspark-notebook (no build, no dependencies)"
	@echo "  make delete CONTAINER_NAME=<name> - Delete containers by name pattern"
	@echo ""
	@echo "Examples:"
	@echo "  make run CONTAINER_NAME=dev"
	@echo "  make build-notebook"
	@echo "  make run-notebook"
	@echo "  make delete CONTAINER_NAME=dev"

build:
	@echo "Building Docker images..."
	docker-compose build

run:
	@echo "Running containers with name: $(CONTAINER_TIMESTAMP)"
	@echo "Checking for existing containers..."
	@mkdir -p volumes/pyspark volumes/s3 volumes/delta volumes/mongodb
	@docker ps -a --filter "name=pyspark-notebook-container-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@docker ps -a --filter "name=mongodb-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@echo "Starting new containers..."
	CONTAINER_TIMESTAMP=$(CONTAINER_TIMESTAMP) docker-compose --profile full-stack up -d
	@echo "Containers started successfully!"
	@echo "Jupyter Notebook: http://localhost:10000"
	@echo "MongoDB: localhost:27017"

build-notebook:
	@echo "Building and starting pyspark-notebook service (no dependencies)..."
	@mkdir -p volumes/pyspark volumes/delta
	CONTAINER_TIMESTAMP=$(CONTAINER_TIMESTAMP) docker compose -f 'docker-compose.yml' up -d --build 'pyspark-notebook'

run-notebook:
	@echo "Starting pyspark-notebook service (no dependencies)..."
	@mkdir -p volumes/pyspark volumes/delta
	CONTAINER_TIMESTAMP=$(CONTAINER_TIMESTAMP) docker compose -f 'docker-compose.yml' up -d 'pyspark-notebook'

delete:
	@echo "Deleting containers with name pattern: $(CONTAINER_NAME)"
	@docker ps -a --filter "name=pyspark-notebook-container-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@docker ps -a --filter "name=mongodb-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@echo "Containers deleted successfully!"
