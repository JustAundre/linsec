#
# Password & Shadow Files
#
# Check for discrepencies between /etc/passwd and /etc/group.
pwck
#
# Migrate stray hashes from passwd to shadow & from group to gshadow
# The pwconv/grpconv don't say anything helpful if there's nothing wrong or if they changed something...
# ...so I had to make my own verbose output.
# (subshell to easily reset the IFS, and for variable isolation)
(
[[ -f /etc/shadow ]] && shadow_old="$(</etc/shadow)"
[[ -f /etc/gshadow ]] && gshadow_old="$(</etc/gshadow)"
pwconv
grpconv
#
# Check for differences between the old and new shadow file
# Hint: diff returns an exit code of 1 when changes are found and 2 when there's an issue, and...
# ...0 when there was no changes made, which makes things much easier here.
if [[ -z "${shadow_old}" ]]; then log i 'No shadow file prior to pwconv so no discrepencies to note.'
elif diff -u <(echo "${shadow_old}") /etc/shadow; then log i 'Nothing changed between the old /etc/shadow file.'
fi
#
# Check for differences between the old and new gshadow file
if [[ -z "${gshadow_old}" ]]; then log i 'No gshadow file prior to grpconv so no discrepencies to note.'
elif diff -u <(echo "${gshadow_old}") /etc/gshadow; then log i 'Nothing changed between the old /etc/gshadow file.'
fi
)