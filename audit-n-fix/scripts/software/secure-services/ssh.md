# Hardening SSHD

Ensure SSHD's integrity; if possible, completely purge it from the system and then reinstall it.

## Binary Integrity

1. Uninstall SSHD

<small>(OS-dependant commands)</small>

```bash
# For Debian and its derivatives:
sudo apt autopurge openssh-server

# For modern Redhat systems and their derivatives:
sudo dnf remove openssh-server

# For legacy Redhat systems and their derivatives:
sudo yum remove openssh-server

# For Arch and its derivatives:
sudo pacman -Rns openssh-server
```

2. Reinstall it

<small>(OS-dependant commands)</small>

```bash
# For Debian and its derivatives:
sudo apt install openssh-server

# For modern Redhat systems and their derivatives:
sudo dnf install openssh-server

# For legacy Redhat systems and their derivatives:
sudo yum install openssh-server

# For Arch and its derivatives:
sudo pacman -Sy openssh-server
```

## Configuration & Secrets

1. Purge SSH files

<small>(OS-agnostic commands)</small>

```bash
sudo rm -rf /etc/ssh
```

2. Regenerate RSA, ECDSA, and ED25519 private host keys

<small>(OS-agnostic commands)</small>

```bash
ssh-keygen -A
ssh-keygen -f /root/.ssh/known_hosts -R localhost
```

3. Adjust `/etc/ssh/sshd_config` and add to `/etc/ssh/sshd_config.d` as needed.

- Disable root login*
- Adjust login grace time to your use-case
- Adjust max concurrent sessions to your use-case
- Lower max authentication attempts*
- Disable Hostbased authentication*
- Ignore user known hosts*
- Ignore user rhosts and shosts*
- Enable or disable Kerberos, GSSAPI, and password authentication as needed to your use-case
- Disable agent, X11, TCP forwarding, and SFTP subsystem*

\* Handled in the template 

<small>Pre-adjusted template `/etc/ssh/sshd_config` found at `audit-n-fix/scripts/cnf/sshd_config` for your convenience.</small>