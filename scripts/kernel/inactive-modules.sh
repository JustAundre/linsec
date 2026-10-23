#!/usr/bin/env bash





#
# Inactive Module Management
#
# Block all currently inactive modules from ever loading.
if [[ ! -d /lib/modules/$(uname -r) ]]; then
	log e 'The kernel modules for your active kernel no longer exist on the disk, please restart your machine.'
	exit 11
fi
#
# Subtract list of active modules from list of all modules to get list of inactive modules.
mapfile -t mods  < <(sort < <(
	find "/lib/modules/$(uname -r)" -type f -name '*.ko*' -printf '%f\n' |
		sed 's/_/-/g' |
		cut -d '.' -f1
	grep -ZoE '^\w+' /proc/modules |
		sed 's/_/-/g'
) | uniq -u)
confirm 'Prevent currently unused kernel modules from ever being loaded' &&
	printf 'install %s /bin/false\n' "${mods[@]}" >>/etc/modprobe.d/hardening.conf
log i 'The new blacklist can be found at "/etc/modprobe.d/hardening.conf".'
