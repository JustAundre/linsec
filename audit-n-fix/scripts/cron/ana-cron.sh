#!/usr/bin/env bash





#
# Anacron & Cron Jobs
#
# Locate scheduled task files, prompt to review/edit each, then enqueue for removal
mapfile -td '' cron_files < <(find /etc/cron* /var/spool/anacron/cron* /etc/anacrontab -type f -print0)

if [[ "${#cron_files[@]}" -ge 1 ]]; then
	for task in "${cron_files[@]}"; do
		log i "Reviewing scheduled task found @ \"${task}\"..."
		sleep 2.5

		"${EDITOR}" "${task}"

		if confirm "Enqueue \"${task}\" for removal"; then
			delete_queue+=("${task}")
			log i "\"${task}\" was queued for removal."
		else
			log w "\"${task}\" was not queued for removal."
		fi
	done

	[[ ${#delete_queue[@]} -ge 1 ]] && if rm -v "${delete_queue[@]}"; then
		log i 'Removed all selected scheduled tasks.'
	else
		log e 'Something went wrong during the deletion.'
	fi
else
	log e 'No scheduled tasks were detected and this script is now exiting...'
fi
