#!/usr/bin/env bash





#
# SystemD .timers & .paths
#
if [[ ${init} != 'systemd' ]]; then
	log e 'Initialization system is not SystemD, therefore are no SystemD timers or paths to audit.'
	exit 11
fi
while IFS='' read -r -u "${trigger_fd}" trigger; do
	log i "Reviewing trigger: ${trigger@Q}"
	pause 0
	"${EDITOR}" -- "${trigger}" &&
		confirm "Delete ${trigger@Q}" &&
		systemctl disable --now -- "${trigger}" &&
		rm -v -- "${trigger}"
done {trigger_fd}< <(
	systemctl show -p FragmentPath --value '*.timer' '*.path' | grep .
)
exec {trigger_fd}<&-
systemctl daemon-reload
