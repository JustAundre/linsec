# Linsec

> [!IMPORTANT]
>
> Remember to use your own judgement and
> apply steps as needed in accordance with your scenario.

## Requirements

`main.sh` runs these checks on startup and offers to proceed anyway if any of them fail:

- Running w/ Bash interpreter (and not sourced)
- Root/UID 0 (`sudo`)
- SystemD or SysV `init` as PID 1
- An interactive terminal
- A supported package manager: `apt-get`, `dnf`, `yum`, `pacman` or `pkg`
- Complete UID/GID bounding definitions in `/etc/login.defs`

It then audits the shared libraries of a handful of core tools
and asks the package manager to verify them and report their owning package.
If anything listed there isn't owned by the system, stop and deal with that first.
On Debian-based systems this check needs `debsums`.

## Usage

1. [Clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository?tool=desktop) the repository
  **with the `--recurse-submodules` flag** to pull dependencies.

1. Read the [wiki](#full-documentation)
  in order to effectively understand your needs.

1. Run `sudo ./main.sh`
  You will be presented with a list of scripts;
  select the scripts you have decided on from the previous step.

Note-worthy findings that don't fit on a terminal are written to `logs/<date>/` inside the repository directory.

## Full Documentation

Please see the [wiki](https://ass-suite.vercel.app/docs?q=toc/linsec.md) for the full documentation.