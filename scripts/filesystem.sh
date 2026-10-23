#!/usr/bin/env bash





#
# Environment Setup
#
log i 'Conducting filesystem searches for various criterias...'
log i 'This may take a while.'
find / -xephem -perm -0002 '(' -type f -o -type d ')' -print0 > "${log_dir}/world-writables.txt" &
find / -xephem -type f -perm -4000 -print0 > "${log_dir}/suid-binaries.txt" &
find / -xephem -type f -perm -2000 -print0 > "${log_dir}/sgid-binaries.txt" &
find / -xephem -nouser -print0 > "${log_dir}/no-user.txt" &
find / -xephem -nogroup -print0 > "${log_dir}/no-group.txt" &
find / -xephem -xtype l -print0 > "${log_dir}/broken-symlinks.txt" &
LC_ALL=C find / -xephem -name '*[! -~]*' -print0 > "${log_dir}/non-ascii-paths.txt" &
find / -xephem -name '[^a-zA-Z0-9_.]*' -print0 > "${log_dir}/non-alphanumeric-leads.txt" &
find /etc '(' -uid +"${id_bounds[SYS_UID_MAX]}" -o -gid +"${id_bounds[SYS_GID_MAX]}" ')' > "${log_dir}/etc-user-owned.txt" &
find /home -mindepth 2 -maxdepth 2 -type f '(' -name .rhosts -o -name .shosts -o -name .netrc -o -name .forward -o -path '/home/*/.ssh/rc' ')' > "${log_dir}/bad-user-configs.txt" &
wait





#
# Login.defs
#
reconfig -x replace UMASK 027 /etc/profile
reconfig -x replace UMASK 027 /etc/login.defs
reconfig -x replace USERGROUPS_ENAB yes /etc/login.defs
reconfig -x replace CREATE_HOME yes /etc/login.defs





#
# SUID/SGID Binaries
#
mapfile -td '' paths < "${log_dir}/suid-binaries.txt"
mapfile -td '' selections < <(PS2='Select paths to remove the SUID bit from' cl-new -mo "${paths[@]}")
((${#selections[@]})) && chmod u-s -v -- "${selections[@]}"
mapfile -td '' paths < "${log_dir}/sgid-binaries.txt"
mapfile -td '' selections < <(PS2='Select paths to remove the SGID bit from' cl-new -mo "${paths[@]}")
((${#selections[@]})) && chmod g-s -v -- "${selections[@]}"





#
# Identity & Authorization
#
# /etc/passwd, /etc/group and the shadow files (plus their backups)
perm-fix -m 644 -o 0 -g 0 /etc/passwd /etc/group
if grep -qE '^shadow:' /etc/group; then
	perm-fix -m 640 -o 0 -g shadow /etc/shadow /etc/gshadow
	perm-fix -m 640 -o 0 -g 0 /etc/shadow- /etc/gshadow-
else
	perm-fix -m 600 -o 0 -g 0 /etc/shadow /etc/gshadow /etc/shadow- /etc/gshadow-
fi
#
# Sudoers configuration
find /etc/sudoers.d /etc/sudoers -type f -print0 | perm-fix -m 640 -o 0 -g 0
find /etc/sudoers.d -type d -print0 | perm-fix -m 750 -o 0 -g 0





#
# Configurations
#
# Bootloader config
find /boot -type f -print0 | perm-fix -m 640 -o 0 -g 0
find /boot -type d -print0 | perm-fix -m 750 -o 0 -g 0
#
# AuditD/rsyslog configurations
find /etc/audit /etc/rsyslog.d /etc/rsyslog.conf -mindepth 1 -type f -print0 | perm-fix -m 640 -o 0 -g 0
find /etc/audit /etc/rsyslog.d -type d -print0 | perm-fix -m 750 -o 0 -g 0
#
# SSH configurations, private keys, and public keys.
find /etc/ssh -type f -print0 | perm-fix -m 600 -o 0 -g 0
find /etc/ssh -type d -print0 | perm-fix -m 750 -o 0 -g 0
find /etc/ssh -name '*.pub' -type f -print0 | perm-fix -m 644 -o 0 -g 0
#
# Secure MOTD/banners are secured
perm-fix -m 644 -o 0 -g 0 /etc/issue /etc/issue.net /etc/motd
#
# Secure global shell profiles
find /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d -type f -print0 | perm-fix -m 644 -o 0 -g 0
find /etc/profile.d -type d -print0 | perm-fix -m 755 -o 0 -g 0
#
# Secure local home directories
for entry in "${passwd[@]}"; do
	IFS=':' read -rd $'\n' user _ uid gid _ home shell <<<"${entry}"
	[[ ${shell} =~ /('nologin'|'false')$ || ${home} =~ ^('/'|'/bin')$ ]] && continue
	perm-fix -m 700 -o "${uid}" -g "${gid}" "${home}" "${home}/.ssh" "${home}/.gnupg"
	perm-fix -m 600 -o "${uid}" -g "${gid}" "${home}/.ssh/authorized_keys" "${home}/.ssh/id_"*
	log i "Comparing home contents with factory home directory for user: ${user@Q}"
	pause 0
	diff -r /etc/skel "${home}" --color=force --unified | less -R
done
#
# APT keyrings
find /etc/apt/trusted.gpg.d /usr/share/keyrings -type f -print0 | perm-fix -m 644 -o 0 -g 0
#
# FHS temp directories are world-writable w/ sticky-bit.
perm-fix -m 1777 -o 0 -g 0 /tmp /var/tmp /dev/shm





#
# Services
#
# SystemD units
find /etc/systemd/system -type f -print0 | perm-fix -m 640 -o 0 -g 0
find /etc/systemd/system -type d -print0 | perm-fix -m 750 -o 0 -g 0
#
# Scheduled tasks
find /etc/crontab /etc/cron.d /etc/cron.allow /etc/cron.deny /etc/anacrontab -type f -print0 | perm-fix -m 640 -o 0 -g 0
find /etc/cron.{hourly,daily,weekly,monthly} -type f -print0 | perm-fix -m 750 -o 0 -g 0
find /etc/cron.* -type d -print0 | perm-fix -m 750 -o 0 -g 0





#
# Logs
#
# General Logs
perm-fix -m 755 -o 0 -g 0 /var/log
find /var/log -mindepth 1 -type f -print0 | perm-fix -m 640
find /var/log -mindepth 1 -type d -print0 | perm-fix -m 750
#
# AuditD logs
auditd_log_file="$(awk -F ' = ' '/^\s*log_file/ { print $2 }' /etc/audit/auditd.conf 2>/dev/null)"
auditd_log_dir="${auditd_log_file%/*}"
if [[ -n ${auditd_log_file} && -d ${auditd_log_dir} ]]; then
	group="$(awk -F '=' '/^log_group/ {gsub(/[ \t]/, "", $2); print $2}' /etc/audit/auditd.conf)"
	find -- "${auditd_log_dir}" -type f -print0 | perm-fix -m 640 -o 0 -g "${group}"
	find -- "${auditd_log_dir}" -type d -print0 | perm-fix -m 750 -o 0 -g "${group}"
	unset group
fi
#
# Disable core dumping
reconfig -x 'replace' -d '=' Storage none /etc/systemd/coredump.conf
reconfig -x 'replace' -d '=' ProcessSizeMax 0 /etc/systemd/coredump.conf
