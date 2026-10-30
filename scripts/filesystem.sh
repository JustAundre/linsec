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
# Global Environment Configurations
#
reconfig -x replace UMASK 027 /etc/profile
reconfig -x replace UMASK 027 /etc/login.defs
reconfig -x replace USERGROUPS_ENAB yes /etc/login.defs
reconfig -x replace CREATE_HOME yes /etc/login.defs





#
# SUID/SGID Binaries
#
mapfile -t -d '' paths < "${log_dir}/suid-binaries.txt"
mapfile -t -d '' selections < <(PS2='Select paths to remove the SUID bit from' cl-new -m -o "${paths[@]}")
((${#selections[@]})) && chmod u-s -v -- "${selections[@]}"
mapfile -t -d '' paths < "${log_dir}/sgid-binaries.txt"
mapfile -t -d '' selections < <(PS2='Select paths to remove the SGID bit from' cl-new -m -o "${paths[@]}")
((${#selections[@]})) && chmod g-s -v -- "${selections[@]}"





#
# Identity & Authorization
#
# /etc/passwd, /etc/group and the shadow files (plus their backups)
perm-fix -s -m 644 -o 0 -g 0 /etc/passwd /etc/group
if grep -q -E '^shadow:' /etc/group; then
	perm-fix -s -m 640 -o 0 -g shadow /etc/shadow /etc/gshadow
	perm-fix -s -m 640 -o 0 -g 0 /etc/shadow- /etc/gshadow-
else
	perm-fix -s -m 600 -o 0 -g 0 /etc/shadow /etc/gshadow /etc/shadow- /etc/gshadow-
fi
#
# Sudoers configuration
if hash sudo &>/dev/null; then
	find /etc/sudoers.d /etc/sudoers -type f -print0 | perm-fix -s -m 640 -o 0 -g 0
	find /etc/sudoers.d -type d -print0 | perm-fix -s -m 750 -o 0 -g 0
fi





#
# Configurations
#
# Bootloader config
find /boot -type f -print0 | perm-fix -s -m 640 -o 0 -g 0
find /boot -type d -print0 | perm-fix -s -m 750 -o 0 -g 0
#
# AuditD/rsyslog configurations
find /etc/audit /etc/rsyslog.d /etc/rsyslog.conf -mindepth 1 -type f -print0 | perm-fix -s -m 640 -o 0 -g 0
find /etc/audit /etc/rsyslog.d -type d -print0 | perm-fix -s -m 750 -o 0 -g 0
#
# SSH configurations, private keys, and public keys.
if hash sshd &>/dev/null; then
	find /etc/ssh -type f -print0 | perm-fix -s -m 600 -o 0 -g 0
	find /etc/ssh -type d -print0 | perm-fix -s -m 750 -o 0 -g 0
	find /etc/ssh -name '*.pub' -type f -print0 | perm-fix -s -m 644 -o 0 -g 0
else
	log i 'SSHD not detected; skipping SSHD file permission fixes...'
fi
#
# Secure MOTD/banners are secured
perm-fix -s -m 644 -o 0 -g 0 /etc/issue /etc/issue.net /etc/motd
#
# Secure global shell profiles
find /etc/profile /etc/profile.d /etc/bashrc /etc/bash.bashrc -type f -print0 | perm-fix -s -m 644 -o 0 -g 0
find /etc/profile.d -type d -print0 | perm-fix -s -m 755 -o 0 -g 0
#
# Secure local home directories
mkdir -p "${log_dir}/home-diffs"
for entry in "${passwd[@]}"; do
	IFS=':' read -r -d $'\n' user _ uid gid _ home shell <<<"${entry}"
	[[ ${shell} =~ /('nologin'|'false')$ || ${home} =~ ^('/'|'/bin')$ ]] && continue
	perm-fix -s -m 700 -o "${uid}" -g "${gid}" "${home}" "${home}/.ssh" "${home}/.gnupg"
	perm-fix -s -m 600 -o "${uid}" -g "${gid}" "${home}/.ssh/authorized_keys" "${home}/.ssh/id_"*
	diff -r /etc/skel "${home}" --unified >"${log_dir}/home-diffs/${user}-${uid}"
done
#
# APT keyrings
find /etc/apt/trusted.gpg.d /usr/share/keyrings -type f -print0 | perm-fix -s -m 644 -o 0 -g 0
#
# FHS temp directories are world-writable w/ sticky-bit.
perm-fix -s -m 1777 -o 0 -g 0 /tmp /var/tmp /dev/shm





#
# Services
#
# SystemD units
if [[ ${init} == 'systemd' ]]; then
	find /etc/systemd/system -type f -print0 | perm-fix -s -m 640 -o 0 -g 0
	find /etc/systemd/system -type d -print0 | perm-fix -s -m 750 -o 0 -g 0
else
	log i 'Initialization system is not SystemD; not checking SystemD unit file permissions.'
fi
#
# Scheduled tasks
find /etc/crontab /etc/cron.d /etc/cron.allow /etc/cron.deny /etc/anacrontab -type f -print0 | perm-fix -s -m 640 -o 0 -g 0
find /etc/cron.{hourly,daily,weekly,monthly} -print0 | perm-fix -s -m 750 -o 0 -g 0





#
# Logs
#
# General Logs
perm-fix -s -m 755 -o 0 -g 0 /var/log
find /var/log -mindepth 1 -type f -print0 | perm-fix -s -m 640
find /var/log -mindepth 1 -type d -print0 | perm-fix -s -m 750
#
# AuditD logs
auditd_log_file="$(awk -F ' = ' '/^\s*log_file/ { print $2 }' /etc/audit/auditd.conf 2>/dev/null)"
auditd_log_dir="${auditd_log_file%/*}"
if [[ -n ${auditd_log_file} && -d ${auditd_log_dir} ]]; then
	group="$(awk -F '=' '/^log_group/ {gsub(/[ \t]/, "", $2); print $2}' /etc/audit/auditd.conf)"
	find -- "${auditd_log_dir}" -type f -print0 | perm-fix -s -m 640 -o 0 -g "${group}"
	find -- "${auditd_log_dir}" -type d -print0 | perm-fix -s -m 750 -o 0 -g "${group}"
	unset group
fi
#
# Disable core dumping
if [[ ${init} == 'systemd' ]]; then
	reconfig -x 'replace' -d '=' Storage none /etc/systemd/coredump.conf
	reconfig -x 'replace' -d '=' ProcessSizeMax 0 /etc/systemd/coredump.conf
else
	log i 'Initialization system is not SystemD; not configuring SystemD to disable coredumps.'
fi





#
# Binary Capabilities
#
while read -r -d '' path; do
	output="$(getcap "${path}" 2>/dev/null)"
	[[ -n ${path} ]] || continue
	caps="${output##* = }"
	printf '%s\0%s\0' "${path}" "${caps}" >"${log_dir}/binary-capabilities.txt"
done < <(
	find / -xephem -type f '(' -perm -001 -o -not -uid 0 -o -not -gid 0 ')'
)
