#!/usr/bin/env bash





#
# Environment Setup
#
# Menu text slug
declare -A slug=(
	['Enforce password quality']='pwquality'
	['Enforce minimum password length']='minlen'
	['Fail locking']='faillock'
	['Reject passwordless logins']='nonullok'
	['Setup AuditD TTY logging']='audit_tty'
)
#
# Per-distro PAM options' slugs
declare -A flag=(
	[fedora:pwquality]='with-pwquality'
	[debian:pwquality]='with-pwquality'
	[fedora:faillock]='with-faillock'
	[debian:faillock]='with-faillock'
	[fedora:nonullok]='without-nullok'
	[debian:audit_tty]='audit_tty'
)
#
# Per-distro custom PAM configurations' slugs
declare -A files=(
	[fedora:pwquality]='pwquality.conf:/etc/security/pwquality.conf'
	[debian:pwquality]='pwquality:/usr/share/pam-configs/pwquality pwquality.conf:/etc/security/pwquality.conf'
	[debian:faillock]='faillock:/usr/share/pam-configs/faillock faillock_reset:/usr/share/pam-configs/faillock_reset faillock_notify:/usr/share/pam-configs/faillock_notify'
	[debian:audit_tty]='audit_tty:/usr/share/pam-configs/audit_tty'
	[freebsd:pwquality]='pwquality.conf:/usr/local/etc/security/pwquality.conf'
)
#
# Query user for configuration options
mapfile -t -d '' selections < <(PS2='Select patches to apply.' cl-new -m -o "${!slug[@]}")
#
# Resolve the distro family once
case "${os_info['ID']} ${os_info['ID_LIKE']}" in
*fedora*)          family='fedora'  ;;
*debian*|*ubuntu*) family='debian'  ;;
*freebsd*)         family='freebsd' ;;
*)
	log e 'unsupported operating system'
	exit 11
	;;
esac





#
# PAM Modules Installation
#
log i '(Re)installing PAM modules...'
case "${pkg_backend}" in
'apt-get')
	"${pkg_backend}" install --reinstall -y -o Dpkg::Options::='--force-confmiss'\
		sssd libpam-pwquality libpam-runtime libpam-modules\
;;
'dnf'|'yum')
	"${pkg_backend}" reinstall -y\
		sssd libpwquality
;;
'pacman')
	"${pkg_backend}" -S --noconfirm\
		sssd libpwquality
;;
'pkg')
	"${pkg_backend}" install -f\
		sssd libpwquality
;;
esac
#
# Distro-agonostic PAM configurations
args=()
fedora_audit_tty=0
for selection in "${selections[@]}"; do
	key="${family}:${slug[${selection}]}"
	[[ -n ${flag[${key}]} ]] && args+=("${flag[${key}]}")
	for pair in ${files[${key}]}; do
		install -m 640 -o 0 -g 0 -D -v "cnf/auth/${pair%%:*}" "${pair#*:}"
	done
	case "${key}" in
	debian:minlen)
		if grep -q -E 'pam_unix\.so.+minlen=' /usr/share/pam-configs/unix; then
			log w 'A minimum password length is already being enforced.'
			confirm 'Continue anyway' || continue
		fi
		echo 'Enter a minimum password length (default 14):'
		response=''
		while [[ ! ${response} =~ ^[0-9]+$ ]]; do
			read -e -r -p '> ' response
			[[ -z ${response} ]] && response=14
			[[ ! ${response} =~ ^[0-9]+$ ]] && log e 'Please enter a valid positive integer.'
		done
		sed -i "\\${sed_delim}pam_unix\.so${sed_delim}s${sed_delim}\$${sed_delim}	minlen=${response}${sed_delim}" /usr/share/pam-configs/unix &&
			log i "Minimum password length set to ${response}."
		;;
	debian:remember)
		if grep -q -E 'pam_unix\.so.+remember=' /usr/share/pam-configs/unix; then
			log w 'A minimum password length is already being enforced.'
			confirm 'Continue anyway' || continue
		fi
		echo 'Enter a minimum password length (default 14):'
		response=''
		while [[ ! ${response} =~ ^[0-9]+$ ]]; do
			read -e -r -p '> ' response
			[[ -z ${response} ]] && response=14
			[[ ! ${response} =~ ^[0-9]+$ ]] && log e 'Please enter a valid positive integer.'
		done
		sed -i "\\${sed_delim}pam_unix\.so${sed_delim}s${sed_delim}\$${sed_delim}	remember=${response}${sed_delim}" /usr/share/pam-configs/unix &&
			log i "Minimum password length set to ${response}."
		;;
	debian:nonullok)
		if ! grep -q nullok /usr/share/pam-configs/unix; then
			log i 'Logins for passwordless users are already rejected.'
			continue
		fi
		sed -i "s${sed_delim}\s*nullok${sed_delim}${sed_delim}g" /usr/share/pam-configs/unix &&
			log i 'Logins for passwordless users are now rejected.'
		;;
	debian:audit_tty|fedora:audit_tty)
		log i 'Installing auditd...'
		case "${pkg_backend}" in
		'apt-get')   "${pkg_backend}" install -y auditd ;;
		'dnf'|'yum') "${pkg_backend}" install -y audit ;;
		esac
		if [[ ${init} == 'systemd' ]]; then
			systemctl enable --now auditd &&
				log i 'auditd enabled.'
		fi
		[[ ${family} == 'fedora' ]] && fedora_audit_tty=1
		;;
	*:audit_tty)
		log w 'TTY audit logging (pam_tty_audit) support from this script is only available for Fedora and Debian-based distributions.'
		;;
	esac
done
#
# Per-distro finalization
case "${family}" in
fedora)
	if hash sudo 2>/dev/null; then
		args+=('with-sudo')
		log i 'Detected sudo, enabling sudo PAM module.'
	fi
	authselect select sssd with-pamaccess with-pwhistory with-mkhomedir "${args[@]}" --force
	authselect apply-changes
	#
	# Must run after authselect, otherwise it would overwrite this change
	if ((fedora_audit_tty)) && ! grep -q 'pam_tty_audit' /etc/pam.d/postlogin; then
		if echo 'session	optional	pam_tty_audit.so enable=*' >>/etc/pam.d/postlogin; then
			log i 'TTY audit logging enabled via postlogin.'
			log w 'TTY audit will not persist authselect changes. You must re-enable it after each authselect change.'
		fi
	fi
	;;
debian)
	# Update PAM configurations
	if [[ ${init} == 'systemd' ]]; then
		args+=('systemd')
		"${pkg_backend}" install --reinstall libpam-systemd -y -o Dpkg::Options::='--force-confmiss'
	fi
	if hash sudo &>/dev/null; then
		args+=('sudo')
		log i 'Detected sudo, enabling sudo PAM module.'
	fi
	if hash gnome-keyring &>/dev/null; then
		args+=('gnome-keyring')
		log i 'Detected gnome-keyring, enabling PAM module.'
	fi
	((${#selections[@]})) && DEBIAN_FRONTEND=noninteractive pam-auth-update --force --package --enable unix limits mkhomedir sss umask "${args[@]}"
	;;
freebsd)
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
