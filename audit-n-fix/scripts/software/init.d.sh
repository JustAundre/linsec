#
# /etc/init.d/ Audit
#
[[ -d /etc/init.d/ ]] &&
	confirm 'It is concerning that /etc/init.d/ is present. Review its contents' &&
	while IFS= read -rd '' file; do
		"${EDITOR}" "${file}"
		rm -vi "${file}"
	done < <(find /etc/init.d/ -type f -print0)
[[ -z "$(find /etc/init.d/ -type f)" ]] && confirm '/etc/init.d/ is now empty. Remove it' && rm -vdi /etc/init.d/