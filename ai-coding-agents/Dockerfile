FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Base tooling
RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    less \
    openssh-client \
    python3 \
    python3-venv \
    python3-pip \
    ripgrep \
    sudo \
    unzip \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN set -eux; \
    EXISTING_GROUP="$(getent group "${GID}" | cut -d: -f1 || true)"; \
    if [ -z "${EXISTING_GROUP}" ]; then \
        groupadd --gid "${GID}" "${USERNAME}"; \
        EXISTING_GROUP="${USERNAME}"; \
    fi; \
    EXISTING_USER="$(getent passwd "${UID}" | cut -d: -f1 || true)"; \
    if [ -n "${EXISTING_USER}" ]; then \
        HOME_DIR="$(getent passwd "${EXISTING_USER}" | cut -d: -f6)"; \
        usermod -l "${USERNAME}" "${EXISTING_USER}"; \
        usermod -d "/home/${USERNAME}" -m "${USERNAME}" || true; \
        usermod -g "${GID}" "${USERNAME}"; \
        if [ "${HOME_DIR}" != "/home/${USERNAME}" ] && [ ! -d "/home/${USERNAME}" ]; then \
            mkdir -p "/home/${USERNAME}"; \
            chown "${UID}:${GID}" "/home/${USERNAME}"; \
        fi; \
    elif id -u "${USERNAME}" >/dev/null 2>&1; then \
        usermod -u "${UID}" -g "${GID}" "${USERNAME}"; \
    else \
        useradd --uid "${UID}" --gid "${GID}" -m -s /bin/bash "${USERNAME}"; \
    fi; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /workspace
ENV HOME=/home/${USERNAME}

# Make local bin paths visible
ENV PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:${PATH}"
RUN mkdir -p "${HOME}/.npm-global" \
    && npm config set prefix "${HOME}/.npm-global"

# Install Codex CLI
RUN npm install -g @openai/codex

# Install Gemini CLI
RUN npm install -g @google/gemini-cli

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install Kimi Code CLI
RUN curl -LsSf https://code.kimi.com/install.sh | bash

# Optional: sanity check versions during build
RUN bash -lc 'set -e; \
    codex --version || true; \
    gemini --version || true; \
    claude --version || true; \
    kimi --version || true'

CMD ["/bin/bash"]
