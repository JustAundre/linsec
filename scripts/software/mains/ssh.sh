#!/usr/bin/env bash





#
# Reset & Regen
#
# Backup existing SSH configs
mv -v /etc/ssh{,'.bak'}
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
# Diff
#
diff /etc/ssh{,'.bak'} -rp > "${log_dir}/ssh_config_diffs.txt"
diff /etc/ssh{,'.bak'} -rp --color=always | less -R
