#!/usr/bin/env bash
# Run on the OLD system, right before wiping the disk.
#   ./system/pre-reinstall.sh /run/media/$USER/USB
# 1. refreshes the package/service lists in this repo (commit + push them after)
# 2. writes an encrypted tarball of everything that must NOT go to GitHub
set -euo pipefail

DEST="${1:?usage: $0 <backup-dir, e.g. a USB drive>}"
SYS="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%F)"

echo "==> Refreshing lists in $SYS"
pacman -Qqen > "$SYS/pkglist-native.txt"
pacman -Qqem > "$SYS/pkglist-aur.txt"
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > "$SYS/enabled-services.txt"
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > "$SYS/enabled-user-services.txt"
virsh -c qemu:///system dumpxml lab-01 > "$SYS/libvirt/lab-01.xml"
virsh -c qemu:///system net-dumpxml default > "$SYS/libvirt/net-default.xml"

echo "==> Encrypted secrets -> $DEST/secrets-$STAMP.tar.gz.gpg (asks for a passphrase)"
tar -C "$HOME" -czf - \
    .ssh .gnupg \
    .claude/projects/-home-Yongjanes/memory \
    .claude/settings.json \
    Practice \
    2>/dev/null \
  | gpg --symmetric --cipher-algo AES256 -o "$DEST/secrets-$STAMP.tar.gz.gpg"

echo "==> Big files (plain copy, not encrypted)"
rsync -a --info=progress2 "$HOME/walls" "$DEST/"
sudo cp --sparse=always /var/lib/libvirt/images/lab-01.qcow2 "$DEST/lab-01-$STAMP.qcow2"

echo
echo "Done. Now:"
echo "  cd $(dirname "$SYS") && git status   # commit + push the refreshed lists"
echo "  ls -lh $DEST                          # check the backup is really there"
