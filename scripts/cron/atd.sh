#!/usr/bin/env bash





#
# AtD Jobs
#
if hash atd &>/dev/null; then
	log w 'AtD not found in the PATH, therefore there are no AtD jobs to audit.'
	exit 11
fi
#
# AtD does not have a standardized directory where it stores AtD jobs, so you have to dig deep into its binary for it
while IFS='' read -rd '' -u "${atd_dir_fd}" path; do
	# Once a directory sticks, iterate through all the job files in it as necessary.
	[[ -d "${path}" && -x "${path}" ]] || continue
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
