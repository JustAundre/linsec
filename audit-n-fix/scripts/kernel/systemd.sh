#!/usr/bin/env bash





#
# SystemD Configuration
#
# Disable core dumping
reconfig -x 'replace' -d '=' Storage none /etc/systemd/coredump.conf
reconfig -x 'replace' -d '=' ProcessSizeMax 0 /etc/systemd/coredump.conf
