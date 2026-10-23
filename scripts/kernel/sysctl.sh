#!/usr/bin/env bash





#
# Sysctl Parameters
#
# Iterate over each category
for category in ./cnf/sysctl/*; do
	# Enumerate options for each category
	choices=()
	for conf in "${category}"/*.conf; do
		choices+=("${conf%'.conf'}")
	done
	#
	# Query for which options to enforce and enforce selected options
	mapfile -td '' selections < <(PS2="Select ${category} hardening sysctl parameters" cl-new -mo "${choices[@]}")
	for selection in "${selections[@]}"; do
		name="${selection##*/}"
		name="${name// /-}"
		install -m 600 -o 0 -g 0 -D -v "${selection}.conf" "/etc/sysctl.d/99-zz-${name@L}.conf"
	done
done
sysctl --system >/dev/null
