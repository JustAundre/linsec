#
# Invalidities
#
# Map out files /w broken ownership.
mapfile -d '' paths < <(xfind / -xdev \( -nouser -o -nogroup \) -print0)
for path in "${paths[@]}"; do (
	# Verbosity: note invalidities, their type, and the UID/GID.
	[[ "$(stat -c '%U' "${path}")" == UNKNOWN ]] && invalid_type+=UID
	[[ "$(stat -c '%G' "${path}")" == UNKNOWN ]] && {
		[[ -n "${invalid_type}" ]] && invalid_type+=' & '
		invalid_type+=GID
	}
	log i "${path} has an invalid owner ${invalid_type}; changed ownership to 0:0."
	chown -h 0:0 "${path}"
) done
#
# Remove invalid symlinks
xfind / -xdev -xtype l -exec log i '{} is a broken symlink; removing...' \; -exec unlink {} +
#
# Ensure FHS temp directories are world-writable /w sticky-bit.
perm_fix -m 1777 -o 0 -g 0 /tmp /var/tmp /dev/shm





#
# Abiguous Path Audit
#
# Prompt for manual review for paths in /etc/ which aren't owned by a system user.
mapfile -d '' paths < <(xfind /etc \( ! -group 0 -o ! -user 0 \) -print0)
for path in "${paths[@]}"; do
	# If the owners are system users/groups, it's probably fine.
	if [[ "$(stat -c %g "${path}")" -ge 1000 || "$(stat -c %u "${path}")" -ge 1000 ]]
	then select_fix "${path}"
	else log i "${path} isn't owned by 0:0 but marked as likely safe as the owners are system users."
	fi
done
#
# Prompt for manual review for paths which are world-writable.
mapfile -d '' -a paths < <(xfind / -xdev -perm -0002 -print0)
for path in "${paths[@]}"; do
	select_fix "${path}"
done





#
# Identity & Authorization Files
#
# Handle /etc/passwd & /etc/group
perm_fix -m 644 -o 0 -g 0 /etc/passwd /etc/group
#
# Shadow file permissions vary by the presence of the shadow group.
if grep -qE '^shadow:' /etc/group; then
	perm_fix -m 0640 -o 0 -g shadow /etc/shadow /etc/gshadow
	perm_fix -m 0600 -o 0 -g 0 /etc/shadow- /etc/gshadow-
else
	perm_fix -m 0000 -o 0 -g 0 /etc/shadow /etc/gshadow /etc/shadow- /etc/gshadow-
fi
#
# Fix Sudoers configuration
find /etc/sudoers.d /etc/sudoers -type f -exec perm_fix -m 600 -o 0 -g 0 {} +
find /etc/sudoers.d /etc/sudoers -type d -exec perm_fix -m 700 -o 0 -g 0 {} +





#
# Misc. System Files
#
# Can be improved
# Ensure only root can read the bootloader config
find /boot -type f -exec perm_fix -m 640 -o 0 -g 0 {} +
find /boot -type d -exec perm_fix -m 750 -o 0 -g 0 {} +
#
# Ensure SystemD unit files are secure
find /etc/systemd/system -type f -exec perm_fix -m 640 -o 0 -g 0 {} +
find /etc/systemd/system -type d -exec perm_fix -m 750 -o 0 -g 0 {} +
#
# Secure cronjobs
find /etc/cron.* /etc/crontab /etc/at.allow -type f -exec perm_fix -m 640 -o 0 -g 0 {} +
find /etc/cron.* /etc/crontab /etc/at.allow -type d -exec perm_fix -m 750 -o 0 -g 0 {} +
#
# Restrict privileged binaries
perm_fix -m 750 -o 0 -g 0 /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules /bin/dmesg /usr/bin/dmesg
#
# Secure SSH configurations/private keys, and public keys.
find /etc/ssh -type f -exec perm_fix -m 600 -o 0 -g 0 {} +
find /etc/ssh -type d -exec perm_fix -m 700 -o 0 -g 0 {} +
find /etc/ssh -name '*.pub' -type f -exec perm_fix -m 644 -o 0 -g 0 {} +
#
# Secure MOTD/banners are secured
perm_fix /etc/issue /etc/issue.net /etc/motd -m 644 -o 0 -g 0
#
# Secure logging directory
perm_fix -m 755 -o 0 -g 0 /var/log
find /var/log/ -mindepth 1 -type f -exec perm_fix -m 640 {} +
find /var/log/ -mindepth 1 -type d -exec perm_fix -m 750 {} +
#
# Some distros use the adm user for these logs
(
auditd_log_dir="$(dirname "$(awk -F\= '/^\s*log_file/ {print $2}' /etc/audit/auditd.conf | xargs)")"
if [[ "${os_info[ID]}" =~ ^(ubuntu|almalinux)$ && -d "${auditd_log_dir}" ]]
then find "${auditd_log_dir}" -type f -exec perm_fix -m 640 -o 0 -g adm {} +
else find "${auditd_log_dir}" -type f -exec perm_fix -m 0600 -o 0 -g 0 {} +
fi
chmod -c 0750 "${auditd_log_dir}"
)
#
# Secure AuditD/rsyslog configurations
find /etc/audit /etc/rsyslog.d/ /etc/rsyslog.conf -mindepth 1 -type f -exec perm_fix -m 640 -o 0 -g 0 {} +
find /etc/audit /etc/rsyslog.d/ -type d -exec perm_fix -m 750 -o 0 -g 0 {} +
#
# Secure global shell profiles
find /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/ -type f -exec perm_fix -m 644 -o 0 -g 0 {} +
find /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/ -type d -exec perm_fix -m 755 -o 0 -g 0 {} +
#
# Secure local home directories
# (including root's home @ /root)
# Iterate over all interactive users' home directories
(for user in "${int_users[@]}"; do
	home="$(grep "^${user}:" | tail -n1 | cut -d: -f6)"
	find "${home}" -type f -exec perm_fix -m 600 -o "${user}" -g "${user}" {} +
	find "${home}" -type d -exec perm_fix -m 700 -o "${user}" -g "${user}" {} +
done)
find /root -type f -exec perm_fix -m 600 -o 0 -g 0 {} +
find /root -type d -exec perm_fix -m 700 -o 0 -g 0 {} +
#
# Debian-based distros exclusive: APT keyrings
if [[ "${os_info[ID]}" == debian || "${os_info[ID]}" == ubuntu ]]; then
	[[ -d /etc/apt/trusted.gpg.d ]] && find /etc/apt/trusted.gpg.d -type f -exec perm_fix -m 644 -o 0 -g 0 {} +
	[[ -d /usr/share/keyrings ]] && find /usr/share/keyrings -type f -exec perm_fix -m 644 -o 0 -g 0 {} +
fi