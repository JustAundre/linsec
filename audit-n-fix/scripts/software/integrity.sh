#!/usr/bin/env bash
case "${pkg_backend}" in
'apt-get')
	mapfile -t options < <(dpkg -V | awk '$1 ~ /^..5/ {print $2}' | xargs -r dpkg -S | cut -d: -f1 | sort -u)
	;;
'dnf'|'yum'|'rpm')
	mapfile -t options < <(rpm -Va | awk '{print $NF}' | xargs -r rpm -qf | sort -u)
	;;
'pacman')
	mapfile -t options < <(pacman -Qk 2>&1 | awk '/gaps in/ {print $2}')
	;;
'pkg')
	mapfile -t options < <(pkg check -sa --checksum 2>&1 | awk -F: '/checksum mismatch|missing/ {print $1}' | sort -u)
	;;
*)
	log e 'Package manager not supported.'
	exit 11
	;;
esac
if ((!${#options[@]})); then
	log i 'Passed integrity check—no further action needed.'
	exit 0
fi
mapfile -td '' selections < <(PS2='Select packages to reinstall—the listed packages have been found to deviate from base installation.' cl-new -mo "${options[@]}")
((${#selections[@]})) && case "${pkg_backend}" in
'apt-get')
	xargs -r apt-get install --reinstall -y <<<"${selections[@]}"
	;;
'dnf'|'yum')
	xargs -r "${pkg_backend}" reinstall -y <<<"${selections[@]}"
	;;
'pacman')
	xargs -r pacman -S --noconfirm <<<"${selections[@]}"
	;;
'pkg')
	xargs -r pkg install -fy <<<"${selections[@]}"
	;;
*)
	log e 'Package manager not supported.'
	exit 11
	;;
esac
