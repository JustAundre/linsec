#
# Display Manager
#
# LightDM
if hash lightdm; then
	# Disable guest login
	reconfig -d \= allow-guest false /etc/lightdm/lightdm.conf
	#
	# Disable automatic login
	reconfig -d \= AutomaticLogin false /etc/lightdm/lightdm.conf
	#
	# Disable user enumeration
	reconfig -d \= greeter-show-manual-login true /etc/lightdm/lightdm.conf
	reconfig -d \= greeter-hide-users true /etc/lightdm/lightdm.conf
	#
	# Disable remote X server login
	reconfig -d \= xdmcp-enabled false /etc/lightdm/lightdm.conf
	#
	# Disable VNC/RDP access
	reconfig -d \= vnc-server-enabled false /etc/lightdm/lightdm.conf
fi
#
# GDM
if hash gdm; then
	# Disable automatic login
	reconfig -d \= AutomaticLoginEnable false /etc/gdm/custom.conf
fi
#
# SDDM
if hash sddm; then
	# Disable automatic login
	reconfig User '' /etc/sddm.conf
	reconfig Session '' /etc/sddm.conf
	
	# Hide the user list
	reconfig HideUsers '' /etc/sddm.conf
	reconfig DisableDebug true /etc/sddm.conf
fi