#!/usr/bin/env bash





#
# Active Module Audit
#
# Fetch loaded kernel modules'...
while IFS= read -r mod; do
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
done < <(grep -Eo '^[^ ]+' /proc/modules | sort)
#
# Prompt for ones to disable.
mapfile -td '' mods_disable < <(
	checklist -mt 'These are active kernel modules; select those to unload and disable.' "${readable[@]}" |
		cut -d: -f1
)
#
# Unload 'em.
modprobe -r "${mods_disable[@]}"
#
# Disable 'em.
perm_fix -m 644 -o 0 -g 0 /etc/modprobe.d/hardening.conf
for mod in "${mods_disable[@]}"; do
	echo "install ${mod} /bin/false" >>/etc/modprobe.d/hardening.conf
done
log i 'You can find blocked kernel modules @ "/etc/modprobe.d/hardening.conf"'
