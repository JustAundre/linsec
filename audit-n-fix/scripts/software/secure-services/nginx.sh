#!/usr/bin/env bash
# shellcheck shell=bash
#
# Setup
#
# Script variables
nginx_main_config='/etc/nginx/nginx.conf'
default_page='/etc/nginx/sites-available/default'
backup_dir='/etc/nginx/backup'
hardening_snippets='/etc/nginx/snippets/security-headers.conf'
general_hardening='/etc/nginx/conf.d/99-hardening.conf'
#
# Make/ensure existence of backup dir
mkdir -p "$backup_dir"





#
# Nginx Setup
#
# Refresh Nginx
(
	set -e
	secure_install nginx
	systemctl unmask nginx
	systemctl enable nginx
) || exit 5
#
# Stop Nginx for smooth configurations
systemctl stop nginx
#
# Backup existing configurations
(
	set -e
	cp -p "$nginx_main_config" "$backup_dir/nginx.conf"
	cp -p "$default_page" "$backup_dir/default"
	echo "ℹ️: Configuration backups are saved under ($backup_dir)."
)
#
# Add secure headers to outgoing requests
mkdir -p /etc/nginx/snippets
install -m 0640 -u root -g root ./general-confs/nginx-headers.conf "$hardening_snippets"
#
# General reduction of information leakage
install -m 0640 -u root -g root ./general-confs/99-hardening.conf "$general_hardening"
#
# Ensures it contains the conf.d include
if ! grep -qE 'include\s+/etc/nginx/conf\.d/\*\.conf;' "$nginx_main_config"; then
	# Insert inside the http {} block right after it opens
	sed -i~ '0,/http\s*{/s/http\s*{/http {\n\tinclude \/etc\/nginx\/conf.d\/\*\.conf;/' "$nginx_main_config"
fi
#
# Update the general-confs/default file with what is appropriate with your scenario
echo '🚧: Replacing default site with secure defaults...'
cat general-confs/default >/etc/nginx/sites-available/default
#
# Remove overlapping configuration values from nginx.conf
sed -i '/server_tokens/d' "$nginx_main_config"
sed -i '/client_body_buffer_size/d' "$nginx_main_config"
sed -i '/client_header_buffer_size/d' "$nginx_main_config"
sed -i '/client_max_body_size/d' "$nginx_main_config"
sed -i '/large_client_header_buffers/d' "$nginx_main_config"
sed -i '/ssl_protocols/d' "$nginx_main_config"
sed -i '/ssl_prefer_server_ciphers/d' "$nginx_main_config"
sed -i '/ssl_session_cache/d' "$nginx_main_config"
sed -i '/ssl_ciphers/d' "$nginx_main_config"




#
# Optional Hardening
#
# Install fail2ban with the standard nginx jails
if confirm 'Install and enable fail2ban with the nginx jails'; then
	(
		set -e
		secure_install fail2ban
		cat >/etc/fail2ban/jail.d/nginx.local <<-'EOF'
			[nginx-http-auth]
			enabled = true

			[nginx-botsearch]
			enabled = true

			[nginx-limit-req]
			enabled = true
		EOF
		systemctl enable --now fail2ban
	)
fi
#
# Generate strong Diffie-Hellman parameters for TLS
if confirm 'Generate strong DH parameters for TLS (can take a while)'; then
	(
		set -e
		openssl dhparam -out /etc/nginx/dhparam.pem 4096
		echo 'ssl_dhparam /etc/nginx/dhparam.pem;' >>"$general_hardening"
	)
fi





#
# Configuration Validation
#
echo '🚧: Testing Nginx configuration...'
if nginx -t; then
	cat <<-'EOF'
		✅: Nginx config is OK,
		🚧: Restarting Nginx...
	EOF
	systemctl restart nginx
else
	cat <<-'EOF'
		❌: Nginx config test failed.
		🚧: Reverting to backups...
	EOF
	cp -p "$backup_dir/nginx.conf" "$nginx_main_config"
	cp -p "$backup_dir/default" "$default_page"
	exit 1
fi