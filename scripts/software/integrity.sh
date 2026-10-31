#!/usr/bin/env bash
case "${pkg_backend}" in
'apt-get')
	mapfile -t options < <(dpkg -V | awk '$1 ~ /^..5/ {print $2}' | xargs -r dpkg -S | cut -d : -f 1 | sort -u)
	;;
'dnf'|'yum')
	mapfile -t options < <(rpm -V -a | awk '{print $NF}' | xargs -r rpm -q -f | sort -u)
	;;
'pacman')
	mapfile -t options < <(pacman -Q -k 2>&1 | awk '/gaps in/ {print $2}')
	;;
'pkg')
	mapfile -t options < <(pkg check -s -a --checksum 2>&1 | awk -F : '/checksum mismatch|missing/ {print $1}' | sort -u)
	;;
esac
if ((!${#options[@]})); then
	log i 'Passed integrity check—no further action needed.'
	exit 0
fi
mapfile -t -d '' selections < <(PS2='Select packages to reinstall—the listed packages have been found to deviate from base installation.' cl-new -m -o "${options[@]}")
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
	xargs -r pkg install -f -y <<<"${selections[@]}"
	;;
esac
