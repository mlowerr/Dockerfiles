# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Chicago

# ---- base packages and common agent tooling ----
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash bat build-essential ca-certificates curl direnv dnsutils fd-find file \
        fzf git git-lfs gnupg jq less libssl-dev locales lsof make \
        netcat-openbsd openssh-client patch pipx pkg-config pre-commit procps \
        python3 python3-dev python3-pip python3-venv ripgrep rsync screen \
        shellcheck sqlite3 sudo tmux tree unzip vim wget xz-utils zip \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ---- Node.js 22 ----
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && rm -rf /var/lib/apt/lists/*

# ---- GitHub CLI ----
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# ---- Docker client only (the host socket is never mounted by default) ----
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
      > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# ---- container user matching the host user ----
ARG USERNAME=matt
ARG UID=1000
ARG GID=1000

RUN set -eux; \
    existing_group="$(getent group "${GID}" | cut -d: -f1 || true)"; \
    if [[ -z "${existing_group}" ]]; then \
        groupadd --gid "${GID}" "${USERNAME}"; \
    elif [[ "${existing_group}" != "${USERNAME}" ]]; then \
        groupmod -n "${USERNAME}" "${existing_group}"; \
    fi; \
    existing_user="$(getent passwd "${UID}" | cut -d: -f1 || true)"; \
    if [[ -n "${existing_user}" && "${existing_user}" != "${USERNAME}" ]]; then \
        usermod -l "${USERNAME}" "${existing_user}"; \
    elif [[ -z "${existing_user}" ]] && ! id -u "${USERNAME}" >/dev/null 2>&1; then \
        useradd --uid "${UID}" --gid "${GID}" -m -s /bin/bash "${USERNAME}"; \
    fi; \
    usermod -d "/home/${USERNAME}" -m "${USERNAME}"; \
    usermod -g "${GID}" "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    ln -sf /usr/bin/batcat /usr/local/bin/bat

COPY --chmod=0755 scripts/run-installer.sh scripts/verify-agents.sh /usr/local/bin/
RUN ln -s /usr/local/bin/verify-agents.sh /usr/local/bin/verify-agents

USER ${USERNAME}
WORKDIR /workspace
ENV HOME=/home/${USERNAME} \
    PATH=/home/${USERNAME}/.local/bin:/home/${USERNAME}/.npm-global/bin:/home/${USERNAME}/.amp/bin:/home/${USERNAME}/.cursor/bin:/home/${USERNAME}/.factory/bin:${PATH} \
    UV_UNMANAGED_INSTALL=/home/${USERNAME}/.local/bin

RUN mkdir -p \
      "${HOME}/.local/bin" "${HOME}/.npm-global" \
      "${HOME}/.codex" "${HOME}/.claude" "${HOME}/.config/gemini" \
      "${HOME}/.kimi" "${HOME}/.config/opencode" "${HOME}/.pi/agent" \
      "${HOME}/.hermes" "${HOME}/.openclaw" "${HOME}/.copilot" \
      "${HOME}/.openhands" "${HOME}/.amp" "${HOME}/.cursor" "${HOME}/.factory" \
    && npm config set prefix "${HOME}/.npm-global"

# Versions are build arguments so automation can test and advance them independently.
ARG CODEX_VERSION=latest
ARG GEMINI_VERSION=latest
ARG OPENCODE_VERSION=latest
ARG QWEN_VERSION=latest
ARG CRUSH_VERSION=latest
ARG PI_VERSION=latest
ARG OPENCLAW_VERSION=latest
ARG COPILOT_VERSION=latest
ARG AIDER_VERSION=latest
ARG OPENHANDS_VERSION=latest

# ---- npm-based coding harnesses ----
RUN npm install -g \
      "@openai/codex@${CODEX_VERSION}" \
      "@google/gemini-cli@${GEMINI_VERSION}" \
      "opencode-ai@${OPENCODE_VERSION}" \
      "@qwen-code/qwen-code@${QWEN_VERSION}" \
      "@charmland/crush@${CRUSH_VERSION}" \
      "@mariozechner/pi-coding-agent@${PI_VERSION}" \
      "openclaw@${OPENCLAW_VERSION}" \
      "@github/copilot@${COPILOT_VERSION}"

# ---- isolated Python tooling and harnesses ----
RUN run-installer https://astral.sh/uv/install.sh sh \
    && if [[ "${AIDER_VERSION}" == latest ]]; then \
         uv tool install --python python3 aider-chat; \
       else \
         uv tool install --python python3 "aider-chat==${AIDER_VERSION}"; \
       fi \
    && if [[ "${OPENHANDS_VERSION}" == latest ]]; then \
         uv tool install --python python3 openhands-ai; \
       else \
         uv tool install --python python3 "openhands-ai==${OPENHANDS_VERSION}"; \
       fi

# ---- official vendor installers ----
# Script-driven products do not all expose versioned artifacts. Each installer is
# downloaded over TLS from its canonical domain and the resulting binary is tested.
ARG HERMES_REF=main
RUN run-installer https://claude.ai/install.sh \
    && run-installer https://code.kimi.com/install.sh \
    && CONFIGURE=false run-installer \
      https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh \
    && run-installer \
      "https://raw.githubusercontent.com/NousResearch/hermes-agent/${HERMES_REF}/scripts/install.sh" \
    && run-installer https://ampcode.com/install.sh \
    && run-installer https://cursor.com/install \
    && run-installer https://app.factory.ai/cli

# Fail the build when any promised harness is unavailable, and retain an inventory.
RUN verify-agents "${HOME}/.local/share/ai-agents/versions.txt"

CMD ["/bin/bash"]
