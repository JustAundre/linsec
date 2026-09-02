#!/usr/bin/env bash





#
# login.defs
#
# Configure secure defaults fore login.defs
reconfig -x 'replace' PASS_MAX_DAYS 90 /etc/login.defs
reconfig -x 'replace' PASS_MIN_DAYS 7 /etc/login.defs
reconfig -x 'replace' PASS_WARN_AGE 14 /etc/login.defs
reconfig -x 'replace' ENCRYPT_METHOD YESCRYPT /etc/login.defs
reconfig -x 'replace' UMASK 077 /etc/login.defs
reconfig -x 'replace' CREATE_HOME yes /etc/login.defs
reconfig -x 'replace' USERGROUPS_ENAB yes /etc/login.defs
