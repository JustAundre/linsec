#!/usr/bin/env bash





#
# Repository URL Checks
#
# Loop over all repository files
while IFS='' read -rd '' repo_file; do
	# Loop over every line URL in the repositories file
	while IFS='' read -rd '' url; do
		# Compare the domains of the newly found URL with the URL from the /etc/os-release file.
		# If the domains match, log it; otherwise, flag it.
		[[ -n "${url}" ]] && if compdom "${os_info[HOME_URL]}" "${url}"; then
			log i "${url@Q} is likely OK."
		else
			log w "${url@Q} marked as foreign—found in ${repo_file@Q}."
		fi
	done < <(grep -oE 'https?://[^/ ]+' "${repo_file}" | sort -z | uniq -zu)
done < <(find /etc/yum.repos.d/ /etc/apt/sources.list.d/ /etc/apt/sources.list -mindepth 1 ! -type d -print0)
