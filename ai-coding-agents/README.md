# AI Coding Agents Docker Image

This repository builds a Docker image for running several AI coding CLIs in a single Ubuntu-based development container.

Included tools:

- OpenAI Codex CLI
- Google Gemini CLI
- OpenCode
- Qwen Code
- Crush
- Aider
- Claude Code
- Kimi Code CLI
- Goose CLI
- GitHub CLI
- Node.js 22
- Python 3
- Common shell utilities such as `git`, `curl`, `ripgrep`, `jq`, and `sudo`

## Repository Contents

- `Dockerfile`: image definition
- `docker-compose.yml`: compose service for launching the container
- `.env.example`: example compose/build environment variables for username and UID/GID mapping
- `docker-build-basic.txt`: simple build command using default container user settings
- `docker-build-host-user.txt`: build command that maps the container user to your host username/UID/GID
- `docker-run.txt`: example disposable `docker run` command
- `docker-run-named.txt`: example named-container `docker run` command
- `docker-compose-run.txt`: example compose run command
- `docker-compose-up-build-detached.txt`: example compose `up --build -d` command

## Build

Use this when you want the simplest possible image build with the default container user settings:

```bash
docker build -t ai-coding-agents:latest -f ai-coding-agents/Dockerfile ai-coding-agents
```

See also: `ai-coding-agents/docker-build-basic.txt`

Use this when you want files created from inside the container to better match your host username, UID, and GID:

```bash
docker build --no-cache \
  --build-arg USERNAME=${AI_AGENTS_USERNAME:-matt} \
  --build-arg UID=${AI_AGENTS_UID:-$(id -u)} \
  --build-arg GID=${AI_AGENTS_GID:-$(id -g)} \
  -t ai-coding-agents:latest \
  -f ai-coding-agents/Dockerfile \
  ai-coding-agents
```

See also: `ai-coding-agents/docker-build-host-user.txt`

If you prefer, copy `ai-coding-agents/.env.example` to `ai-coding-agents/.env` and adjust the values before using the compose examples.

The image is based on `ubuntu:24.04` and sets up a non-root user, a writable npm global directory, and the installed CLIs during build time.
It also creates empty per-tool config directories in the container home directory so the CLIs can start without any host-mounted config.

## Run With Docker

Use this when you want a disposable interactive container for a quick session in the current project directory:

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ai-coding-agents:latest
```

This starts an interactive shell in `/workspace` with your current directory mounted into the container.

Use this when you want a reusable named container that you can stop, start, and re-enter later:

```bash
docker run -dit \
  --name ai-agents-dev \
  -v "$PWD":/workspace \
  -w /workspace \
  ai-coding-agents:latest
```

See also: `ai-coding-agents/docker-run-named.txt`

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

Current compose behavior:

- The service builds from `ai-coding-agents/Dockerfile`
- It can pass through `AI_AGENTS_USERNAME`, `AI_AGENTS_UID`, and `AI_AGENTS_GID` as build args
- It mounts the current repository directory into `/workspace`
- It opens an interactive TTY session

### Compose Run

Use this when you want a one-off interactive session launched through Docker Compose with host UID/GID passed into the build:

```bash
AI_AGENTS_UID=$(id -u) AI_AGENTS_GID=$(id -g) docker compose -f ai-coding-agents/docker-compose.yml run --rm ai-agents
```

See also: `ai-coding-agents/docker-compose-run.txt`

### Compose Up

Start the compose service as a persistent background container:

```bash
AI_AGENTS_UID=$(id -u) AI_AGENTS_GID=$(id -g) docker compose -f ai-coding-agents/docker-compose.yml up -d ai-agents
```

Use this when you want a long-running Compose-managed container and also want Compose to rebuild the image first:

```bash
AI_AGENTS_UID=$(id -u) AI_AGENTS_GID=$(id -g) docker compose -f ai-coding-agents/docker-compose.yml up --build -d ai-agents
```

See also: `ai-coding-agents/docker-compose-up-build-detached.txt`

Open a shell in the running compose container:

```bash
docker compose -f ai-coding-agents/docker-compose.yml exec ai-agents /bin/bash
```

Stop the compose service without deleting the container:

```bash
docker compose -f ai-coding-agents/docker-compose.yml stop ai-agents
```

Start the stopped compose service again:

```bash
docker compose -f ai-coding-agents/docker-compose.yml start ai-agents
```

Stop and remove the compose container:

```bash
docker compose -f ai-coding-agents/docker-compose.yml down
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
