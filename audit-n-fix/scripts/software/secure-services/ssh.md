# Hardening SSHD

Ensure SSHD's integrity; if possible, completely purge it from the system and then reinstall it.

## Binary Integrity

1. Reinstall SSHD

```bash
# For Debian and its derivatives:
sudo apt-get install --reinstall openssh-server

# For modern Redhat systems and their derivatives:
sudo dnf reinstall openssh-server

# For legacy Redhat systems and their derivatives:
sudo yum reinstall openssh-server

# For Arch and its derivatives:
sudo pacman -S openssh
```

## Configuration & Host Keys

1. Purge SSH files

```bash
sudo rm -rf /etc/ssh
```

2. Regenerate RSA, ECDSA, and ED25519 private host keys

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

There is a pre-adjusted template,
`/etc/ssh/sshd_config` @ `audit-n-fix/scripts/cnf/sshd_config`
for your convenience.
