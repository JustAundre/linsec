#!/usr/bin/env -iS /usr/bin/bash --noprofile --norc
# shellcheck shell=bash
#
# Run the SQL Configuration Script
#
# The actual "script" is not here, this is just a wrapper for it.
# MySQL, MariaDB and others alike have their own "shell" to run their own configuration commands in.
# Please see general-confs/mysql-database.sql and general-confs/postgres-database.sql for the actual
# scripts used to configure your SQL database.
#





#
# Environment Setup
#
# Source secure environment
. .allrc





#
# Script Redirect
#
case $(checklist "Which type of database are we patching?" "radiolist" "MySQL" "MariaDB" "PostgreSQL") in
	MySQL)
		mysql_secure_installation
		mysql -u root < general-confs/mysql-database.sql
	;;
	MariaDB)
		mysql_secure_installation
		mariadb -u root -p < general-confs/mysql-database.sql
	;;
	PostgreSQL)
		# Postgre has no default password to crack, listens locally by default, etc; and has no securing script.
		sudo -u postgres psql < general-confs/postgres-database.sql
	;;
esac
