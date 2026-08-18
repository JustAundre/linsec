#
# login.defs
#
# Configure secure defaults fore login.defs
reconfig PASS_MAX_DAYS 90 /etc/login.defs
reconfig PASS_MIN_DAYS 7 /etc/login.defs
reconfig PASS_WARN_AGE 14 /etc/login.defs
reconfig ENCRYPT_METHOD YESCRYPT /etc/login.defs
reconfig UMASK 077 /etc/login.defs
reconfig CREATE_HOME yes /etc/login.defs
reconfig USERGROUPS_ENAB yes /etc/login.defs
