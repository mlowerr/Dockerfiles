# AI Coding Agents Docker Image

An Ubuntu 24.04 development image containing a broad set of terminal coding agents, their shared toolchains, and common repository-inspection utilities. The image runs as a configurable non-root user and does not contain credentials or mount the host Docker socket by default.

## Included coding harnesses

| Harness | Command | Install channel | State/config path |
|---|---|---|---|
| OpenAI Codex CLI | `codex` | npm | `~/.codex` |
| Claude Code | `claude` | official installer | `~/.claude` |
| Google Gemini CLI | `gemini` | npm | `~/.config/gemini` |
| xAI Grok CLI | `grok` | npm | `~/.grok` |
| OpenCode | `opencode` | npm | `~/.config/opencode` |
| Qwen Code | `qwen` | npm | tool-managed |
| Crush | `crush` | npm | tool-managed |
| Aider | `aider` | isolated uv tool | tool-managed |
| Kimi Code CLI | `kimi` | official installer | `~/.kimi` |
| Goose | `goose` | official release installer | tool-managed |
| Pi | `pi` | npm | `~/.pi` |
| Hermes Agent | `hermes` | official installer | `~/.hermes` |
| OpenClaw | `openclaw` | npm | `~/.openclaw` |
| GitHub Copilot CLI | `copilot` | npm | `~/.copilot` |
| OpenHands CLI | `openhands` | isolated uv tool | `~/.openhands` |
| Amp | `amp` | official installer | tool-managed |
| Cursor Agent | `agent` | official installer | `~/.cursor` |
| Factory Droid | `droid` | official installer | `~/.factory` |

This set keeps every harness previously in the image and adds actively maintained, standalone terminal agents. Kiro, Continue, Cline, Roo Code, and SWE-agent were not put in the default image: their primary distribution is editor-specific, benchmark-oriented, in transition, or not a generally available standalone Linux harness. They can be reconsidered when an official non-interactive Linux installer and stable CLI contract are available.

Every promised command must pass `scripts/verify-agents.sh` during the build; a missing or broken agent fails the image rather than being hidden by `|| true`. Resolved versions are stored at `~/.local/share/ai-agents/versions.txt`.

## Shared development tools

The image includes:

- Node.js 22, npm, Corepack, Python 3, `uv`, `uvx`, pipx, Git, Git LFS, and GitHub CLI.
- Docker CLI and the Compose plugin. There is no Docker daemon in the image.
- Compilers and native-extension prerequisites: `build-essential`, `make`, `pkg-config`, Python headers, and OpenSSL headers.
- Search and navigation tools: ripgrep, fd, fzf, bat, tree, jq, and sqlite3.
- Diagnostics and shell tools: ShellCheck, procps, lsof, netcat, DNS utilities, rsync, patch, tmux, screen, and Vim.

Python applications are installed into isolated `uv` environments instead of modifying Ubuntu's distribution-managed Python installation.

## Build

From the repository root:

```bash
docker build \
  --build-arg USERNAME="${AI_AGENTS_USERNAME:-matt}" \
  --build-arg UID="${AI_AGENTS_UID:-$(id -u)}" \
  --build-arg GID="${AI_AGENTS_GID:-$(id -g)}" \
  -t ai-coding-agents:latest \
  -f ai-coding-agents/Dockerfile \
  ai-coding-agents
```

The simple form uses the default `matt:1000:1000` image user:

```bash
docker build -t ai-coding-agents:latest ai-coding-agents
```

### Version policy and overrides

Fast-moving npm and Python agents default to the newest version available at build time. Each version is independently overridable, allowing CI or a release build to pin a tested set:

```bash
docker build \
  --build-arg CODEX_VERSION=1.2.3 \
  --build-arg PI_VERSION=1.2.3 \
  --build-arg OPENCLAW_VERSION=1.2.3 \
  --build-arg AIDER_VERSION=1.2.3 \
  -t ai-coding-agents:tested \
  ai-coding-agents
```

Available arguments are `CODEX_VERSION`, `GEMINI_VERSION`, `GROK_VERSION`, `OPENCODE_VERSION`, `QWEN_VERSION`, `CRUSH_VERSION`, `PI_VERSION`, `OPENCLAW_VERSION`, `COPILOT_VERSION`, `AIDER_VERSION`, and `OPENHANDS_VERSION`. Hermes can be sourced from a tested upstream ref using `HERMES_REF`.

Vendor-managed installers do not all publish version-addressable artifacts. The build uses their official TLS endpoints, immediately checks the resulting commands, and records the resolved versions. Use a no-cache build when you need to resolve every `latest` package again and exercise every live installer. Renovate groups dependency updates for review rather than silently changing a previously built image.

## Run

Mount a project into `/workspace` and start a shell:

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ai-coding-agents:latest
```

For a reusable container:

```bash
docker run -dit \
  --name ai-agents-dev \
  -v "$PWD":/workspace \
  -w /workspace \
  ai-coding-agents:latest

docker exec -it ai-agents-dev /bin/bash
```

Compose passes the configurable username and IDs into the build:

```bash
AI_AGENTS_UID=$(id -u) AI_AGENTS_GID=$(id -g) \
  docker compose -f ai-coding-agents/docker-compose.yml run --rm ai-agents
```

Copy `.env.example` to `.env` to persist those Compose settings locally.

## Authentication and persistence

No API keys, OAuth tokens, host configuration, or login caches are copied into the image. Authenticate from inside the container using each vendor's documented login command or pass its documented API-key environment variable at runtime:

```bash
docker run --rm -it \
  --env-file /path/to/private-agent.env \
  -v "$PWD":/workspace \
  ai-coding-agents:latest
```

Do not commit that environment file. Prefer short-lived credentials and pass only the variables required by the agent in use. Some OAuth flows print a device URL and code; open that URL on the host and finish the login there.

The default Compose configuration deliberately has no credential volumes. To retain container-created login state in Docker-managed named volumes, add the opt-in overlay:

```bash
AI_AGENTS_UID=$(id -u) AI_AGENTS_GID=$(id -g) \
  docker compose \
    -f ai-coding-agents/docker-compose.yml \
    -f ai-coding-agents/docker-compose.persistence.yml \
    run --rm ai-agents
```

The overlay persists the documented state directories without exposing existing host credentials. Vendor layouts can change; inspect a tool's current documentation before backing up or sharing its volume.

## Docker access and security

The included Docker CLI is inert unless connected to a daemon. Do **not** mount `/var/run/docker.sock` casually: control of the host daemon is effectively host-level access. The default Docker and Compose examples neither mount the socket nor run privileged.

OpenHands and other sandbox-oriented agents may offer container runtimes. Enabling one is an explicit runtime decision; it is not required for the image to start and must not be implemented by making this container privileged.

Agents can inspect files and execute commands in mounted repositories. Review their approval/sandbox settings, restrict mounted paths, and never bake secrets into an image layer.

## Architecture and verification

The Dockerfile uses packages and official installers expected to support `linux/amd64` and `linux/arm64`. Build and run the verifier on each architecture you plan to deploy; if an upstream project stops publishing one architecture, the verifier will fail rather than silently accepting a missing harness.

Local checks:

```bash
shellcheck ai-coding-agents/scripts/*.sh
docker build --check -f ai-coding-agents/Dockerfile ai-coding-agents
docker build -t ai-coding-agents:test ai-coding-agents
docker run --rm ai-coding-agents:test verify-agents
```

The build may need more time and disk than a language-specific development image because it intentionally combines many independent harnesses.

## Troubleshooting

- **A command is missing during build:** the upstream installer or package layout changed. Consult the failing verifier entry and the official project release notes; do not bypass it with `|| true`.
- **OAuth callback cannot open a browser:** use the displayed device URL on the host. If the vendor only supports a localhost callback, publish only the required port for the login session.
- **Files have the wrong ownership:** rebuild with host `UID` and `GID` arguments or populate `.env` for Compose.
- **An agent needs Docker:** connect to a deliberately isolated remote daemon or an explicitly accepted host socket; do not start a privileged Docker daemon in this image.
- **An ARM build fails:** verify that the named upstream agent publishes ARM64 artifacts. Keep it out of the ARM image rather than emulating or substituting an AMD64 binary silently.
