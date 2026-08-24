#!/usr/bin/env bash
#
# Setup
#
# Script Variables
vsftpdConfig="/etc/vsftpd.conf"
backup="/etc/vsftpd.conf.bak"
certDir=/etc/ssl/private
certFile="${certDir}/vsftpd.pem"
#
# A function to apply VSFTPD configurations
set_vsftpd_config() {
	local key="${1}"
	local value="${2}"

	if grep -qE "^#?\s*${key}=" "${vsftpdConfig}"; then
		sed -i "s|^\s*#\?\s*${key}=.*|${key}=${value}|" "${vsftpdConfig}"
	else
		echo "${key}=${value}" >> "${vsftpdConfig}"
	fi
}
#
# Backup existing configurations
cp -p "${vsftpdConfig}" "${backup}"
echo "✅: Backed up VSFTPD confugrations to ${backup}"





#
# Install/Verify Integrity of VSFTPD
#
# vsftpd openssl





#
# Harden VSFTPD
#
if ! [[ -f "${certFile}" ]]; then
	echo "🚧: Generating TLS certificate"
	openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout "${certFile}" -out "${certFile}" -subj "/CN=FTP Server"
	chmod 600 "${certFile}"
fi
# Disable anonymous access
echo "🚧: Applying secure VSFTPD configurations..."
set_vsftpd_config "anonymous_enable" "NO"
#
# Local users only
set_vsftpd_config "local_enable" "YES"
set_vsftpd_config "write_enable" "YES"
#
# Chroot/anchor users to their home directories
set_vsftpd_config "chroot_local_user" "YES"
set_vsftpd_config "allow_writeable_chroot" "YES"
#
# Restrict file permissions
set_vsftpd_config "local_umask" "022"
#
# Disable risky features
set_vsftpd_config "dirmessage_enable" "NO"
set_vsftpd_config "xferlog_enable" "YES"
set_vsftpd_config "port_enable" "NO"
#
# Enable Logging
set_vsftpd_config "log_ftp_protocol" "YES"
set_vsftpd_config "vsftpd_log_file" "/var/log/vsftpd.log"
#
# Connection limits (brute-force mitigation)
set_vsftpd_config "max_clients" "10"
set_vsftpd_config "max_per_ip" "3"
set_vsftpd_config "pasv_enable" "YES"
set_vsftpd_config "pasv_min_port" "40000"
set_vsftpd_config "pasv_max_port" "40100"
#
# Idle/timeout limits
set_vsftpd_config "idle_session_timeout" "600"
set_vsftpd_config "data_connection_timeout" "300"
#
# Banner
set_vsftpd_config "ftpd_banner" "Authorized access only."
#
# TLS Hardening
set_vsftpd_config "ssl_enable" "YES"
set_vsftpd_config "rsa_cert_file" "$certFile"
set_vsftpd_config "rsa_private_key_file" "$certFile"
#
# Force Encryption
set_vsftpd_config "force_local_logins_ssl" "YES"
set_vsftpd_config "force_local_data_ssl" "YES"
#
# Disable Weak SSL
set_vsftpd_config "ssl_sslv2" "NO"
set_vsftpd_config "ssl_sslv3" "NO"
set_vsftpd_config "ssl_tlsv1" "NO"
set_vsftpd_config "ssl_tlsv1_1" "NO"
set_vsftpd_config "ssl_tlsv1_2" "YES"
#
# Strong ciphers
set_vsftpd_config "ssl_ciphers" "HIGH"
#
# Hide users
set_vsftpd_config "userlist_enable" "YES"
set_vsftpd_config "userlist_deny" "NO"
set_vsftpd_config "require_ssl_reuse" "NO"





#
# Configuration Validation
#
# vsftpd has no syntax-check flag; a valid config keeps the daemon running in the foreground, so use a timeout. Exit 124 means it survived until killed (valid).
timeout 2 vsftpd "${vsftpdConfig}" &>/dev/null
if [[ $? -eq 124 ]]; then
	systemctl restart vsftpd
	echo "✅: VSFTPD started securely"
else
	echo "❌: Configuration validation error; reverting to backup(s)..."
	cp -p "${backup}" "${vsftpdConfig}"
	systemctl restart vsftpd
	exit 1
fi