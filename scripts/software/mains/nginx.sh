#!/usr/bin/env bash
# TODO: Needs cross-distro testing





#
# Setup
#
# Refuse to operate on broken configurations
if ! nginx -t; then
	log e 'Refused to operate on a broken configuration.'
	log w 'Please fix your current Apache configuration before running this script. (Try "nginx -t"?)'
	exit 11
fi
#
# Script variables
declare -A nginx
nginx[root]='/etc/nginx'
nginx[backup]="${nginx[root]}.$(date +%s).bak"
nginx[snippets]="${nginx[root]}/snippets"
nginx[config]="${nginx[root]}/nginx.conf"
nginx[ssl_cert]='/etc/nginx/ssl/server.crt'
nginx[ssl_key]='/etc/nginx/ssl/server.key'
#
# Stop Nginx
log i 'Stopping Nginx...'
systemctl stop nginx
#
# Backup current configuration
log i "Backing up ${nginx[root]@Q} to ${nginx[backup]}..."
cp -av "${nginx[root]}" "${nginx[backup]}"





#
# Nginx Setup
#
mkdir -v -p "${nginx[snippets]}"
#
# Remove conflicting entries from nginx.conf
log i "Deduplicating ${nginx[config]@Q}..."
directives=(
	"server_tokens"
	"client_body_buffer_size"
	"client_header_buffer_size"
	"client_max_body_size"
	"large_client_header_buffers"
	"ssl_protocols"
	"ssl_prefer_server_ciphers"
	"ssl_ciphers"
	"ssl_session_cache"
	"ssl_session_timeout"
	"include ${nginx[snippets]}/security-hardening.conf;"
	"include ${nginx[snippets]}/ssl-hardening.conf;"
	"include ${nginx[snippets]}/server-tls.conf;"
	"listen"
)
for directive in "${directives[@]}"; do
	sed -Ei "\|^[[:space:]]*${directive}[[:space:]]|d" "${nginx[config]}"
done
#
# Create TLS snippet
log i 'Creating RSA:4096 certificate/key pair...'
mkdir -pv "$(dirname "${nginx[ssl_cert]}")"
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout "${nginx[ssl_key]}" -out "${nginx[ssl_cert]}"
cat > "${nginx[snippets]}/server-tls.conf" <<-EOF
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;
	http2 on;
	ssl_certificate ${nginx[ssl_cert]};
	ssl_certificate_key ${nginx[ssl_key]};
EOF
perm-fix -m 640 -o 0 -g 0 "${nginx[snippets]}/server-tls.conf"
#
# Import hardening configuration snippets
install -m 640 -o 0 -g 0 -D -v cnf/nginx/ssl-hardening.conf "${nginx[snippets]}/ssl-hardening.conf"
install -m 640 -o 0 -g 0 -D -v cnf/nginx/security-hardening.conf "${nginx[snippets]}/security-hardening.conf"
#
# Import snippets to all server blocks
insq "${nginx[config]}" 'server[[:space:]]*\{' append 1\
	"include ${nginx[snippets]}/security-hardening.conf;"\
	"include ${nginx[snippets]}/server-tls.conf;"\
	"include ${nginx[snippets]}/ssl-hardening.conf;"





#
# Optional Hardening
#
# Install fail2ban with the standard nginx jails
# TODO: Needs refactoring
if confirm 'Install, enable and configure fail2ban for Nginx'; then
	pkg-mgr install fail2ban
	mkdir -vp /etc/fail2ban/jail.d
	install -vm 640 -o 0 -g 0 cnf/f2b/nginx.local /etc/fail2ban/jail.d/nginx.local
	systemctl enable --now fail2ban
fi





#
# Configuration Validation
#
if ! nginx -t; then
	log e 'Configuration failed validation.'
	log i 'Reverting configuration to backup...'
	rm -rfv "${nginx[root]}"
	mv -v "${nginx[backup]}" "${nginx[root]}"
	systemctl restart nginx
	exit 12
fi
log i 'Configuration passed validation.'
systemctl restart nginx
