# https://aur.archlinux.org/packages/pacman-cleanup-hook
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = *

[Action]
Description = Removing obsolete cached package files (keeping the latest two)...
Depends = pacman-contrib
When = PostTransaction
Exec = /bin/sh -c 'paccache -rk1; paccache -ruk0'
