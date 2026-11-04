#!/usr/bin/env bash





#
# Enable Periodic Source Updates
#
case "${pkg_backend}" in
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
