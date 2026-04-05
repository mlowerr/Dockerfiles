# AI Coding Agents Docker Image

This repository builds a Docker image for running several AI coding CLIs in a single Ubuntu-based development container.

Included tools:

- OpenAI Codex CLI
- Google Gemini CLI
- Claude Code
- Kimi Code CLI
- GitHub CLI
- Node.js 22
- Python 3
- Common shell utilities such as `git`, `curl`, `ripgrep`, `jq`, and `sudo`

## Repository Contents

- `Dockerfile`: image definition
- `docker-compose.yml`: compose service for launching the container
- `docker-build-cmd.txt` and `docker-build-command.txt`: example build commands
- `docker-run.txt`: example `docker run` command
- `docker-compose-cmd.txt`: example compose command

## Build

Basic build:

```bash
docker build -t ai-coding-agents:latest .
```

Recommended build that matches the container user to your host UID/GID:

```bash
docker build --no-cache \
  --build-arg USERNAME=matt \
  --build-arg UID=$(id -u) \
  --build-arg GID=$(id -g) \
  -t ai-coding-agents:latest .
```

The image is based on `ubuntu:24.04` and sets up a non-root user, a writable npm global directory, and the installed CLIs during build time.
It also creates empty per-tool config directories in the container home directory so the CLIs can start without any host-mounted config.

## Run With Docker

Disposable interactive session:

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ai-coding-agents:latest
```

This starts an interactive shell in `/workspace` with your current directory mounted into the container.

Named container you can stop and resume later:

```bash
docker run -dit \
  --name ai-agents-dev \
  -v "$PWD":/workspace \
  -w /workspace \
  ai-coding-agents:latest
```

Attach a shell to the running container:

```bash
docker exec -it ai-agents-dev /bin/bash
```

Stop the container without removing it:

```bash
docker stop ai-agents-dev
```

Start the existing container again:

```bash
docker start ai-agents-dev
```

Start it and attach immediately:

```bash
docker start -ai ai-agents-dev
```

Remove the container when you no longer need it:

```bash
docker rm -f ai-agents-dev
```

## Run With Docker Compose

Ephemeral interactive session:

```bash
docker compose run --rm ai-agents
```

Current compose behavior:

- The service mounts the repository into `/workspace`
- It opens an interactive TTY session

Start the compose service as a persistent background container:

```bash
docker compose up -d ai-agents
```

Open a shell in the running compose container:

```bash
docker compose exec ai-agents /bin/bash
```

Stop the compose service without deleting the container:

```bash
docker compose stop ai-agents
```

Start the stopped compose service again:

```bash
docker compose start ai-agents
```

Stop and remove the compose container:

```bash
docker compose down
```

## Tool Configuration

By default, the container does not mount host configuration directories for Codex, Claude, Gemini, or Kimi.
The image creates these directories inside the container instead:

- `~/.codex`
- `~/.claude`
- `~/.config/gemini`
- `~/.kimi`

If you want persistent sign-in state later, you can still mount specific config directories intentionally, but it is no longer part of the default runtime setup.

## Default Container Behavior

The container starts with:

```bash
/bin/bash
```

The working directory is:

```bash
/workspace
```

## Typical Workflow

1. Build the image
2. For throwaway sessions, use `docker run --rm -it` or `docker compose run --rm`
3. For a reusable environment, create a named container with `docker run -dit --name ...` or `docker compose up -d`
4. Re-enter a running container with `docker exec -it ... /bin/bash` or `docker compose exec`
5. Sign in to any CLI you want to use from inside the container
6. Work inside `/workspace`

## Notes

- `build.log` appears to be a captured Docker build log and is not required for normal usage
- Matching the container user to the host UID/GID via build args is workable but more custom than a typical fixed-user Docker image
