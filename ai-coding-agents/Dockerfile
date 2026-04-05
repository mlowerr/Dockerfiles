FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# ---- base packages ----
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
    python3-pip \
    python3-venv \
    ripgrep \
    sudo \
    unzip \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# ---- Node.js 22 ----
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---- GitHub CLI ----
RUN mkdir -p /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# ---- container user matching WSL user ----
ARG USERNAME=matt
ARG UID=1000
ARG GID=1000

RUN set -eux; \
    EXISTING_GROUP="$(getent group "${GID}" | cut -d: -f1 || true)"; \
    if [ -z "${EXISTING_GROUP}" ]; then \
        groupadd --gid "${GID}" "${USERNAME}"; \
        EXISTING_GROUP="${USERNAME}"; \
    elif [ "${EXISTING_GROUP}" != "${USERNAME}" ]; then \
        groupmod -n "${USERNAME}" "${EXISTING_GROUP}"; \
    fi; \
    EXISTING_USER="$(getent passwd "${UID}" | cut -d: -f1 || true)"; \
    if [ -n "${EXISTING_USER}" ] && [ "${EXISTING_USER}" != "${USERNAME}" ]; then \
        usermod -l "${USERNAME}" "${EXISTING_USER}"; \
    elif [ -z "${EXISTING_USER}" ] && ! id -u "${USERNAME}" >/dev/null 2>&1; then \
        useradd --uid "${UID}" --gid "${GID}" -m -s /bin/bash "${USERNAME}"; \
    fi; \
    usermod -d "/home/${USERNAME}" -m "${USERNAME}"; \
    usermod -g "${GID}" "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}; \
    chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /workspace
ENV HOME=/home/${USERNAME}
ENV PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:${PATH}"

RUN mkdir -p \
    "${HOME}/.npm-global" \
    "${HOME}/.codex" \
    "${HOME}/.claude" \
    "${HOME}/.config/gemini" \
    "${HOME}/.kimi" \
    && npm config set prefix "${HOME}/.npm-global"

# ---- install coding CLIs ----

# Codex CLI
RUN npm install -g @openai/codex

# Gemini CLI
RUN npm install -g @google/gemini-cli

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# Kimi Code CLI
RUN curl -LsSf https://code.kimi.com/install.sh | bash

RUN bash -lc '\
    echo "node: $(node --version)" && \
    echo "npm:  $(npm --version)" && \
    echo "git:  $(git --version)" && \
    echo "gh:   $(gh --version | head -n 1)" && \
    codex --version || true && \
    gemini --version || true && \
    claude --version || true && \
    kimi --version || true \
'

CMD ["/bin/bash"]
