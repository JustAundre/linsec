#
# SystemD Baselining
#
# Baseline /etc/systemd/system/ from /lib/systemd/system/
log i 'Baselining "/etc/systemd/system/" from "/lib/systemd/system/"...'
mapfile -td '' paths < <(find /etc/systemd/system -maxdepth 1 -mindepth 1 -print0)
for svc_path in "${paths[@]}"; do
	# Handle symlinks
	if [[ -h "${svc_path}" ]]; then
		# Handle broken symlinks
		[[ ! -e "${svc_path}" ]] &&
			confirm "${svc_path} is a broken symlink. Remove" &&
			unlink "${svc_path}"
		#
		# Checks if a service is a symlink to a file in /lib/systemd/system/ or /usr/lib/systemd/system/.
		real_path="$(readlink "${svc_path}")"
		if [[
			"${real_path}" == /lib/systemd/system/* ||
			"${real_path}" == /usr/lib/systemd/system/*
		]]; then
			# Generally most services fall under the above condition.
			log i "${svc_path} is likely a vendor provided service that has been enabled."
		elif [[ "${real_path}" == /dev/null ]]; then
			log i "${svc_path} is a masked service pointing to /dev/null."
		else
			if confirm "Unusual symlink; ${svc_path} points to ${real_path}. Review"; then
				"${EDITOR}" "${real_path}"
				confirm "Delete the symlink pointing from ${svc_path} to ${real_path}" && unlink "${svc_path}"
				confirm "Delete the source file @ ${real_path}" && rm -vi "${real_path}"
			fi
		fi
	#
	# Handle directories
	elif [[ -d "${svc_path}" ]]; then
		if [[ "${svc_path}" == *.d ]]; then
			log i "${svc_path} is just an overrides directory."
		else
			confirm "${svc_path} doesn't end in \".d\"; review its contents" &&
				while IFS= read -rd '' file <&3; do
					"${EDITOR}" "${file}"
					rm -vi "${file}"
				done 3< <(find "${svc_path}" -type f -print0) </dev/tty
		fi
		[[ -z "$(find "${svc_path}" -mindepth 1)" ]] && rm -vdi "${svc_path}"
	#
	# Prompt to audit files. If yes, audit files then ask for whether to delete the file.
	elif [[ -f "${svc_path}" ]] && confirm "${svc_path} is a real file located in /etc/systemd/system/—may be a custom service. Review"; then
		"${EDITOR}" "${svc_path}"
		rm -vi "${svc_path}"
	fi
done