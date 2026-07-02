#
# login.defs
#
# Configure secure defaults fore login.defs
(
	declare -x target_file=/etc/login.defs
	reconfig PASS_MAX_DAYS 90
	reconfig PASS_MIN_DAYS 7
	reconfig PASS_WARN_AGE 14
	reconfig ENCRYPT_METHOD YESCRYPT
	reconfig UMASK 077
	reconfig CREATE_HOME yes
	reconfig USERGROUPS_ENAB yes
)