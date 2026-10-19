# Manual Tasks

## Verifying Integrity

### Manual check

```bash
# Debian
dpkg -V

# RHEL (both modern & legacy)
rpm -Va

# Arch
pacman -Qk

# FreeBSD
pkg check -sa
```

### Automatic reinstall

```bash
# Debian
dpkg -V | awk '$1 ~ /^..5/ {print $2}' | xargs -r dpkg -S | cut -d: -f1 | sort -u | sudo xargs -r apt-get install --reinstall -y -o Dpkg::Options::='--force-confnew' -o Dpkg::Options::='--force-confmiss'

# RHEL (both modern & legacy)
rpm -Va --nofiles | awk '{print $NF}' | xargs -r rpm -qf | sort -u | sudo xargs -r dnf reinstall -y

# Arch
pacman -Qk 2>&1 | awk '/gaps in/ {print $2}' | sudo xargs -r pacman -S --noconfirm

# FreeBSD
pkg check -sa --checksum 2>&1 | awk -F: '/checksum mismatch|missing/ {print $1}' | sort -u | sudo xargs -r pkg install -fy
```

## Forensic & Audit Tooling

These tools **report** problems; they don't fix them. Review findings before acting on them,
since `rkhunter`, `chkrootkit`, and `lynis` in particular produce false positives.
Anything that builds a baseline (AIDE, `rkhunter --propupd`) should only be run on a system you trust is clean.

### Installing

```bash
# Debian
sudo apt-get install debsecan debsums lynis rkhunter chkrootkit clamav aide needrestart

# RHEL (most of these live in EPEL: sudo dnf install epel-release)
sudo dnf install lynis rkhunter chkrootkit clamav clamav-update aide openscap-scanner scap-security-guide

# Arch (a few of these may be AUR-only)
sudo pacman -S arch-audit lynis rkhunter clamav

# FreeBSD
sudo pkg install lynis rkhunter chkrootkit clamav
```

### Known-Vulnerable Packages

Compares installed packages against the distribution's security data. Requires network access.

```bash
# Debian (debsecan uses Debian's security tracker; it isn't meaningful on Ubuntu)
debsecan --suite "$(. /etc/os-release && echo "${VERSION_CODENAME}")" --only-fixed --format detail

# Ubuntu
pro security-status

# RHEL (modern)
sudo dnf updateinfo list security
sudo dnf updateinfo info --security
sudo dnf upgrade --security

# RHEL (legacy; RHEL 6 needs yum-plugin-security)
sudo yum --security check-update
sudo yum --security update

# Arch (-u shows only vulnerabilities that already have a fix available)
arch-audit -u

# FreeBSD (-F fetches the latest vulnerability database first)
sudo pkg audit -F
# Compare the base system against the official release
sudo freebsd-update IDS
```

### Processes Running Outdated Libraries

After updating, some services still run the old, vulnerable code until they're restarted.

```bash
# Debian
sudo needrestart -r l

# RHEL
sudo dnf needs-restarting
sudo dnf needs-restarting -r
```

### Hardening & Compliance Auditors

Lynis works on all the supported platforms and prints a prioritized list of suggestions.
OpenSCAP scores the system against a benchmark profile such as CIS or STIG.

```bash
# Lynis: the report lands in /var/log/lynis-report.dat
sudo lynis audit system
sudo grep -E '^(warning|suggestion)\[\]' /var/log/lynis-report.dat

# OpenSCAP: the available datastreams vary by distribution
ls /usr/share/xml/scap/ssg/content/
sudo oscap info /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml   # lists profiles
sudo oscap xccdf eval \
	--profile xccdf_org.ssgproject.content_profile_cis \
	--results results.xml --report report.html \
	/usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml
```

### Rootkits & Malware

Rootkit scanners are noisy; research each warning before trusting or dismissing it.
Scanning `/` with ClamAV is slow, so narrow the targets if you can.

```bash
# rkhunter (only run --propupd on a known-clean system)
sudo rkhunter --update
sudo rkhunter --propupd
sudo rkhunter --check --sk --rwo

# chkrootkit
sudo chkrootkit -q

# ClamAV
sudo freshclam
sudo clamscan -ri --log=clamscan.log --exclude-dir='^/sys' --exclude-dir='^/proc' --exclude-dir='^/dev' /
```

### File Integrity Monitoring (AIDE)

Take the baseline *after* you've finished hardening, then check against it later to spot changes.

```bash
# Debian
sudo aideinit
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
sudo aide --config /etc/aide/aide.conf --check

# RHEL
sudo aide --init
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
sudo aide --check
```

### Package File Integrity

Complements the [integrity checks](#verifying-integrity) above.

```bash
# Debian: list files that differ from their package's checksums
sudo debsums -c
```

### Live System Triage

Built-in tools for a quick look at what's running and who has been logging in.

```bash
# Listening sockets and the processes that own them
sudo ss -tulpn

# Files that were deleted from disk but are still held open (a common malware tell)
sudo lsof +L1

# Processes running from deleted or temporary locations
sudo ls -l /proc/[0-9]*/exe 2>/dev/null | grep -E '\(deleted\)|/(tmp|dev/shm|var/tmp)/'

# Process tree
ps auxf

# Login history: successful, failed, and per-account
last -aiF
sudo lastb -aiF
lastlog | grep -v 'Never logged in'
who -a

# FreeBSD equivalent of ss
sockstat -l
```

### Reviewing Audit Logs

Requires `auditd` with the rules from `cnf/auditd/audit.rules` loaded; the keys below match that file.

```bash
sudo aureport --summary
sudo aureport --auth --failed
sudo aureport -x --summary
sudo ausearch -k execution_monitor -ts today -i
sudo ausearch -k file_mods -ts recent -i
```

## Finding Files

Fast, but relies on file extensions:

```sh
# Finding png files, change file extension as needed
sudo find /home -type f -name '*.png'
```

Comprehensive, but slow:

```bash
# Finding images, change type as needed
sudo find /home -type f -exec file --mime-type {} + | grep 'image/'
```

## Updates

### Debian

```sh
sudo apt-get update
sudo apt-get full-upgrade
sudo apt-get dist-upgrade
```

### RHEL

```sh
# Modern RHEL (8 and above)
sudo dnf update

# Legacy RHEL (7 and below)
sudo yum update
```

### Arch

```sh
sudo pacman -Syu
```

### BSD

```sh
sudo pkg upgrade
```

## Login.defs

Set a secure encryption method

Inside `/etc/login.defs`:

```properties
ENCRYPT_METHOD YESCRYPT
```

## Display Manager

### LightDM

Disable guest login, auto login, user enumeration, remote X server login, and VNC/RDP access.

Inside `/etc/lightdm/lightdm.conf`:

```properties
allow-guest=false
AutomaticLogin=false
greeter-show-manual-login=true
greeter-hide-users=true
xdmcp-enabled=false
vnc-server-enabled=false
```

### GDM

Disable automatic login

Inside `/etc/gdm/custom.conf`:

```properties
AutomaticLoginEnable=false 
```

### SDDM

Disable automatic login and user enumeration

Inside `/etc/sddm.conf`:

```properties
User
Session
HideUsers
DisableDebug true
```
