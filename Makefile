# Default container name if not provided
CONTAINER_NAME ?= default

# Generate timestamp in YYYY-MM-DD-HH-MM-SS format
TIMESTAMP := $(shell date +%Y-%m-%d-%H-%M-%S)
CONTAINER_TIMESTAMP := $(CONTAINER_NAME)-$(TIMESTAMP)

.PHONY: build run delete help

help:
	@echo "Available commands:"
	@echo "  make build                    - Build Docker images"
	@echo "  make run CONTAINER_NAME=<name> - Run containers with timestamp"
	@echo "  make delete CONTAINER_NAME=<name> - Delete containers by name pattern"
	@echo ""
	@echo "Examples:"
	@echo "  make run CONTAINER_NAME=dev"
	@echo "  make delete CONTAINER_NAME=dev"

build:
	@echo "Building Docker images..."
	docker-compose build

run:
	@echo "Running containers with name: $(CONTAINER_TIMESTAMP)"
	@echo "Checking for existing containers..."
	@docker ps -a --filter "name=pyspark-notebook-container-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@docker ps -a --filter "name=mongodb-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@echo "Starting new containers..."
	CONTAINER_TIMESTAMP=$(CONTAINER_TIMESTAMP) docker-compose up -d
	@echo "Containers started successfully!"
	@echo "Jupyter Notebook: http://localhost:10000"
	@echo "MongoDB: localhost:27017"

delete:
	@echo "Deleting containers with name pattern: $(CONTAINER_NAME)"
	@docker ps -a --filter "name=pyspark-notebook-container-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@docker ps -a --filter "name=mongodb-$(CONTAINER_NAME)" --format "{{.Names}}" | xargs -r docker rm -f
	@echo "Containers deleted successfully!"
