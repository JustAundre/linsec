#!/usr/bin/env bash





#
# Display Manager
#
# LightDM
if hash lightdm; then
	# Disable guest login, auto login, user enumeration, remote X server login, and VNC/RDP access.
	reconfig -x 'replace' -d '=' allow-guest false /etc/lightdm/lightdm.conf
	reconfig -x 'replace' -d '=' AutomaticLogin false /etc/lightdm/lightdm.conf
	reconfig -x 'replace' -d '=' greeter-show-manual-login true /etc/lightdm/lightdm.conf
	reconfig -x 'replace' -d '=' greeter-hide-users true /etc/lightdm/lightdm.conf
	reconfig -x 'replace' -d '=' xdmcp-enabled false /etc/lightdm/lightdm.conf
	reconfig -x 'replace' -d '=' vnc-server-enabled false /etc/lightdm/lightdm.conf
fi
#
# GDM
if hash gdm; then
	# Disable automatic login
	reconfig -x 'replace' -d '=' AutomaticLoginEnable false /etc/gdm/custom.conf
fi
#
# SDDM
if hash sddm; then
	# Disable automatic login and user enumeration
	reconfig -x 'replace' User '' /etc/sddm.conf
	reconfig -x 'replace' Session '' /etc/sddm.conf
	reconfig -x 'replace' HideUsers '' /etc/sddm.conf
	reconfig -x 'replace' DisableDebug true /etc/sddm.conf
fi
