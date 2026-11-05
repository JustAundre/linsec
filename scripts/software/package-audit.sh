#!/usr/bin/env bash





#
# Environment Setup
#
# Note: not package names--theyre binaries.
badware=(
	telnet in.telnetd rsh rwho rusers ftp tftp in.tftpd finger
	talk in.talkd inetd xinetd rpcbind ypserv ypbind exportfs
	snmpd pptpd sendmail cups-browsed bluetoothd nscd x11vnc
	xrdp transmission-gtk xprobe2 vncserver showmount in.fingerd
	vsftpd proftpd pure-ftpd
)
crackers=(
	nmap ncat nc socat cryptcat masscan zmap hping3 netdiscover
	arp-scan john hashcat hydra medusa ncrack ophcrack fcrackzip
	pdfcrack doona crunch cewl Crack wireshark tshark tcpdump
	ettercap dsniff sslstrip yersinia macchanger aircrack-ng
	reaver wifite nikto sqlmap sshpass wpscan dirb gobuster
	burpsuite zaproxy msfconsole proxychains4 tor kismet wfuzz
)
services=(
	apache2 httpd nginx lighttpd catalina.sh jetty.sh php-fpm
	mysqld mariadbd postgres redis-server memcached mongod
	squid named slapd smbd nmbd dovecot rabbitmq-server node
)





#
# Identify Common Unauthorized Software
#
log i 'Querying for common unauthorized software (this will take a while)...'
mapfile -t paths < <(which "${badware[@]}" "${crackers[@]}" 2>/dev/null | xargs realpath)
for path in "${paths[@]}"; do
	ufpm query-owner "${path}"
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
	ufpm query-owner "${bin}"
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
mapfile -t paths < <(which "${services[@]}" 2>/dev/null | xargs realpath)
for path in "${paths[@]}"; do
	ufpm query-owner "${path}"
	if [[ -n ${pkg} ]]; then
		identified_services+=("${pkg}")
	fi
done





#
# Query User for Removal
#
mapfile -t -d '' selections_1 < <(PS2='Select identified potentially unwanted software to remove' cl-new -m -o "${identified_pkgs[@]}")
mapfile -t -d '' selections_2 < <(PS2='Select binaries with no associated package to remove' cl-new -m -o "${unidentified_pkgs[@]}")
mapfile -t -d '' selections_3 < <(PS2='Select services to remove' cl-new -m -o "${identified_services[@]}")
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
