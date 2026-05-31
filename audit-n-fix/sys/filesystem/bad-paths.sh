log i 'Scanning for filepaths allowed by the Linux kernel but which may cause unexpected behavior...'
log i 'The recommended method of viewing generated log files is using the "less -R" command or "cat -A".'
#
# Review non-ascii paths
mapfile -td '' naps < <(
	xfind / -mindepth 1 ! -iregex '^[\x00-\x7F\n]+$' -xdev -print0 \
		-exec pause + \
		-exec select_fix {} \; |
			tee "non-ascii-paths-${session_id}.log"
)
#
# Review hyphen-initiated paths
mapfile -td '' hips < <(
	xfind / -mindepth 1 -name '-*' -xdev -print0 \
		-exec log w 'There are paths on your system which begin with 1 or more hyphens.' + \
		-exec pause + \
		-exec select_fix {} \; |
			tee "hyphen-initiated-paths-${session_id}.log"
)