#!/usr/bin/env bash





#
# Anacron & Cron Jobs
#
# Locate scheduled task files, prompt to review/edit each, and offer removal
while IFS='' read -rd '' -u "${task_fd}" task; do
	log i "Reviewing scheduled task: ${task@Q}"
	pause 0
	"${EDITOR}" -- "${task}"
	rm -vi -- "${task}"
done {task_fd}< <(find /etc/cron* /var/spool/anacron/cron* /etc/anacrontab -type f -print0)
exec {task_fd}<&-





#
# AtD Jobs
#
if hash atd &>/dev/null; then
	# AtD does not have a standardized directory where it stores AtD jobs, so you have to dig deep into its binary for it
	while IFS='' read -rd '' -u "${atd_dir_fd}" path; do
		# Cycle through the possible candidate AtD jobs directories until 1 sticks
		[[ -d "${path}" && -x "${path}" ]] || continue
		#
		# Once a directory sticks, iterate through all the job files in it as necessary.
		while IFS='' read -r -d '' -u "${atd_job_fd}" job; do
			log i "AtD job: ${job@Q}"
			pause 0
			"${EDITOR}" -- "${job}"
			rm -v -i -- "${job}"
		done {atd_job_fd}< <(find -- "${path}" ! -name '.SEQ' -type f -print0)
		exec {atd_job_fd}<&-
	done {atd_dir_fd}< <(
		strings "$(which atd)" |
			grep -o -E '/var/spool/[^[:space:]]+' |
			sort -u |
			tr '\n' '\0'
	)
	exec {atd_dir_fd}<&-
else
	log w 'AtD not found in the PATH; skipped AtD checks.'
fi





#
# Crontabs
#
# Prompt to review, edit and/or delete the crontab of every user
if hash crontab &>/dev/null; then
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
else
	log w 'Crontab not found in the PATH; skipped crontab checks.'
fi





#
# SystemD .timers & .paths
#
# Map out the .timers/.paths
if [[ ${init} == 'systemd' ]]; then
	# Audit them & act accordingly.
	while IFS='' read -r -u "${trigger_fd}" trigger; do
		log i "Reviewing trigger: ${trigger@Q}"
		pause 0
		"${EDITOR}" -- "${trigger}" &&
			confirm "Delete ${trigger@Q}" &&
			systemctl disable --now -- "${trigger}" &&
			rm -v -- "${trigger}"
	done {trigger_fd}< <(
		systemctl show -p FragmentPath --value '*.timer' '*.path' | grep .
	)
	exec {trigger_fd}<&-
	#
	# Pushes changes into SystemD
	systemctl daemon-reload
else
	log w 'Init. system is not SystemD; skipped SystemD timer checks.'
fi
