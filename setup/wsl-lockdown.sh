#!/usr/bin/env bash
# One-time setup of the conker-ps5 WSL distro (a copy of dk64-ps5's disk, made 2026-11-08).
# Run as root, then restart the distro (wsl --terminate conker-ps5). It keeps the build user,
# stops Windows drives being mounted except this project folder, and stops Linux launching
# Windows programs. The DK64 folder is no longer mounted here.
set -euo pipefail

user=sam
id "$user" >/dev/null 2>&1 || useradd --create-home --uid 1000 --shell /bin/bash "$user"

cat > /etc/wsl.conf <<'EOF'
[boot]
systemd=true

[automount]
# Windows drives are not mounted. Only the project folder is, through /etc/fstab.
enabled=false
mountFsTab=true

[interop]
# Linux cannot launch Windows programs, and the Windows PATH is not added.
enabled=false
appendWindowsPath=false

[user]
default=sam

[network]
hostname=conker-ps5
generateHosts=true
EOF

# The project folder at /mnt/conker. fstab octal escapes: \134 is a backslash, \040 a space.
mkdir -p /mnt/conker
sed -i '\# /mnt/dk64 #d; \# /mnt/conker #d' /etc/fstab
echo 'C:\134Users\134samcl\134Desktop\134PS5\040Recomps\134Conker\040-\040PS5 /mnt/conker drvfs rw,noatime,metadata,uid=1000,gid=1000,umask=022 0 0' >> /etc/fstab
umount /mnt/dk64 2>/dev/null || true
rmdir /mnt/dk64 2>/dev/null || true

echo "lockdown written; restart the distro to apply"
