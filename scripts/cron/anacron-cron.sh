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
