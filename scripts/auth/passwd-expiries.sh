#!/usr/bin/env bash





#
# Change Expiries (for future users)
#
reconfig -x replace PASS_MAX_DAYS 31 /etc/login.defs
reconfig -x replace PASS_MIN_DAYS 3 /etc/login.defs
reconfig -x replace PASS_WARN_AGE 27 /etc/login.defs





#
# Change Expiries (for existing users)
#
for entry in "${passwd[@]}"; do
	IFS=':' read -rd $'\n' user hash uid gid gecos home shell <<<"${entry}"
	[[ ${shell} =~ /('nologin'|'false')$ || ${user} == "${SUDO_USER}" ]] && continue
	timestamp="$(date +%Y-%m-%d)"
	chage -m 3 -M 31 -W 27 "${user}" &&
		log i "Set password min/max/warn timings to 3/31/27 (in days) for user: ${user@Q}."
	chage -d "${timestamp}" "${user}" &&
		log i "Set date since last password change for user ${user@Q} to ${timestamp@Q}."
done
