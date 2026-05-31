#
# /etc/init.d/ Audit
#
[[ -d /etc/init.d/ ]] &&
	confirm 'It is concerning that /etc/init.d/ is present. Review its contents' &&
	find /etc/init.d/ -type f \
		-exec "${EDITOR}" {} \; \
		-exec rm -vi {} \; \
		</dev/tty
[[ -z "$(find /etc/init.d/ -type f)" ]] && confirm '/etc/init.d/ is now empty. Remove it' && rm -vdi /etc/init.d/