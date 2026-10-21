#!/usr/bin/env bash





#
# Environment Setup
#
set -u
STRICT=0
MODE='all'
FIX=0
HELP_PATH="${0}.help.md"
for arg in "${@}"; do
	case "${arg}" in
		--staged) MODE='staged' ;;
		--strict) STRICT=1 ;;
		--fix) FIX=1 ;;
		*)
			echo "E: unknown option: ${arg@Q}" >&2
			exit 1
			;;
	esac
done





#
# Standardize File Permissions
#
files=()
while read -r path; do
	[[ "$(stat -c %a "${path}")" == 700 ]] || files+=("${path}")
done < <(
	if [[ "${MODE}" == staged ]]; then
		git diff --name-only -z
	else
		git ls-files -z
	fi
)
((${#files[@]})) || exit 0
if ((FIX)); then
	xargs -L 250 -- chmod 700 <<<"${files[@]}"
else
	printf '%s\0' "${files[@]}"
	((STRICT)) || exit 2
fi
