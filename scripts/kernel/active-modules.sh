#!/usr/bin/env bash





#
# Active Module Audit
#
# Fetch loaded kernel modules'...
mapfile -t mods < <(grep -E -o '^[^ ]+' /proc/modules | sort)
for mod in "${mods[@]}"; do
	# Descriptions
	desc="$(modinfo -d "${mod}" | tr -d '\n')"
	[[ -z "${desc}" ]] && desc='No description.'
	#
	# Dependencies
	deps="$(modinfo "${mod}" -F depends)"
	[[ "${deps}" =~ ^\w+$ ]] && deps=nothing.
	#
	# Combine.
	readable+=("${mod}: ${desc} - Depends on ${deps}")
done
#
# Unload & disable selected modules.
while IFS=':' read -r -d '' mod desc; do
	selections+=("${mod}")
done < <(PS2='Select active modules to stop and disable.' cl-new -m -o "${readable[@]}")
((!${#selections[@]})) && exit 0
modprobe -r "${selections[@]}"
printf 'install %s /bin/false\n' "${selections[@]}" >>/etc/modprobe.d/hardening.conf
perm-fix -m 644 -o 0 -g 0 /etc/modprobe.d/hardening.conf
log i 'You can find blocked kernel modules @ "/etc/modprobe.d/hardening.conf"'
