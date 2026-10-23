#!/usr/bin/env bash
set -u

MODE='all'
STRICT=0
FIX=0
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

is_bash_file() {
	case "${1}" in
		*.sh|*.bash|*.rc) return 0 ;;
	esac
	head -n1 "${1}" 2>/dev/null | grep -qE '^#!.*\bbash\b'
}

files=()
candidates=()
failures=0
findings=0

if [[ "${MODE}" == staged ]]; then
	mapfile -t candidates < <(git diff --cached --name-only --diff-filter=ACM)
else
	mapfile -t candidates < <(git ls-files)
fi

for file in "${candidates[@]}"; do
	[[ -f "${file}" ]] || continue
	is_bash_file "${file}" && files+=("${file}")
done

for file in "${files[@]}"; do
	if ! bash -n "${file}"; then
		echo "E: ${file@Q}: syntax error." >&2
		((failures++))
	fi
done

tmp="$(mktemp -d)"
trap 'rm -r -f "${tmp}"' EXIT
for file in "${files[@]}"; do
	grep -P -z '(?<!(?<!\n)\n{6})#\n# \w+\n#\n' "${file}"
	flags="$(grep -P -z -c '(?<!(?<!\n)\n{6})#\n# \w+\n#\n' "${file}")"
	if [[ ${flags} -gt 0 ]] && (( FIX )); then
		mkdir -p "$(dirname "${tmp}/${file}")"
		cp -a "${file}" "${tmp}/${file}"
		perl -0777 -p -i -e 's/\n*#\n# (.+)\n#\n/\n\n\n\n\n\n#\n# $1\n#\n/g' "${file}"
		diff -d "${tmp}/${file}" "${file}"
		exit_status="${?}"
		[[ "${exit_status}" -eq 1 ]] &&
			echo "i: ${file@Q}: Fixed ${flags} instances of improperly spaced headers."
	elif [[ ${flags} -gt 0 ]]; then
		((failures += flags))
			echo "W: ${file@Q}: Found ${flags} instances of improperly spaced headers." >&2
	fi
done

for file in "${files[@]}"; do
	if matches="$(grep -n -E '[[:blank:]]+$' "${file}")"; then
		if ((FIX)); then
			sed -i 's/[[:blank:]]\+$//' "${file}"
			git add -- "${file}"
			echo "i: ${file@Q}: Fixed trailing whitespace."
		else
			echo "E: ${file@Q}: Found trailing whitespace." >&2
			# shellcheck disable=SC2001
			sed 's/^/    /' <<<"${matches}"
			((failures++))
		fi
	fi
	if [[ -s "${file}" && -n "$(tail -c 1 "${file}")" ]]; then
		if (( FIX )); then
			printf '\n' >> "${file}"
			git add -- "${file}"
			echo "i: ${file@Q}: fixed missing EOF newline."
		else
			echo "W: ${file@Q}: found missing EOF newline." >&2
			((failures++))
		fi
	fi
done

if command -v shellcheck &>/dev/null; then
	for file in "${files[@]}"; do
		if ! shellcheck "${file}"; then
			if ((STRICT)); then
				echo "W: ${file@Q}: shellcheck:" >&2
				((failures++))
			else
				echo "W: shellcheck findings in: ${file} (run hooks/lint.sh --strict to enforce)" >&2
				((findings++))
			fi
		fi
	done
else
	echo 'E: shellcheck not installed; skipped lint.' >&2
fi

if ((!${#files[@]})); then
	echo 'i: No shellscripts to check.'
elif ((findings > 0)); then
	echo "W: ${#files[@]} file(s) checked, ${findings} advisory finding(s)." >&2
elif ((failures > 0)); then
	echo "E: ${failures} failure(s) found; aborting..." >&2
	exit 2
else
	echo "i: ${#files[@]} file(s) checked, 0 advisories or critical errors."
fi
