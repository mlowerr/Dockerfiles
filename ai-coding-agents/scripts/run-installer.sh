#!/usr/bin/env bash
set -euo pipefail

url=${1:?usage: run-installer URL [INTERPRETER]}
interpreter=${2:-bash}
installer=$(mktemp)
trap 'rm -f "${installer}"' EXIT

curl --fail --silent --show-error --location \
    --proto '=https' --tlsv1.2 \
    "${url}" --output "${installer}"

if [[ ! -s "${installer}" ]]; then
    printf 'Downloaded installer is empty: %s\n' "${url}" >&2
    exit 1
fi

# A vendor-published digest can be supplied by a pinned release build. Dynamic
# installer endpoints generally do not publish one, so TLS plus immediate smoke
# testing is the documented fallback rather than pretending the content is pinned.
if [[ -n "${INSTALLER_SHA256:-}" ]]; then
    printf '%s  %s\n' "${INSTALLER_SHA256}" "${installer}" | sha256sum --check --status
fi

"${interpreter}" "${installer}"
