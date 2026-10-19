#!/usr/bin/env bash





#
# Anacron & Cron Jobs
#
# Locate scheduled task files, prompt to review/edit each, then enqueue for removal
while IFS='' read -rd '' task; do
	log i "Reviewing scheduled task: ${task@Q}."
	pause 0
	"${EDITOR}" -- "${task}"
	if confirm "Enqueue ${task@Q} for removal"; then
		delete_queue+=("${task}")
		log i "${task@Q} was queued for removal."
	else
		log i "${task@Q} was not queued for removal."
	fi
done < <(find /etc/cron* /var/spool/anacron/cron* /etc/anacrontab -type f -print0)
[[ ${#delete_queue[@]} -ge 1 ]] && if rm -v "${delete_queue[@]}"; then
	log i 'Removed all selected (Ana)Cron jobs.'
else
	log e 'Something went wrong during the deletion.'
fi





#
# AtD Jobs
#
if hash atd; then
	# AtD does not have a standardized directory where it stores Atd jobs, so you have to dig deep into its binary for it
	while IFS='' read -rd '' path; do
		# Cycle through the possible candidate AtD jobs directories until 1 sticks
		[[ -d "${path}" && -x "${path}" ]] || continue
		if [[ ! -d "${path}" ]]; then
			log w "Candidate AtD jobs directory ${path@Q} doesn't exist."
			continue
		fi
		#
		# Once a directory sticks, iterate through all the job files in it as necessary.
		log i "Successfully located AtD job directory @ ${path@Q}"
		while IFS='' read -rd '' job; do
			log i "AtD job: ${job@Q}"
			pause 0
			"${EDITOR}" -- "${job}"
			rm -vi -- "${job}"
		done < <(find -- "${path}" ! -name '.SEQ' -type f)
	done < <(strings "$(which atd)" | grep -zoE '/var/spool/.+')
else
	log w 'AtD not found in the PATH; skipped AtD checks.'
fi





#
# Crontabs
#
# Prompt to review, edit and/or delete the crontab of every user
if hash crontab; then
	for entry in "${passwd[@]}"; do
		IFS=':' read -rd $'\n' user hash uid gid gecos home shell <<<"${entry}"
		if crontab -u "${user}" -l &>/dev/null; then
			log i "Crontab of: ${user@Q}"
			pause 0
	    	crontab -eu "${user}"
	    	crontab -riu "${user}"
		else
			log i "Skipped empty crontab for user: ${user@Q}."
		fi
	done
else
	log w 'Crontab not found in the PATH; skipped AtD checks.'
fi





#
# SystemD .timers & .paths
#
# Map out the .timers/.paths
if [[ ${init} == 'systemd' ]]; then
	# Audit them & act accordingly.
	while IFS='' read -r trigger; do
		log i "Reviewing trigger: ${trigger@Q}."
		pause 0
		"${EDITOR}" -- "${trigger}" &&
			confirm "Delete ${trigger@Q}" &&
			systemctl disable --now -- "${trigger}" &&
			rm -v -- "${trigger}"
	done < <(
		systemctl list-units --all --plain --no-legend |
			awk '{ print $1 }' |
			xargs systemctl show -p FragmentPath --value -- |
			grep -E '\.(timer|path)$'
	)
	unset triggers
	#
	# Pushes changes into SystemD
	systemctl daemon-reload
else
	log w 'Init. system is not SystemD; skipped SystemD timer checks.'
fi
