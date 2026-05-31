#
# AtD Jobs
#
# AtD does not have a standardized directory where
# it stores Atd jobs, so you have to dig deep into its binary for it.
if hash atd; then
	while read -r path; do
		[[ -d "${path}" && -x "${path}" ]] && atd_dir="${path}" || break
		find "${atd_dir}" ! -name '.SEQ' -type f \
			-exec log i "Reviewing AtD job file \"{}\"..." \; \
			-exec sleep 2.5 \; \
			-exec "${EDITOR}" {} \; \
			-exec rm -vi {} \; \
			</dev/tty
		break
	done < <(strings "$(which atd)" | grep -Eo '/var/spool/.+')
	[[ -z "${atd_dir}" ]] && log w $'AtD is installed, but the directory where AtD jobs are stored couldn\'t be located.'
fi