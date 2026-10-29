#!/usr/bin/env bash





#
# Crontabs
#
if hash crontab &>/dev/null; then
	log e 'Crontab not found in the PATH and therefore there are no crontabs to audit.'
	exit 11
fi
for entry in "${passwd[@]}"; do
	IFS=':' read -r user _ <<<"${entry}"
	if crontab -u "${user}" -l &>/dev/null; then
		log i "Reviewing crontab for ${user@Q}"
		pause 0
		crontab -e -u "${user}"
		crontab -r -i -u "${user}"
	else
		log i "Skipped empty crontab for ${user@Q}"
	fi
done
