#!/usr/bin/env bash





#
# Reset & Regen
#
# Backup existing SSH configs
declare -A ssh
ssh[root]='/etc/ssh'
ssh[backup]="${ssh[root]}.$(date +%s).bak"
mv -v "${ssh[root]}" "${ssh[backup]}"
#
# Reinstall SSHD
case "${pkg_backend}" in
	'apt-get') "${pkg_backend}" install --reinstall openssh-server -y -o Dpkg::Options::='--force-confnew' -o Dpkg::Options::='--force-confmiss' ;;
	'dnf') "${pkg_backend}" reinstall openssh-server -y ;;
	'yum') "${pkg_backend}" reinstall openssh-server -y ;;
	'pacman') "${pkg_backend}" -S openssh --noconfirm ;;
	'pkg') "${pkg_backend}" install -f sshd ;;
esac
#
# Regenerate
ssh-keygen -A
ssh-keygen -f /root/.ssh/known_hosts -R localhost
#
# Install preset sshd_config file
install -o 0 -g 0 -m 640 -v cnf/sshd_config /etc/ssh/sshd_config





#
# Optional Hardening
#
# Install fail2ban with the standard SSHD jails.
if confirm 'Install, enable and configure fail2ban for SSHD'; then
	case "${pkg_backend}" in
	'apt-get') "${pkg_backend}" install --reinstall fail2ban -y -o Dpkg::Options::='--force-confmiss' ;;
	'dnf') "${pkg_backend}" reinstall fail2ban -y ;;
	'yum') "${pkg_backend}" reinstall fail2ban -y ;;
	'pacman') "${pkg_backend}" -S fail2ban --noconfirm ;;
	'pkg') "${pkg_backend}" install -f fail2ban ;;
	esac
	mkdir -v -p /etc/fail2ban/jail.d
	install -v -m 640 -o 0 -g 0 cnf/f2b/nginx.local /etc/fail2ban/jail.d/sshd.local
	systemctl enable --now fail2ban
fi





#
# Diff
#
diff "${ssh[root]}" "${ssh[backup]}" -r -p > "${log_dir}/ssh_config_diffs.txt"
diff "${ssh[root]}" "${ssh[backup]}" -r -p --color=always | less -R
