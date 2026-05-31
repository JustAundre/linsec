#
# Software Updates
#
# Run updates for all major package distrobuters.
if hash apt-get; then apt-get update && apt-get full-upgrade --no-install-recommends -y
elif hash pacman; then pacman -Syuu
elif hash dnf; then dnf upgrade --refresh
fi
hash flatpak && flatpak update -y
hash snap && snap refresh