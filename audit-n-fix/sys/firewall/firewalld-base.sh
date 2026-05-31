if hash firewall-cmd; then
	# (--permanent: Modifies on-disk configuration, not in-memory configuration.)
	# Start the firewall
	systemctl unmask firewalld &&
		systemctl enable --now firewalld &&
		log i 'Restarted FirewallD.'
	#
	# Reset the firewall
	firewall-cmd --reset-to-defaults &&
		log i 'Successfully reset FirewallD.'
	#
	# Deny all incoming, allow all outgoing.
	firewall-cmd --set-default-zone public &&
		firewall-cmd --permanent --load-zone-defaults public &&
		log i 'Set FirewallD to zone "public". Deny incoming by default, allow outgoing by default.'
	#
	# Block ICMP echo requests & timestamp requests/replies
	firewall-cmd --permanent --add-icmp-block echo-request &&
		firewall-cmd --permanent --add-icmp-block timestamp-reply &&
		firewall-cmd --permanent --add-icmp-block timestamp-request &&
		log i 'Blocked ICMP echos/pings and timestamp requests.'
	#
	# Push on-disk configuration into in-memory configuration
	firewall-cmd --reload &&
		log i 'Loaded on-disk FirewallD configuration into running configuration.'
else
	log e 'This script needs FirewallD/firewall-cmd installed and locatable in your system PATH variable.'
fi