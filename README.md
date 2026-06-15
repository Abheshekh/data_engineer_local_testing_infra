# Data Engineer Local Testing Infrastructure

A Docker-based local testing environment for PySpark development with integrated services.

## Services

- **PySpark Notebook**: Jupyter notebook with PySpark, Delta Lake, and AWS SDK
- **LocalStack**: Local AWS services (S3, SSM, Lambda)
- **MongoDB**: Document database
- **Delta Lake**: Storage layer for data lakes (installed in PySpark container)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- Make (optional, for convenience commands)
- A free [LocalStack account](https://app.localstack.cloud/sign-up) (required for AWS emulation)

## LocalStack Setup (Get Your Auth Token)

LocalStack requires an auth token to run. Follow these steps once before your first run:

1. **Register** at [https://app.localstack.cloud/sign-up](https://app.localstack.cloud/sign-up)
2. **Log in** and navigate to **Workspace → Auth Token** in the left sidebar
3. **Copy** the token shown on that page
4. **Set it** in your local `.env` file:
   ```bash
   make setup          # copies env.example → .env
   ```
   Then open `.env` and replace `your-localstack-auth-token-here` with your actual token:
   ```
   LOCALSTACK_AUTH_TOKEN=ls-xxxx-xxxx-xxxx-xxxx
   ```

> The token is tied to your LocalStack account. Keep it out of version control — `.env` is already in `.gitignore`.

## Quick Start

1. **Run interactive setup** (first time only):
   ```bash
   make setup
   ```
   This will ask you for:
   - **Notebook work path** — a local directory that maps to `/home/jovyan/work` in the container (e.g. `~/Documents/my-projects`)
   - **Volumes base path** — a local directory where `s3/`, `delta/`, `mongodb/` subdirectories will be created (e.g. `~/Documents/volumes`)
   - **LocalStack auth token** — paste your token from [localstack.cloud](https://app.localstack.cloud) → Workspace → Auth Token

   It creates the directories, writes them to `.env`, and prints next steps.

2. **Build images:**
   ```bash
   make build
   ```

3. **Run all services:**
   ```bash
   make run CONTAINER_NAME=dev
   ```

   Or for notebook only (no LocalStack/MongoDB):
   ```bash
   make build-notebook
   ```

4. **Access services:**
   - Jupyter Notebook: http://localhost:10000
   - Spark UI: http://localhost:4040
   - LocalStack: http://localhost:4566
   - MongoDB: localhost:27017

## Usage

| Command | Description |
|---------|-------------|
| `make setup` | Copy `env.example` → `.env` (skips if `.env` already exists) |
| `make build` | Build Docker images |
| `make run CONTAINER_NAME=<name>` | Run all services (notebook + mongodb + localstack) |
| `make build-notebook` | Build and start only pyspark-notebook |
| `make run-notebook` | Start only pyspark-notebook (no rebuild) |
| `make delete CONTAINER_NAME=<name>` | Delete containers by name pattern |
| `make help` | Show all available commands |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NOTEBOOK_WORK_PATH` | Local path mounted to `/home/jovyan/work` | `~/Documents/my-projects` |
| `VOLUMES_BASE_PATH` | Parent dir for `s3/`, `delta/`, `mongodb/` subdirs | `~/Documents/volumes` |
| `LOCALSTACK_AUTH_TOKEN` | Auth token from localstack.cloud dashboard | `ls-xxxx-xxxx` |
| `AWS_ACCESS_KEY_ID` | AWS key (keep as `test` for local use) | `test` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret (keep as `test` for local use) | `test` |
| `AWS_DEFAULT_REGION` | AWS region | `us-west-2` |
| `MONGO_INITDB_ROOT_USERNAME` | MongoDB root username | `mongo_user` |
| `MONGO_INITDB_ROOT_PASSWORD` | MongoDB root password | `mongo_pass` |

## Project Structure

```
.
├── docker-compose.yml    # Service definitions
├── Dockerfile            # PySpark notebook image
├── Makefile              # Convenience commands
├── requirements.txt      # Python dependencies
├── env.example           # Environment variables template
└── examples/             # Example notebooks
```

## Spark Metrics Configuration

The Docker image is configured with comprehensive metrics collection enabled by default.

### Enabled Metrics

- **Executor Metrics**: CPU, memory, disk I/O, and network metrics per executor
- **Storage Metrics**: Disk usage, memory usage, and block manager statistics
- **Cache Metrics**: Cache hits/misses, cache size, and storage levels
- **Arrow Metrics**: Arrow-based columnar data transfer metrics
- **Process Tree Metrics**: Detailed CPU and memory metrics per process

### Accessing Metrics

1. **Spark UI** at http://localhost:4040:
   - **Executors Tab**: CPU, memory, disk, network per executor
   - **Storage Tab**: Cached RDDs/DataFrames, memory/disk usage
   - **SQL Tab**: Arrow execution metrics
   - **Jobs/Stages Tabs**: Task-level metrics

2. **Event Logs**: Stored in `./volumes/pyspark/spark-events/` (persisted via volume)

## Notes

- Delta tables are stored in `/home/jovyan/delta` inside the container (persisted via volume)
- LocalStack S3 endpoint for use inside notebooks: `http://localstack:4566`
- All data volumes are stored in `./volumes/` directory (excluded from git)
