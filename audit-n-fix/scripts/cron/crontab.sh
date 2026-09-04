#!/usr/bin/env bash





#
# Crontabs
#
# Prompt to review/edit the crontab of each user
# Prompt to delete the crontab of each user
hash crontab &>/dev/null || exit 10
for u in "${all_users[@]}"; do
	log i "Reviewing crontab of user: \"${u}\"..."
	pause 3
	crontab -eu "${u}"
	crontab -riu "${u}"
done
