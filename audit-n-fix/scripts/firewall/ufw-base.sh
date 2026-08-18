if hash ufw; then
	# Start the firewall
	systemctl unmask ufw
	systemctl enable --now ufw
	ufw --force enable
	#
	# Reset the firewall
	ufw reset
	#
	# Deny all incoming, allow all outgoing.
	ufw default deny incoming
	ufw default allow outgoing
else
	log e 'This script needs UFW installed and locatable in your system PATH variable.'
fi
