#
# Service Audit
#
# Enumerate services
# Check for services to remove
mapfile -t services < <(TERM=dumb systemctl list-unit-files --type=service --no-legend --plain | awk '{ print $1 }')
mapfile -t flagged_services < <(checklist -mt 'Select services to REMOVE' "${services[@]}")
#
# Remove selected services
for flagged_service in "${flagged_services[@]}"; do
	# Attempt to remove package behind service
	# Will just decommission service file if cannot locate resposible package.
	apt-get remove --purge -y "$(dpkg -S "/etc/systemd/system/${flagged_service}.service" | cut -d: -f1)" ||
	decommission "${flagged_service}"
done
#
# Reload SystemD
systemctl daemon-reload