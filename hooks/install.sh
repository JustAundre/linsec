#!/usr/bin/env bash
# shellcheck shell=bash
#
# One-time setup: point git at the versioned hooks directory so every
# contributor runs the same checks. Run from anywhere inside the repo.





#
#   ./hooks/install.sh
#
# To uninstall:  git config --unset core.hooksPath

set -euo pipefail

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
	printf 'install-hooks: not inside a git repository\n' >&2
	exit 1
fi

git config core.hooksPath hooks

printf 'Installed: core.hooksPath -> hooks\n'
printf 'The pre-commit hook now checks staged shell scripts (syntax + whitespace).\n'
printf 'Run hooks/lint.sh --fix to auto-fix whitespace, or --strict to enforce shellcheck.\n'
