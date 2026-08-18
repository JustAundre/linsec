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
# Install the original to the first path specified.
# (Most common MOTD location)
log i <<-EOF
	You'll be put into a text editor to review a MOTD file template."
	    Revise it as needed, then it'll be installed to the following files:
	    ${motds[*]}
EOF
pause
install -m 640 -o 0 -g 0 -D cnf/motd/motd "${motds[0]}"
#
# Hardlink to other likely MOTD file locations
for path in "${motds[@]:1}"; do
	link "${motds[0]}" "${path}"
done
#
# Delete /etc/update-motd.d/?
[[ -d /etc/update-motd.d/ ]] && {
	log i <<-EOF
		Files in "/etc/update-motd.d/" may leak information; here's all the files found in the directory:
		$(find /etc/update-motd.d/ -print0 | xargs -0n1 printf '    %s\n')
	EOF
	confirm 'Delete /etc/update-motd.d/ and its contents' && rm -rfv /etc/update-motd.d/
}