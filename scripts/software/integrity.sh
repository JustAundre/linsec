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
[[ ${init} == 'systemd' ]] && confirm 'Enable periodic updates' && case "${pkg_backend}" in
'apt-get')
	"${pkg_backend}" install --reinstall -y\
		-o Dpkg::Options::='--force-confnew'\
		-o Dpkg::Options::='--force-confmiss'\
		unattended-upgrades apt-listchanges
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





#
# Integrity Check
#
case "${pkg_backend}" in
'apt-get')
	mapfile -t options < <(
		dpkg -V |
			awk '$1 ~ /^..5/ {print $2}' |
			xargs -r dpkg -S |
			cut -d : -f 1 |
			sort -u
	)
	;;
'dnf'|'yum')
	mapfile -t options < <(
		rpm -V -a |
			awk '{print $NF}' |
			xargs -r rpm -q -f |
			sort -u
	)
	;;
'pacman')
	mapfile -t options < <(
		pacman -Q -k 2>&1 |
			awk '/gaps in/ {print $2}'
	)
	;;
'pkg')
	mapfile -t options < <(
		pkg check -s -a --checksum 2>&1 |
			awk -F : '/checksum mismatch|missing/ {print $1}' |
			sort -u
	)
	;;
esac
if ((!${#options[@]})); then
	log i 'Passed integrity check—no further action needed.'
	exit 0
fi
mapfile -t -d '' selections < <(PS2='Select packages to reinstall—the listed packages have been found to deviate from base installation.' cl-new -m -o "${options[@]}")
case "${pkg_backend}" in
'apt-get')
	"${pkg_backend}" install --reinstall -y "${selections[@]}"
	;;
'dnf'|'yum')
	"${pkg_backend}" reinstall -y "${selections[@]}"
	;;
'pacman')
	"${pkg_backend}" -S --noconfirm "${selections[@]}"
	;;
'pkg')
	"${pkg_backend}" install -f -y "${selections[@]}"
	;;
esac
