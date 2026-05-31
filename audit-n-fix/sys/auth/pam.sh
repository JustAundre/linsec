#
# PAM Configuration
#
# RHEL-like distros
if
	hash authselect && [[
		-d /etc/authselect/ &&
		-d /usr/share/authselect/default/
	]];
then
	# Configure PAM /w secure defaults enabled & further configure password QA
	authselect select sssd with-faillock with-pamaccess with-pwhistory with-pwquality with-mkhomedir with-sudo without-nullok --force
	install -m 640 -o 0 -g 0 -D cnf/auth/pwquality.conf /etc/security/pwquality.conf
	#
	# Regenerate PAM configurations /w previous configuration
	authselect apply-changes
#
# Debian-like distros
elif
	hash pam-auth-update &&
	[[ -d /usr/share/pam-configs/ ]]
then
	# Insert password QA configuration
	install -m 640 -o 0 -g 0 -D cnf/auth/pwquality /usr/share/pam-configs/pwquality
	install -m 640 -o 0 -g 0 -D cnf/auth/pwquality.conf /etc/security/pwquality.conf
	#
	# Insert faillock configuration
	install -m 640 -o 0 -g 0 -D cnf/auth/faillock /usr/share/pam-configs/faillock
	install -m 640 -o 0 -g 0 -D cnf/auth/faillock_reset /usr/share/pam-configs/faillock_reset
	install -m 640 -o 0 -g 0 -D cnf/auth/faillock_notify /usr/share/pam-configs/faillock_notify
	#
	# Reject logins for users with no password
	sed -i 's/\s*nullok//g' /usr/share/pam-configs/unix
	#
	# Update PAM configurations
	pam-auth-update --force --package
else
	log e 'Your PAM configuration setup is unsupported.'
fi
#
# Enforce password age policies (to users w/ UID 1000=<)
mapfile -t nonsys_users < <(awk -F: '$3 >= 1000 { print $1 }' /etc/passwd)
for u in "${nonsys_users[@]}"; do
	# Skips the iterated user if they're the user running the script
	# Apply the password age restrictions to the user
	# Sets the date they last changed their password to current date to avoid accidental lockouts
	[[ "${u}" != "${SUDO_USER}" ]] &&
		chage -m 7 -M 90 -W 14 "${u}" &&
		chage -d "$(date +%Y-%m-%d)" "${u}"
done