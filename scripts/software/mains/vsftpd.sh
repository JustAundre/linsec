#!/usr/bin/env bash





#
# Environment Setup
#
# Script Variables
vsftpd_config='/etc/vsftpd.conf'
cert_file='/etc/ssl/private/vsftpd.pem'





#
# Reset VSFTPD
#
# Backup existing configuration
mv -v "${vsftpd_config}"{,'.bak'}
#
# Reinstall VSFTPD
case "${pkg_backend}" in
	'apt-get') "${pkg_backend}" install --reinstall vsftpd -y -o Dpkg::Options::='--force-confnew' -o Dpkg::Options::='--force-confmiss' ;;
	'dnf'|'yum') "${pkg_backend}" reinstall vsftpd -y ;;
	'pacman') "${pkg_backend}" -S vsftpd --noconfirm ;;
	'pkg') "${pkg_backend}" install -f vsftpd ;;
esac
#
# Create SSL certificate
if [[ ! -f "${cert_file}" ]]; then
	openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout "${cert_file}" -out "${cert_file}" -subj "/CN=FTP Server"
	perm-fix -o 0 -g 0 -m 600 "${cert_file}"
fi
#
# Install preset configuration
install -o 0 -g 0 -m 640 -v "cnf/$(basename "${vsftpd_config}")" "${vsftpd_config}"






#
# Configuration Validation
#
# Vsftpd has no syntax-check flag; a valid config keeps the daemon running in the foreground, so use a timeout. Exit 124 means it survived until killed (valid).
timeout 2 vsftpd "${vsftpd_config}" &>/dev/null
if ((${?} != 124)); then
	log e 'Configuration validation failed.'
	rm -v "${vsftpd_config}"
	mv -v "${vsftpd_config}"{'.bak',}
	systemctl restart vsftpd
	exit 11
fi
systemctl restart vsftpd
