#
# Non-ASCII characters in Node Names
#
mapfile -td '' has_non_ascii < <(
	find / -mindepth 1 ! -iregex '^[\x00-\x7F\n]+$' -xephem -print0 |
		tee "non-ascii-paths-${session_id}.log"
)
if [[ "${#has_non_ascii[@]}" -ge 1 ]]; then
	log i 'Be prepared to review nodes which contain non-ASCII characters in their names.'
	pause
fi
for node in "${has_non_ascii[@]}"; do
	select_fix "${node}"
done





#
# Node Names Leading With A Hyphen
#
mapfile -td '' leading_hyphen < <(
	find / -mindepth 1 -name '-*' -xephem -print0 |
		tee "leading-hyphen-${session_id}.log"
)
if [[ "${#leading_hyphen[@]}" -ge 1 ]]; then
	log i 'Be prepared to review nodes whose name leads with a hyphen.'
	pause
fi
for node in "${leading_hyphen[@]}"; do
	select_fix "${node}"
done