#!/usr/bin/env bash
# One-time setup: point git at the versioned hooks directory so every
# contributor runs the same checks. Run from anywhere inside the repo.
set -e -u -o pipefail
BASE_DIR="$(dirname "$(realpath "${0}")")"
BASE_NAME="${0##*/}"
cd "${BASE_DIR}" || exit 1
if ! git rev-parse --show-toplevel &>/dev/null; then
	echo "E: ${BASE_NAME}: not inside a git repository" >&2
	exit 1
fi
git config core.hooksPath "${BASE_DIR}"
