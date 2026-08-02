# Review nodes containing non-ASCII characters
mapfile -td '' has_non_ascii < <(
	find / -xephem -mindepth 1 ! -iregex '^[\x00-\x7F\n]+$' -print0 |
		tee "non-ascii-paths-${session_id}.log"
)
for node in "${has_non_ascii[@]}"; do
	pause
	select_fix "${node}"
done
#
# Review nodes leading with a hyphen
mapfile -td '' leading_hyphen < <(
	find / -xephem -mindepth 1 -name '-*' -print0 |
		tee "leading-hyphen-${session_id}.log"
)
for node in "${leading_hyphen[@]}"; do
	pause
	select_fix "${node}"
done