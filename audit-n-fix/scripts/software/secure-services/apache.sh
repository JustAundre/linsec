#!/usr/bin/env -iS /usr/bin/bash --noprofile --norc
# shellcheck shell=bash
#
# Setup
#
. ../.allrc
apache_main_config="/etc/apache2/apache2.conf"
apache_additional_config="/etc/apache2/conf-enabled/99-apache-security.conf"
#
# Confirm existence of drop-in configuration file
touch "$apache_additional_config"
#
# Append a configuration if the configuration doesn't already exist; otherwise skip.
safe_add() {
	grep -qF -- "$1" "$apache_main_config" ||
	echo "$1" >>"$apache_main_config"
}





#
# Service Hardening
#
# Comment out Indexing commands in ALL config files (prevents the "Invalid command IndexIgnore" error)
find /etc/apache2 -type f -name "*.conf"\
	-exec sed -i~ "s/^\s*IndexIgnore/# IndexIgnore/g" {} +
find /etc/apache2 -type f -name "*.conf"\
	-exec sed -i "s/^\s*IndexOptions/# IndexOptions/g" {} +
#
# Fix the "Options" error in main config
sed -i 's/^.*Options.*Indexes.*$/\tOptions None/g' "$apache_main_config"
#
# Disable risky modules (no confirmation)
echo "🚧: Disabling risky modules..."
a2dismod -fq autoindex status info
#
# Hide version information
echo "🚧: Preventing web server version leaks..."
safe_add "ServerTokens Prod"
safe_add "ServerSignature Off"
#
# Standardizes the /var/www/ block to "Options None" and "AllowOverride None"
echo "🚧: Hardening Directory blocks..."
sed -Ei~ '
	/<Directory\s+\/var\/www\/>/,/<\/Directory>/ {
		s/^\s*Options.*/\tOptions None/
		s/^\s*AllowOverride.*/\tAllowOverride None/
	}
' "$apache_main_config"
# if service goes down, try AllowOverride AuthConfig or AllowOverride All
#
# Header Configuration
echo "🚧: Adding Security Headers..."
echo '
	<IfModule mod_headers.c>
		Header always set X-Frame-Options "SAMEORIGIN"
		Header always set X-Content-Type-Options "nosniff"
		Header set X-XSS-Protection "1"
	</IfModule>
' >>"$apache_main_config"




#
# Extended Hardening
#
if confirm 'Apply extended Apache hardening (TRACE, default site, modules, TLS, WAF)'; then
	# Disable HTTP TRACE
	echo "🚧: Disabling HTTP TRACE..."
	if grep -q '^TraceEnable' "$apache_main_config"; then
		sed -i 's/^TraceEnable.*/TraceEnable off/' "$apache_main_config"
	else
		safe_add "TraceEnable off"
	fi
	#
	# Remove the default site
	echo "🚧: Disabling the default site..."
	if [[ -f /etc/apache2/sites-enabled/000-default.conf ]]; then
		a2dissite 000-default.conf || true
	fi
	#
	# Disable additional risky modules (if present)
	echo "🚧: Disabling additional risky modules..."
	a2dismod -fq cgi userdir proxy proxy_http proxy_balancer proxy_ftp 2>/dev/null || true
	#
	# Limit the request body size
	safe_add "LimitRequestBody 10485760"
	#
	# Strip ETag headers
	safe_add "FileETag None"
	echo 'Header unset ETag' >>"$apache_main_config"
	#
	# Strict TLS configuration (only when mod_ssl is active)
	if a2query -m ssl >/dev/null 2>&1; then
		echo "🚧: Hardening SSL configuration..."
		ssl_conf=/etc/apache2/mods-enabled/ssl.conf
		if [[ -f "$ssl_conf" ]]; then
			sed -Ei 's/^\s*SSLProtocol.*/SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1/' "$ssl_conf"
			sed -Ei 's/^\s*SSLCipherSuite.*/SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!CAMELLIA/' "$ssl_conf"
			grep -q '^SSLHonorCipherOrder' "$ssl_conf" ||
				echo 'SSLHonorCipherOrder On' >>"$ssl_conf"
		fi
	fi
	#
	# WAF: ModSecurity + OWASP CRS + mod_evasive
	if confirm 'Install ModSecurity + OWASP CRS + mod_evasive (WAF)'; then
		(
			set -e
			secure_install libapache2-mod-security2 modsecurity-crs libapache2-mod-evasive
			a2enmod security2 evasive
			if [[ -f /etc/modsecurity/modsecurity.conf-recommended && ! -f /etc/modsecurity/modsecurity.conf ]]; then
				cp -p /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
			fi
			sed -i 's/^SecRuleEngine .*/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf
		)
	fi
fi





#
# Configuration Validation
#
echo "🚧: Verifying configuration syntax..."
a2enmod headers
if apache2ctl -t; then
	echo "
		✅: Syntax OK
		🚧: Restarting Apache...
	"
	systemctl restart apache2
else
	echo '
		❌: Syntax check failed
		ℹ️: Run "apache2ctl -t" to see why.
	'
	exit 1
fi





#
# Firewall Configuration
#
# Whitelist the universal HTTP port
echo 'ℹ️: Space-seperated inputs required (i.e. 80 8080 4320)'
read -rp 'What port(s) does your webserver use? (Enter nothing for defaults): ' ports
for port in $ports; do
	if [[ "$port" =~ $numberCheck ]]; then
		ufw allow in "$port"/tcp && echo "✅: Exempting port ($port/tcp)"
	else
		echo "❌: Erroneous input at ($port) so exempting default web server port (80/tcp)."
		ufw allow in 80/tcp
		continue
	fi
done





#
# Exit
#
clear
exit 0
