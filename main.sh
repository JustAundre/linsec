#!/usr/bin/env bash





#
# Environment Setup
#
# CD into the script's parent directory.
cd "$(dirname "${0}")" || exit 1
[[ -d "./bash-lib" ]] || exit 2
for function in "./bash-lib/"*; do
	source "${function}"
done
#
# Set editor
export EDITOR
hash "${EDITOR}" || for EDITOR in nano micro mcedit tilde joe e3 hx nvim vim vi kak emacs ed mp jed ash vis sam; do
	hash "${EDITOR}" && break
done
until hash "${EDITOR}"; do
	log w 'The EDITOR variable is invalid or undeclared.'
	read -erp 'Type a text editor and hit [ENTER] to confirm: ' EDITOR
done
#
# Performance optimizations, not strictly necessary but great to have enabled.
for builtin in basename dirname cut head logname mkfifo mktmp realpath rm rmdir seq sleep tee tty uname ln unlink whoami; do
	[[ -f /usr/lib/bash/${builtin} ]] && enable -f "/usr/lib/bash/${builtin}" "${builtin}"
done
unset builtin





#
# Shell Opts & Helper Variables
#
# Create logging directory
# Detect init system
# Define secure UMASK
# Make a pipeline's exit code the exit code of the last failed command of the pipelines
# Load users into arrays by type
# Store OS details in an associative array
# Store package manager in variable
log_dir="$(pwd)/logs/$(date)" && mkdir -p "${log_dir}" || exit 3
init="$(ps -p 1 -o comm=)"
umask 0077
set -o pipefail
shopt -s nullglob
declare -A id_bounds
while IFS=' ' read -rd $'\n' key value; do
	id_bounds["${key}"]="${value}"
done < <(awk '/^#?\s*(SYS_)?(U|G)ID_(MIN|MAX)/ {print $1, $2}' /etc/login.defs)
mapfile -t passwd < /etc/passwd
mapfile -t group < /etc/group
declare -A os_info
while IFS='=' read -r key value; do
	value="${value%\"}"
	value="${value#\"}"
	os_info["${key}"]="${value}"
done < /etc/os-release
for pkg_backend in apt-get dnf yum pacman pkg; do
	hash "${pkg_backend}" && break
	unset pkg_backend
done
export log_dir init int_users sys_users all_users os_info pkg_backend id_bounds





#
# DLL Audit
#
log w 'If the following command output reveals any DLLs not owned by the system, exit this script immediately and remedy the issue.'
mapfile -t ldds < <(
	which ps ss ls netstat find passwd whoami 2>/dev/null |
		unshare -n runuser -u nobody -- xargs -r -d '\n' ldd |
		awk '$2 == "=>" && $3 ~ /^\// { print $3 } $1 ~ /^\// { print $1 }' |
		xargs -r -d '\n' realpath -e |
		sort -u
)
pkg-mgr verify-file "${ldds[@]}"
pkg-mgr query-owner "${ldds[@]}"
pause 0





#
# Environment Check
#
log i 'Running environment checks...'
#
# 1. Is this running in Bash & NOT sourced?
# 2. Does this script have root permissions?
# 3. Is the active init. system SystemD?
# 4. Is the output a terminal?
[[ ${BASH_SOURCE[0]} == "${0}" ]] || errors+=('main.sh: script cannot be sourced and requires Bash interpreter.')
[[ ${EUID} -eq 0 ]] || errors+=("main.sh: UID 0 required—try: sudo ${0}.")
[[ ${init} =~ ^(systemd|init)$ ]] || errors+=('main.sh: your system must be using SystemD or init).')
[[ -t 0 ]] || errors+=('main.sh: interactive terminal required.')
((${#pkg_backend})) || errors+=('main.sh: unable to find supported package manager in PATH variable.')
((${#id_bounds[@]} == 8)) || errors+=("main.sh: unable to completely detect this system's UID and GID boundings; check '/etc/login.defs'.")
#
# If any of the above, alert.
if [[ ${#errors[@]} -ge 1 ]]; then
	log e "${errors[@]}" "Failed ${#errors[@]} startup checks."
	confirm 'Proceed anyway' || exit 4
else
	log i 'Passed environment checks.'
fi





#
# Script Selection
#
mapfile -td '' scripts < <(find scripts -name '*.sh' -print0 | sort -z)
mapfile -td '' selections < <(PS2='Choose a script to run' cl-new -m "${scripts[@]}")
for script in "${selections[@]}"; do
	log i "Incoming script: ${script@Q}"
	pause 0
	(
		trap 'exit 130' SIGINT
		#
		# Execute the script.
		source "${script}"
	)
	if ((${?} == 130)); then
		log i 'Sending SIGINT (CTRL + C) during script execution sends you back to the main menu.' 'Send SIGINT again to terminate the script.'
		pause
		exec "${0}"
	fi
done





#
# Exit
#
cat <<-EOF
	  ---{=========}###[@]###{===========}---
	        Windows at loss at the
	           agape freedom of Linux
	  ---{=========}###[@]###{===========}---

	Suite version:			$(git log | head -n1)
	Operating system:		$(uname -r)
	Startup checks failed:		${#errors[@]}
	Log directory:			${log_dir@Q}
	# of logs:			$(files=("${log_dir}"/*.txt); printf '%d' "${#files[@]}")

EOF
exit 0
