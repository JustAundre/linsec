#
# Repository URL Checks
#
# Loop over all repository files
while read -r repo_file; do
	# Loop over every line URL in the repositories file
	while read -r repo_url; do
		# Compare the domains of the newly found URL with the URL from the /etc/os-release file.
		# If the domains match, just log it.
		# If they don't match and the "newly found URL" actually exists, flag it.
		if compdom "${os_info[HOME_URL]}" "${repo_url}"; then log i "URL \"${repo_url}\" was identified."
		elif [[ -n "${repo_url}" ]]; then log w "URL with foreign domain \"${repo_url}\" found in \"${repo_file}\"."
		fi
	done < <(grep -oE 'https?://[^/ ]+' "${repo_file}" | sort -ux)
done < <(
	find /etc/yum.repos.d/ -mindepth 1 ! -type d
	find /etc/apt/sources.list.d/ -mindepth 1 ! -type d
	echo /etc/apt/sources.list
)