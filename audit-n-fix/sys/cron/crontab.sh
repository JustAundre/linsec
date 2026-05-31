#
# Crontabs
#
# Prompt to review/edit the crontab of each user
# Prompt to delete the crontab of each user
hash crontab && for u in "${all_users[@]}"; do
	log i "Reviewing the crontab for user \"${u}\"..."
	sleep 2.5
	crontab -eu "${u}"
	crontab -riu "${u}"
done