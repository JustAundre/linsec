#!/usr/bin/env bash
set -e -u -o pipefail
BASE_DIR="$(dirname "$(realpath "${0}")")"
BASE_NAME="${0##*/}"
cd "${BASE_DIR}" || exit 1
if ! git rev-parse --show-toplevel &>/dev/null; then
	echo "E: ${BASE_NAME}: not inside a git repository" >&2
	exit 1
fi
git config --unset core.hooksPath
