#!/usr/bin/env bash





#
# SystemD Baselining
#
case "${init}" in
'systemd')
	while IFS='' read -r -d '' path; do
		# Symlinks
		if [[ -h "${path}" ]]; then
			resolved_path="$(readlink -- "${path}")"
			case "${resolved_path}" in
			/lib/systemd/system/*|/usr/lib/systemd/system/*)
				vendor_svcs+=("${path}")
				log i "Vendor service: ${path@Q}"
				;;
			/dev/null)
				masked_svcs+=("${path}")
				log i "Masked service: ${path@Q}"
				;;
			*)
				custom_symlinked_svcs+=("${path}")
				log w "Custom (and symlinked) service: ${path@Q}"
				;;
			esac
		#
		# Directories
		elif [[ -d "${path}" ]]; then
			case "${path}" in
			*.d)
				overrides_dirs+=("${path}")
				log w "Service configuration overrides directory: ${path@Q}"
				;;
			*.wants)
				depends_dirs+=("${path}")
				log i "Service dependencies directory: ${path@Q}"
				;;
			*)
				unknown_dirs+=("${path}")
				log w "Unidentified directory: ${path@Q}"
				;;
			esac
		#
		# Normal files
		elif [[ -f "${path}" ]]; then
			custom_svcs+=("${path@Q}")
			log w "Custom service: ${path@Q}"
		fi
	done < <(find /etc/systemd/system -maxdepth 1 -mindepth 1 -print0)
	printf '%s\0' "${masked_svcs[@]}" > "${log_dir}/masked-services.txt"
	printf '%s\0' "${custom_symlinked_svcs[@]}" > "${log_dir}/custom-services-(symlinked).txt"
	printf '%s\0' "${overrides_dirs[@]}" > "${log_dir}/service-overrides-dirs.txt"
	printf '%s\0' "${depends_dirs[@]}" > "${log_dir}/service-dependencies-dirs.txt"
	printf '%s\0' "${unknown_dirs[@]}" > "${log_dir}/service-unknown-dirs.txt"
	printf '%s\0' "${custom_svcs[@]}" > "${log_dir}/custom-services.txt"
	;;
'init')
	# TODO: Needs improvement
	case "${pkg_backend}" in
	'pkg')
		pkg which /etc/rc.d/* | grep -v "not found" | log i
		pkg which /etc/rc.d/* | grep "not found" | log w
		;;
	'dnf'|'yum')
		for path in /etc/rc.d/init.d/*; do
			rpm -q -f "${path}" 2>(log w) | log i
		done
		;;
	esac
	;;
esac
