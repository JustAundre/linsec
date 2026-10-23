#!/usr/bin/env bash

firewalls=(
	'Uncomplicated Firewall (UFW)'
	'Firewall Daemon (FirewallD)'
)
if hash pfctl &>/dev/null; then
	selection='Packet Filters (pf)'
else
	selection="$(PS2='Select your firewall of choice' cl-new "${firewalls[@]}")"
fi
case "${selection}" in
*'(UFW)'*)
	xargs -n 1 modprobe <<<'ip_tables iptable_filter'
	mv -v /etc/ufw{,'.bak'}
	case "${pkg_backend}" in
	'apt-get')
		"${pkg_backend}" install --reinstall -y ufw -o Dpkg::Options::='--force-confnew' -o Dpkg::Options::='--force-confmiss'
		;;
	'dnf'|'yum')
		"${pkg_backend}" install -y ufw
		;;
	'pacman')
		"${pkg_backend}" -S ufw --noconfirm
		;;
	*)
		log e 'Package manager not supported.'
		exit 12
		;;
	esac
	mkdir -p /etc/ufw
	true >>/etc/ufw/before.rules 3>>/etc/ufw/before6.rules 4>>/etc/ufw/after.rules 5>>/etc/ufw/after6.rules
	ufw reset
	ufw default deny incoming
	ufw default allow outgoing
	systemctl unmask ufw
	systemctl enable --now ufw
	ufw --force enable
	;;
*'(FirewallD)'*)
	mv -v /etc/firewalld{,'.bak'}
	case "${pkg_backend}" in
	'apt-get')
		"${pkg_backend}" install --reinstall -y firewalld -o Dpkg::Options::='--force-confnew' -o Dpkg::Options::='--force-confmiss'
		;;
	'dnf'|'yum')
		"${pkg_backend}" install -y firewalld
		;;
	'pacman')
		"${pkg_backend}" -S --noconfirm firewalld
		;;
	*)
		log e 'Package manager not supported.'
		exit 12
		;;
	esac
	systemctl unmask firewalld
	systemctl enable --now firewalld
	firewall-cmd --reset-to-defaults
	firewall-cmd --set-default-zone public
	firewall-cmd --permanent --load-zone-defaults public
	firewall-cmd --permanent --add-icmp-block echo-request && log i 'Blocked ICMP echo requests.'
	firewall-cmd --permanent --add-icmp-block timestamp-reply && log i 'Blocked ICMP timestamp replies.'
	firewall-cmd --permanent --add-icmp-block timestamp-request && log i 'Blocked ICMP timestamp requests.'
	firewall-cmd --permanent --add-icmp-block redirect && log i 'Blocked ICMP redirects.'
	firewall-cmd --permanent --add-icmp-block address-mask-request && log i 'Blocked ICMP address mask requests.'
	firewall-cmd --permanent --add-icmp-block address-mask-reply && log i 'Blocked ICMP address mask replies.'
	firewall-cmd --permanent --add-icmp-block router-solicitation && log i 'Blocked ICMP router solicitation requests.'
	firewall-cmd --permanent --add-icmp-block router-advertisement && log i 'Blocked ICMP router advertisement requests.'
	firewall-cmd --permanent --add-icmp-block information-request && log i 'Blocked ICMP information requests.'
	firewall-cmd --permanent --add-icmp-block information-reply && log i 'Blocked ICMP information replies.'
	firewall-cmd --reload
	;;
*'(pf)'*)
	pkg install -fy FreeBSD-pf && log i 'Reinstalled "Packet Filters" package.'
	mv -v /etc/pf.conf{,'.bak'} && log i 'Backed up current pf configuration.'
	install -o 0 -g wheel -m 640 cnf/pf.conf /etc/pf.conf && log i 'Installed preset pf configuration.'
	if pfctl -nf /etc/pf.conf; then
		log i 'Passed syntax check.'
		rm -v /etc/pf.conf~
		pfctl -f /etc/pf.conf && log i 'Reloaded pf configuration.'
	else
		log e 'New pf configuration failed syntax check.'
		if [[ -f '/etc/pf.conf.bak' ]]; then
			mv -vf /etc/pf.conf{'.bak',} && log i 'Restored original pf configuration.'
			pfctl -f /etc/pf.conf && log i 'Reloaded original pf configuration.'
		else
			rm -v /etc/pf.conf{,'.bak'}
		fi
	fi
	service pf restart
	;;
*)
	log e 'Firewall software unsupported.'
	exit 11
	;;
esac
