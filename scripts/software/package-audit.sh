#!/usr/bin/env bash





#
# Environment Setup
#
pkg_owner() {
	local pkg=''
	case "${pkg_backend}" in
	'apt-get')
		pkg="$(dpkg -S "${1}" 2>/dev/null)"
		[[ -z ${pkg} ]] && pkg="$(dpkg -S "${1#'/usr'}" 2>/dev/null)"
		pkg="${pkg%%[:,]*}"
		;;
	'dnf'|'yum')
		pkg="$(rpm -qf --qf '%{NAME}\n' "${1}" 2>/dev/null)"
		;;
	'pacman')
		pkg="$(pacman -Qoq "${1}" 2>/dev/null)"
		;;
	'pkg')
		pkg="$(pkg which -q "${1}" 2>/dev/null)"
		pkg="${pkg%-*}"
		;;
	esac
	echo "${pkg}"
}
export -f pkg_owner
badware=(
	telnet telnetd rsh rwho rusers ftp tftp in.tftpd vsftpd proftpd pure-ftpd
	finger in.fingerd talk in.talkd inetd xinetd rpcbind ypserv ypbind exportfs
	showmount snmpd smbd pptpd sendmail cups-browsed bluetoothd nscd x11vnc
	vncserver xrdp transmission-gtk deluge aisleriot gnome-mines freeciv
	minetest sshpass doona xproble
)
crackers=(
	nmap ncat nc socat cryptcat masscan zmap hping3 netdiscover arp-scan
	john hashcat hydra medusa ncrack ophcrack fcrackzip pdfcrack
	crunch cewl crack wireshark tshark tcpdump ettercap dsniff sslstrip
	yersinia macchanger aircrack-ng kismet reaver wifite nikto sqlmap
	wpscan dirb gobuster wfuzz burpsuite zaproxy msfconsole proxychains tor
)
services=(
	apache2 httpd nginx lighttpd tomcat tomcat9 jetty nodejs php-fpm
	mysql mariadb postgresql redis memcached mongodb rabbitmq-server
	squid vsftpd proftpd pure-ftpd bind9 openldap-server samba nmbd dovecot
)
declare identified_pkgs=() unidentified_pkgs=()





#
# Identify Common Unauthorized Software
#
log i 'Querying for common unauthorized software (this will take a while)...'
for bin in "${badware[@]}" "${crackers[@]}"; do
	hash "${bin}" &>/dev/null || continue
	path="$(realpath "$(command -v "${bin}")")"
	pkg="$(pkg_owner "${path}")"
	if [[ -n ${pkg} ]]; then
		# Package identified by package manager
		identified_pkgs+=("${pkg}")
	fi
done





#
# Identify Binaries with No Associated Package
#
log i 'Querying for binaries with no associated package (this will take a while)...'
mapfile -t -d ':' PATH_array <<<"${PATH}"
while IFS='' read -r -d '' bin; do
	pkg="$(pkg_owner "${bin}")"
	if [[ -z ${pkg} ]]; then
		# Binary not associated with any package
		unidentified_pkgs+=("${bin}")
	fi
done < <(
	find "${PATH_array[@]}" -type f -executable -exec realpath -z {} + |
		sort -uz
)





#
# Identify Services
#
log i 'Querying for common services (this will take a while)...'
for bin in "${services[@]}"; do
	hash "${bin}" &>/dev/null || continue
	path="$(realpath "$(command -v "${bin}")")"
	pkg="$(pkg_owner "${path}")"
	if [[ -n ${pkg} ]]; then
		identified_pkgs+=("${pkg}")
	fi
done





#
# Query User for Removal
#
mapfile -t -d '' selections_1 < <(PS2='Select identified potentially unwanted software to remove' cl-new -m -o "${identified_pkgs[@]}")
mapfile -t -d '' selections_2 < <(PS2='Select binaries with no associated package to remove' cl-new -m -o "${unidentified_pkgs[@]}")
mapfile -t -d '' selections_3 < <(PS2='Select services to remove' cl-new -m -o "${services[@]}")
((${#selections_1[@]} + ${#selections_2[@]} + ${#selections_3[@]})) && for selection in "${selections_1[@]}" "${selections_2[@]}" "${selections_3[@]}"; do
	case "${pkg_backend}" in
	'apt-get')
		"${pkg_backend}" remove --purge -y "${selection}"
		;;
	'dnf'|'yum')
		"${pkg_backend}" remove -y "${selection}"
		;;
	'pacman')
		"${pkg_backend}" -Rns --noconfirm "${selection}"
		;;
	'pkg')
		"${pkg_backend}" delete -y "${selection}"
		;;
	esac
done || true
