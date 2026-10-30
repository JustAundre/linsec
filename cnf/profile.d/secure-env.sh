#!/usr/bin/env bash
# Curly brackets to stop output of staging commands
{
	# Set secure/safe shell configurations
	set +o xtrace +o verbose +o monitor +o nolog +o ignoreeof
	set -o functrace -o errtrace -o pipefail -o noclobber
	shopt -s histappend histverify cmdhist dotglob globstar interactive_comments
	shopt -u cdable_vars cdspell dirspell extglob nocaseglob nocasematch expand_aliases progcomp
	umask 077
	#
	# Lock down variables
	PROMPT_COMMAND='history -a; history -w'
	UID="$(< /proc/self/loginuid)"
	[[ ${UID} == 4294967295 ]] && UID="$(id -u)"
	USER="$(id -n -u "${UID}")"
	HOME=~${USER}
	LOGNAME="${USER}"
	LD_PRELOAD=''
	HISTFILE="${HOME}/.bash_history"
	HISTSIZE='-1'
	HISTFILESIZE='-1'
	HISTIGNORE=''
	HISTCONTROL='ignoreboth'
	HOSTNAME="$(hostname)"
	TTY="$(tty)"
	TTY="${TTY##*/}"
	SSH_TTY="${TTY}"
	for var in SSH_CONNECTION SSH_CLIENT; do
		[[ -z "${var}" ]] && "${var}=Local"
	done
	declare -r -x UID USER HOME LOGNAME LD_PRELOAD HISTFILE HISTSIZE HISTFILESIZE HISTIGNORE HISTCONTROL HOSTNAME SSH_CONNECTION TTY SSH_TTY SSH_CLIENT SSH_ORIGINAL_COMMAND
	#
	# Remove usage of commands which allow bypasses or unauthorized forensics
	builtin enable -n set shopt umask kill builtin command unalias ulimit disown enable times alias echo printf
} &>/dev/null
