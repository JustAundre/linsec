#!/usr/bin/env bash





#
# Reset Sources
#
confirm 'Reset package manager sources' && case "${os_info[ID]}" in
'ubuntu'|'debian')
	mv -v /etc/apt/sources.list{,".bak.$(date +%s)"}
	install -p -v -m 640 -o 0 -g 0\
		<(sed "s${sed_delim}CODENAME${sed_delim}$(lsb_release -c -s)${sed_delim}" "cnf/sources/${os_info[ID]}.repo")\
		/etc/apt/sources.list
	;;
'linuxmint')
	mv -v /etc/apt/sources.list{,".bak.$(date +%s)"}
	install -p -v -m 640 -o 0 -g 0\
		<(sed "s${sed_delim}CODENAME${sed_delim}${os_info[UBUNTU_CODENAME]}${sed_delim}" cnf/sources/ubuntu.repo)\
		/etc/apt/sources.list
	;;
'rhel'|'centos')
	for repo in /etc/yum.repos.d/*.repo; do
		mv -v "${repo}" "${repo}.bak.$(date +%s)"
	done
	install -p -v -m 644 -o 0 -g 0\
		<(sed "s${sed_delim}RELEASEVER${sed_delim}${os_info[VERSION_ID]%%.*}${sed_delim}" "cnf/sources/${os_info[ID]}.repo")\
		"/etc/yum.repos.d/${os_info[ID]}.repo"
	;;
esac





#
# Enable Periodic Source Updates
#
[[ ${init} == 'systemd' ]] && case "${pkg_backend}" in
'apt-get')
	"${pkg_backend}" install -y unattended-upgrades apt-listchanges
	install -p -v -m 640 -o 0 -g 0 cnf/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
	install -p -v -m 640 -o 0 -g 0 cnf/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
	dpkg-reconfigure --priority=low unattended-upgrades
	systemctl enable --now apt-daily-upgrade.timer
	;;
'dnf')
	"${pkg_backend}" install -y dnf-automatic
	systemctl enable --now dnf-automatic.timer
	;;
'yum')
	"${pkg_backend}" install -y yum-cron
	systemctl enable --now yum-cron
	;;
esac
