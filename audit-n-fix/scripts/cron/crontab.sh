#!/usr/bin/env bash





#
# Crontabs
#
# Prompt to review/edit the crontab of each user
# Prompt to delete the crontab of each user
hash crontab &>/dev/null || exit 1
for u in "${all_users[@]}"; do
	log i "Reviewing crontab of user: \"${u}\"..."
	sleep 1.5
	crontab -eu "${u}"
	crontab -riu "${u}"
done
