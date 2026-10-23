#!/usr/bin/env bash





#
# Install MOTDs
#
# MOTD locations
motds=(
	/etc/issue
	/etc/issue.net
	/etc/motd
)
#
# Install the original to the first path specified, hardlink all others to original.
"${EDITOR}" -- cnf/motd
install -m 644 -o 0 -g 0 -Dv cnf/motd "${motds[0]}"
#
# Hardlink to other likely MOTD file locations
for path in "${motds[@]:1}"; do
	link -- "${motds[0]}" "${path}"
done





#
# Delete Unecessary MOTDs
#
rm -rfv /etc/update-motd.d/
