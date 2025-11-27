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
   
   Or for notebook only (no dependencies):
   ```bash
   make build-notebook
   ```

3. **Access services:**
   - Jupyter Notebook: http://localhost:10000
   - Spark UI: http://localhost:4040
   - LocalStack: http://localhost:4566
   - MongoDB: localhost:27017

## Usage

- **Build images:** `make build`
- **Run all services:** `make run CONTAINER_NAME=<name>` (starts notebook + mongodb + localstack)
- **Build and start notebook only:** `make build-notebook` (rebuilds image, no dependencies)
- **Start notebook only:** `make run-notebook` (no build, assumes image exists, no dependencies)
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
├── spark-defaults.conf   # Spark configuration with metrics enabled
└── examples/            # Example notebooks
```

## Spark Metrics Configuration

The Docker image is configured with comprehensive metrics collection enabled by default. The `spark-defaults.conf` file includes:

### Enabled Metrics

- **Executor Metrics**: CPU, memory, disk I/O, and network metrics per executor
- **Storage Metrics**: Disk usage, memory usage, and block manager statistics
- **Cache Metrics**: Cache hits/misses, cache size, and storage levels
- **Arrow Metrics**: Arrow-based columnar data transfer metrics (when using Arrow operations)
- **Process Tree Metrics**: Detailed CPU and memory metrics per process

### Accessing Metrics

1. **Spark UI**: Open http://localhost:4040 in your browser after starting a Spark session
   - **Executors Tab**: View detailed executor metrics (CPU, memory, disk, network)
   - **Storage Tab**: View cached RDDs/DataFrames, memory/disk usage
   - **SQL Tab**: View Arrow execution metrics (when applicable)
   - **Jobs/Stages Tabs**: Enhanced task-level metrics

2. **Event Logs**: Event logs are stored in `/home/jovyan/work/spark-events` and persisted in `./volumes/pyspark/spark-events/`

### Configuration File

The `spark-defaults.conf` file is automatically copied to the Spark installation during Docker build. All Spark sessions will use these configurations by default. You can override specific settings in your SparkSession builder if needed.

## Notes

- Delta tables are stored in `/home/jovyan/delta` (persisted via volume)
- LocalStack S3 endpoint: `http://localstack:4566`
- All data volumes are stored in `./volumes/` directory
- Spark event logs are stored in `./volumes/pyspark/spark-events/` (persisted via volume)
