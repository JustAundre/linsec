#!/usr/bin/env bash
# One-time setup: point git at the versioned hooks directory so every
# contributor runs the same checks. Run from anywhere inside the repo.
set -euo pipefail
cd "$(dirname "${0}")" || exit 1
if ! git rev-parse --show-toplevel &>/dev/null; then
	echo "E: ${0}: not inside a git repository" >&2
	exit 1
fi
git config --unset core.hooksPath
