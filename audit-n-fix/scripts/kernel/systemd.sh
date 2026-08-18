#
# SystemD Configuration
#
# Disable core dumping
reconfig -d'=' Storage none /etc/systemd/coredump.conf
reconfig -d'=' ProcessSizeMax 0 /etc/systemd/coredump.conf
