# Data Engineer Local Testing Infrastructure

A Docker-based local testing environment for PySpark development with integrated services.

## Services

- **PySpark Notebook**: Jupyter notebook with PySpark, Delta Lake, and AWS SDK
- **LocalStack**: Local AWS services (S3, SSM, Lambda)
- **MongoDB**: Document database
- **Delta Lake**: Storage layer for data lakes (installed in PySpark container)

## Prerequisites

- Docker
- Docker Compose
- Make (optional, for convenience commands)

## Quick Start

1. **Copy environment file:**
   ```bash
   cp env.example env
   ```

2. **Build and run:**
   ```bash
   make build
   make run CONTAINER_NAME=dev
   ```

3. **Access services:**
   - Jupyter Notebook: http://localhost:10000
   - Spark UI: http://localhost:4040
   - LocalStack: http://localhost:4566
   - MongoDB: localhost:27017

## Usage

- **Build images:** `make build`
- **Run containers:** `make run CONTAINER_NAME=<name>`
- **Delete containers:** `make delete CONTAINER_NAME=<name>`
- **View help:** `make help`

## Project Structure

```
.
├── docker-compose.yml    # Service definitions
├── Dockerfile            # PySpark notebook image
├── Makefile              # Convenience commands
├── requirements.txt      # Python dependencies
├── env.example          # Environment variables template
└── examples/            # Example notebooks
```

## Notes

- Delta tables are stored in `/home/jovyan/delta` (persisted via volume)
- LocalStack S3 endpoint: `http://localstack:4566`
- All data volumes are stored in `./volumes/` directory
