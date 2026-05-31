#
# SystemD .timers & .paths
#
# Map out the .timers/.paths
mapfile -t triggers < <(
	systemctl list-units --all --plain --no-legend |
		awk '{print $1}' |
		xargs systemctl show -p FragmentPath --value -- |
		xargs grep -E '\.(timer|path)$'
)
#
# Audit them & act accordingly.
for trigger in "${triggers[@]}"; do
	"${EDITOR}" "${trigger}" &&
		confirm "Delete ${trigger}" &&
		systemctl disable --now "${trigger}" &&
		rm -v "${trigger}"
done
#
# Pushes changes into SystemD
systemctl daemon-reload