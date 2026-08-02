#
# Attribute Manager
#
# Act based on selected mode
# TODO: FIX WHITESAPCE SAFETY
options=(
	remove
	restore
)
if [[ "$(checklist -t 'Remove/restore immutable and append-only attributes' "${options[@]}")" == remove ]]; then
	# Alert the user of the possible lengthy scan
	log i $'This will take a second; if you ask, no the script didn\'t hang.'
	#
	# Removes the (i)mmutable & (a)ppend-only attributes from all files
	find / -xephem -type f -exec lsattr -d {} + 2>/dev/null | while read -r attrs file; do
		if [[ "${attrs}" == *i* ]]; then
			echo "${file}" >>immutable-files.txt
			log i "Found immutable file: ${file}"
		fi
		if [[ "${attrs}" == *a* ]]; then
			echo "${file}" >>append-only-files.txt
			log i "Found append-only file: ${file}"
		fi
	done
	[[ -s immutable-files.txt ]] && xargs chattr -- -i <immutable-files.txt
	[[ -s append-only-files.txt ]] && xargs chattr -- -a <append-only-files.txt
else
	[[ -s append-only-files.txt ]] && while IFS= read -r path; do
		if [[ -f "${path}" ]]; then
			chattr +a "${path}"
			log i "Restored append-only to \"${path}\"."
		else
			log w "\"${path}\" previously had an attribute but no longer exists and so cannot have append-only restored."
		fi
	done <append-only-files.txt
	[[ -s immutable-files.txt ]] && while IFS= read -r path; do
		if [[ -f "${path}" ]]; then
			chattr +i "${path}"
			log i "Restored immutability to \"${path}\"."
		else
			log w "\"${path}\" previously had an attribute but no longer exists and so cannot have immutability restored."
		fi
	done <immutable-files.txt
fi
