# CLAUDE.md — Project Instructions for Claude Code

## On Project Open: Volume Path Check

**Always do this first when the user opens this project or asks about running it:**

1. Check whether `.env` exists and whether `NOTEBOOK_WORK_PATH` and `VOLUMES_BASE_PATH` are set to real paths (not the placeholder values `your-notebook-work-path-here` / `your-volumes-base-path-here`).

2. If either is missing or still a placeholder, **ask the user before doing anything else**:
   - "What local directory should map to the Jupyter notebook work folder (`/home/jovyan/work`)? For example: `~/Documents/my-projects`"
   - "What base directory should hold the data volumes (`s3/`, `delta/`, `mongodb/` will be subdirectories)? For example: `~/Documents/volumes`"

3. Once you have the answers:
   - If `.env` does not exist, copy `env.example` → `.env` first.
   - Update `NOTEBOOK_WORK_PATH` and `VOLUMES_BASE_PATH` in `.env` with the user's answers (expand `~` to the full home path).
   - Run `mkdir -p` to create the directories if they don't exist.
   - Tell the user the paths have been set.

4. If `LOCALSTACK_AUTH_TOKEN` is also still the placeholder (`your-localstack-auth-token-here`), remind the user to get their token from `https://app.localstack.cloud` → Workspace → Auth Token and paste it into `.env`.

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service definitions — uses `${NOTEBOOK_WORK_PATH}` and `${VOLUMES_BASE_PATH}` for volume mounts |
| `.env` | Local secrets and paths — never committed (in `.gitignore`) |
| `env.example` | Template for `.env` — committed, safe to read |
| `Makefile` | `make setup` runs an interactive terminal prompt for all paths |

## Common Tasks

- **First-time setup**: `make setup` (interactive) → `make build` → `make run CONTAINER_NAME=dev`
- **Notebook only** (no LocalStack/MongoDB): `make build-notebook`
- **Check config before run**: `make check-env` validates all required `.env` values

## Volume Mapping

| docker-compose.yml variable | `.env` key | Container path |
|-----------------------------|------------|----------------|
| `${NOTEBOOK_WORK_PATH}` | `NOTEBOOK_WORK_PATH` | `/home/jovyan/work` |
| `${VOLUMES_BASE_PATH}/s3` | `VOLUMES_BASE_PATH` | `/var/lib/localstack` |
| `${VOLUMES_BASE_PATH}/delta` | `VOLUMES_BASE_PATH` | `/home/jovyan/delta` |
| `${VOLUMES_BASE_PATH}/mongodb` | `VOLUMES_BASE_PATH` | `/data/db` |
