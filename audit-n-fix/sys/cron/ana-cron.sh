#
# (Ana)Cron files
#
# Check /etc/cron* files
hash crond && find /etc/cron* /var/spool/anacron/cron* /etc/anacrontab -type f \
	-exec log i 'Reviewing cron file "{}"...' \; \
	-exec sleep 2.5 \; \
	-exec "${EDITOR}" {} \; \
	-exec rm -vi {} \; \
	</dev/tty