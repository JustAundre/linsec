#!/usr/bin/env bash





#
# Environment Setup
#
set -u
MODE='all'
FIX=0
HELP_PATH="$(dirname "${0}")/standardize-perms.sh.help.md"
for arg in "${@}"; do
	case "${arg}" in
		--staged) MODE='staged' ;;
		--fix) FIX=1 ;;
		-h|--help)
			cat "${HELP_PATH}"
			exit 0
			;;
		*)
			echo "E: unknown option: ${arg@Q}" >&2
			exit 1
			;;
	esac
done





#
# Standardize File Permissions
#
while read -r path; do
	[[ "$(stat -c %a "${path}")" == 700 ]] || files+=("${path}")
done < <(
	if [[ "${MODE}" == staged ]]; then
		git diff --name-only -z
	else
		git ls-files -z
	fi
)
((${#files[@]})) && if ((FIX)); then
	xargs -L 250 -- chmod 700 <<<"${files[@]}"
else
	printf '%s\0' "${files[@]}"
fi
