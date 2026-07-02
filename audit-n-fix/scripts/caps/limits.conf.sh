#!/usr/bin/env bash
#
# Modify/Verify
#
# Edit/validify limits.conf
until [[ "${pass}" == true ]]; do
	"${EDITOR}" cnf/rsc-caps/limits.conf
	while read -r 'field[0]' 'field[1]' 'field[2]' 'field[3]' 'field[4]'; do
		# Validate the identifier field
		# TODO
		if [[ "${field[0]}" =~ ^@[0-9]+(:[0-9]+)?$ || "${field[0]}" =~ ^[0-9]+(:[0-9]+)?$ || "${field[0]}" == '*' ]]; then :
		elif [[ "${field[0]}" =~ ^[@%]([a-zA-Z_-.]{1,32})$ ]] && getent group "${BASH_REMATCH[1]}" &>/dev/null; then :
		elif [[ "${field[0]}" =~ ^([a-zA-Z_-.]{1,32})$ ]] && getent passwd "${BASH_REMATCH[1]}" &>/dev/null; then :
		else
			pass=false
			break
		fi
	done < <(grep -Ev '^\s*(#|$)' cnf/rsc-caps/limits.conf)
	if [[ "${pass}" == false ]]; then
		log w 'There was a syntax error in your limits.conf.'
		pause
	else
		pass=true
	fi
done





#
# Install
#
install -m 644 -o 0 -g 0 cnf/rsc-caps/limits.conf /etc/security/limits.conf