#!/usr/bin/env bash





#
# Environment Setup
#
# CD into the script's parent directory;
# Source global functions and variables.
cd "$(dirname "${0}")" || exit 69
#
# Source library commands
[[ -d "../lib/" ]] || exit 69
for function in "../lib/"*; do
	. "${function}"
done
#
# Set editor
# Secure UMASK
# Include hidden directories when globbing
# Trying to avoid errors when globbing results in nothing, & set case insensitivity for responses.
# Unset aliases & disable alias expansion
# Make a pipeline's exit code the exit code of the last failed command of the pipelines
until [[ -x "${EDITOR}" ]] || hash "${EDITOR}" &>/dev/null; do
	log w 'Invalid or no text editor selected; try nano or vi?'
	read -rp 'Type a text editor and hit [ENTER] to confirm: ' EDITOR
done
umask 077
shopt -s dotglob nullglob nocasematch
unalias -a
set -o pipefail





#
# Helper Variables
#
# Load the PATH variable into an array, then all executables in the PATH into an array
mapfile -td ':' paths < <(printf '%s' "${PATH}")
mapfile -td '' binaries < <(find "${paths[@]}" -maxdepth 1 -type f -executable -print0)
#
# Load all interactive, non-interactvie, and all users into their respective arrays
mapfile -t int_users < <(
	grep -vE '/(nologin|false|true)$' /etc/passwd |
		awk -F: '$3 >= 1000 { print $1 }'
)
mapfile -t nonint_users < <(
	grep -E '/(nologin|false|true)$' /etc/passwd |
		awk -F: '$3 < 1000 { print $1 }'
)
mapfile -t all_users < <(cut -d: -f1 < /etc/passwd)
#
# Store OS details in an associative array.
declare -A os_info
while IFS='=' read -r key value; do
	value="${value%\"}"
	value="${value#\"}"
	os_info["${key}"]="${value}"
done < /etc/os-release





#
# Environment Check
#
log i 'Running environment checks...'
#
# 1. Is this running in Bash & NOT sourced?
# 2. Does this script have root permissions?
# 3. Is the active init. system SystemD?
# 4. Is the output a terminal?
[[ ${BASH_SOURCE[0]} == "${0}" ]] || errors+=('Script must be ran by Bash intepreter & must NOT be sourced.')
[[ ${EUID} -eq 0 ]] || errors+=("Must run as root. Try (sudo bash ${0}).")
[[ "$(< /proc/1/comm)" == systemd ]] || errors+=('System is not using SystemD which is the only system daemon supported by this script.')
[[ -t 0 ]] || errors+=('All scripts here require an interactive terminal.')
#
# If any of the above, alert.
if [[ ${#errors[@]} -ge 1 ]]; then
	log e "${errors[@]}"
	log e "Failed ${#errors[@]} startup checks."
	confirm 'Continue' || exit 69
else
	log i 'Passed startup checks.'
fi





#
# Discovery & Execution
#
# Enumerate all scripts, select 1.
mapfile -td '' scripts < <(find scripts -name '*.sh' -print0 | sort -z)
script="$(checklist -t 'Choose a script to run' "${scripts[@]}")"
#
# Find a valid file name for the log file
session_id=1
while compgen -G "*-${session_id}.log" > /dev/null; do ((session_id++)); done
main_log="logs/$(basename "${script}" | sed 's/\.sh//g')-${session_id}.log"
mkdir -p "$(dirname -- "${main_log}")" && : >> "${main_log}"
#
# Start logging and execute the selected script.
exec &> >(tee -a "${main_log}")
. "${script}"





#
# Exit
#
# Fetch log files, clear the screen, & print the summary.
mapfile -t log_files < <(timeout 5 find logs -maxdepth 1 -type f -name "*${session_id}.log")
clear
cat <<- EOF
	  ---{=========}###[@]###{===========}---
	        WINDOWS AT LOSS AT THE
	           AGAPE FREEDOM OF LINUX
	  ---{=========}###[@]###{===========}---

	      Cybersecurity is great; though,
	    people often have their priorities
	       mixed up. Make sure you have
	        good password hygiene and
	         a good password manager.

	-----<============>{x}<============>-----
EOF
if [[ ${#log_files[@]} -ge 1 ]]; then
	printf 'Here are the log files from this session:\n'
	printf '%s\n' "${log_files[@]}"
else
	log w "That's strange, no log files were detected."
fi
exit 0
