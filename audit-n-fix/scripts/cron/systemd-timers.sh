#!/usr/bin/env bash





#
# SystemD .timers & .paths
#
# Map out the .timers/.paths
mapfile -t triggers < <(
	systemctl list-units --all --plain --no-legend |
		awk '{ print $1 }' |
		xargs systemctl show -p FragmentPath --value -- |
		grep -E '\.(timer|path)$'
)
#
# Audit them & act accordingly.
for trigger in "${triggers[@]}"; do
	log i "Reviewing trigger: \"${trigger}\"."
	pause 3
	"${EDITOR}" -- "${trigger}" &&
		confirm "Delete \"${trigger}\"" &&
		systemctl disable --now -- "${trigger}" &&
		rm -v -- "${trigger}"
done
#
# Pushes changes into SystemD
systemctl daemon-reload
