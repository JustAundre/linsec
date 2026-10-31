#!/usr/bin/env bash





#
# PAM Configuration
#
mapfile -t -d '' selections < <(PS2='Select patches to apply.' cl-new -m -o 'Enforce password quality' 'Enforce minimum password length' 'Fail locking' 'Reject passwordless logins')
case "${os_info['ID']} ${os_info['ID_LIKE']}" in
*fedora*)
	for selection in "${selections[@]}"; do
		case "${selection}" in
		'Enforce password quality')
			args+=('with-pwquality')
			install -m 640 -o 0 -g 0 -D -v cnf/auth/pwquality.conf /etc/security/pwquality.conf
			;;
		'Fail locking')
			args+=('with-faillock')
			;;
		'Reject passwordless logins')
			args+=('without-nullok')
			;;
		*)
			log e "unknown selection ${response@Q}."
			;;
		esac
	done
	authselect select sssd with-pamaccess with-pwhistory with-mkhomedir with-sudo "${args[@]}" --force
	authselect apply-changes
	;;
*debian*|*ubuntu*)
	for selection in "${selections[@]}"; do
		case "${selection}" in
		'Enforce password quality')
			case "${pkg_backend}" in
			'apt-get') "${pkg_backend}" install --reinstall libpam-pwquality -y -o Dpkg::Options::='--force-confmiss' ;;
			'dnf') "${pkg_backend}" reinstall libpam-pwquality -y ;;
			'yum') "${pkg_backend}" reinstall libpam-pwquality -y ;;
			'pacman') "${pkg_backend}" -S libpam-pwquality --noconfirm ;;
			'pkg') "${pkg_backend}" install -f libpam-pwquality ;;
			esac
			install -m 640 -o 0 -g 0 -D -v cnf/auth/pwquality /usr/share/pam-configs/pwquality
			install -m 640 -o 0 -g 0 -D -v cnf/auth/pwquality.conf /etc/security/pwquality.conf
			;;
		'Enforce minimum password length')
			if grep -q -E 'pam_unix\.so.+minlen=' /etc/pam.d/common-password; then
				log w 'A minimum password length is already being enforced.'
				confirm 'Continue anyway' || continue
			fi
			echo 'Enter a minimum password length:'
			until [[ ${response} =~ ^[0-9]+$ ]]; do
				read -e -r -p '> ' response
			done
			sed -i "\\${sed_delim}pam_unix\.so${sed_delim}s${sed_delim}[[:space:]]+minlen=[[:digit:]]+${sed_delim}	minlen=${response}${sed_delim}" /etc/pam.d/common-password
			sed -i "\\${sed_delim}pam_unix\.so${sed_delim}s${sed_delim}\$${sed_delim}	minlen=${response}${sed_delim}" /etc/pam.d/common-password
			;;
		'Fail locking')
			install -m 640 -o 0 -g 0 -D -v cnf/auth/faillock /usr/share/pam-configs/faillock
			install -m 640 -o 0 -g 0 -D -v cnf/auth/faillock_reset /usr/share/pam-configs/faillock_reset
			install -m 640 -o 0 -g 0 -D -v cnf/auth/faillock_notify /usr/share/pam-configs/faillock_notify
			log i 'Enabled faillock.'
			;;
		'Reject passwordless logins')
			if ! grep -q nullok /usr/share/pam-configs/unix; then
				log i 'Logins for passwordless users are already rejected.'
				continue
			fi
			sed -i "s${sed_delim}\s*nullok${sed_delim}${sed_delim}g" /usr/share/pam-configs/unix &&
				log i 'Logins for passwordless users are now rejected.'
			;;
		*)
			log e "unknown selection ${response@Q}."
			;;
		esac
	done
	#
	# Update PAM configurations
	((${#selections[@]})) && pam-auth-update --force --package
	;;
*freebsd*)
	# TODO: TESTING NEEDED
	# Download base image for FreeBSD system
	trap '[[ -f base.txz ]] && rm -v base.txz' EXIT
	base_sys_url="https://download.freebsd.org/releases/$(uname -m)/$(freebsd-version | cut -d '-' -f 1,2)/base.txz"
	log i "Fetching base system image from ${base_sys_url@Q}..."
	fetch -o base.txz -a -s -r "${base_sys_url}" 2>&1 1>&2 | log e || exit 12
	#
	# Backup existing /etc/pam.d directory and extract base.
	mv /etc/pam.d{,'.bak'}
	tar -x -f base.txz -C /etc/pam.d/ etc/pam.d
	#
	# Audit PAM configuration overrides
	mapfile -t -d '' paths < <(find /usr/local/etc/pam.d/ -type f -print0)
	for path in "${paths[@]}"; do
		# TODO: Automatically reinstall
		pkg which -q -- "${path}"
		if ((${?} == 1)); then
			log w "Unidentified PAM configuration override found: ${path@Q}"
			printf '%s\0' "${path}" >>"${log_dir}/unidentified-pam-overrides.txt"
		fi
	done
	#
	# Enable password quality checks
	pkg install -f pam_pwquality
	install -m 640 -o 0 -g 0 -D -v cnf/auth/pwquality.conf /usr/local/etc/security/pwquality.conf
	;;
*)
	log e 'unsupported operating system'
	exit 11
	;;
esac





#
# Password Expiries
#
PASS_MAX_DAYS=31
PASS_MIN_DAYS=1
PASS_WARN_AGE=27
reconfig -x replace PASS_MIN_DAYS "${PASS_MIN_DAYS}" /etc/login.defs
reconfig -x replace PASS_MAX_DAYS "${PASS_MAX_DAYS}" /etc/login.defs
reconfig -x replace PASS_WARN_AGE "${PASS_WARN_AGE}" /etc/login.defs
for entry in "${passwd[@]}"; do
	IFS=':' read -r -d $'\n' user _ _ _ _ _ shell <<<"${entry}"
	[[ ${shell} =~ /('nologin'|'false')$ || ${user} == "$(logname)" ]] && continue
	timestamp="$(date +%Y-%m-%d)"
	chage -m "${PASS_MIN_DAYS}" -M "${PASS_MAX_DAYS}" -W "${PASS_WARN_AGE}" "${user}" &&
		log i "${user@Q}'s password min/max/warn timings set to ${PASS_MIN_DAYS}/${PASS_MAX_DAYS}/${PASS_WARN_AGE} (in days)."
	chage -d "${timestamp}" "${user}" &&
		log i "${user@Q}'s last password change date set to ${timestamp@Q}."
done
