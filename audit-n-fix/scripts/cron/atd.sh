#
# AtD Jobs
#
# AtD does not have a standardized directory where
# it stores Atd jobs, so you have to dig deep into its binary for it.
if hash atd; then
	while read -r path; do
		[[ -d "${path}" && -x "${path}" ]] && atd_dir="${path}" || break
		if [[ -d "${path}" ]]; then
			log i "Successfully located AtD job directory @ \"${path}\""
			mapfile -td '' atd_jobs < <(find "${atd_dir}" ! -name '.SEQ' -type f)
		else
			log w "Possible AtD job directory \"${path}\" doesn't exist; attempting to find another possible AtD job directory..."
			continue
		fi
		for atd_job in "${atd_jobs[@]}"; do
			log i "Reviewing AtD job file \"${atd_job}\"..."
			sleep 2.5
			"${EDITOR}" "${atd_job}"
			rm -vi "${atd_dir}"
		done
	done < <(strings "$(which atd)" | grep -Eo '/var/spool/.+')
	[[ -z "${atd_dir}" ]] && log w $'AtD is installed, but the directory where AtD jobs are stored couldn\'t be located.'
fi