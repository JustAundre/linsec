#
# Inactive Module Management
#
# Block all currently inactive modules from ever loading.
confirm 'Prevent currently unused kernel modules from ever being loaded' && while IFS= read -r mod; do
	echo "install ${mod} /bin/false" >>/etc/modprobe.d/hardening.conf
#
# uniq -u: If a line occurs more than once, all instances of that line are removed.
done < <(sort < <(
	# Combine results from active modules and ALL modules.
	find /lib/modules/"$(uname -r)" -type f -name '*.ko*' -print0 | xargs -0n1 basename | cut -d. -f1
	grep -Eo '^[^ ]+' /proc/modules
) | uniq -u)
log i 'You can find blocked kernel modules @ "/etc/modprobe.d/hardening.conf"'