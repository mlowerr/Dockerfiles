#!/usr/bin/env bash
set -euo pipefail

output=${1:-/tmp/ai-agent-versions.txt}
mkdir -p "$(dirname "${output}")"
: > "${output}"

record() {
    local binary=$1
    shift
    if ! command -v "${binary}" >/dev/null 2>&1; then
        printf 'Required harness is missing: %s\n' "${binary}" >&2
        return 1
    fi

    local result version
    result=$("${binary}" "$@" 2>&1)
    version=${result%%$'\n'*}
    if [[ -z "${version}" ]]; then
        printf 'Harness returned no version information: %s\n' "${binary}" >&2
        return 1
    fi
    printf '%-12s %s\n' "${binary}" "${version}" | tee -a "${output}"
}

record codex --version
record gemini --version
record grok --version
record opencode --version
record qwen --version
record crush --version
record aider --version
record claude --version
record kimi --version
record goose --version
record pi --version
record openclaw --version
record copilot --version
record openhands --version
record hermes --version
record amp --version
record agent --version
record droid --version
