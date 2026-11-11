#!/usr/bin/env bash
# Rebuild this Arch + Hyprland setup on a fresh install.
# Run as your normal user from the repo root:  ./system/restore.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SYS="$REPO/system"

STOW_PACKAGES=(
    bash git starship fastfetch kitty tmux
    hypr waybar rofi swaync swayosd waypaper wal
    gtk qt mimeapps k9s lidmode wallpaper-timer
)

echo "==> 1/4 Native packages"
sudo pacman -Syu --needed - < "$SYS/pkglist-native.txt"

echo "==> 2/4 AUR packages (needs yay)"
if ! command -v yay >/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
fi
yay -S --needed - < <(grep -v -e '^yay$' -e '^yay-debug$' "$SYS/pkglist-aur.txt")

echo "==> 3/4 Dotfiles (stow)"
cd "$REPO"
for pkg in "${STOW_PACKAGES[@]}"; do
    # TODO(human): stow "$pkg", handling the case where a fresh install
    # already put a default file at the target (e.g. ~/.bashrc from /etc/skel).
    :
done
# Absolute symlink, so stow can't carry it; pywal fills the target on first run.
ln -sf "$HOME/.cache/wal/colors-hyprtoolkit.conf" "$HOME/.config/hypr/hyprtoolkit.conf"

echo "==> 4/4 System files"
sudo install -Dm644 "$SYS/etc/ssh/sshd_config.d/10-hardening.conf" /etc/ssh/sshd_config.d/10-hardening.conf
sudo install -Dm644 "$SYS/etc/greetd/config.toml" /etc/greetd/config.toml
sudo sshd -t   # refuse to continue with a broken sshd config

echo
echo "Done. Next, by hand (see README.md):"
echo "  - enable services from system/enabled-services.txt"
echo "  - restore secrets: gpg -d secrets-DATE.tar.gz.gpg | tar -C ~ -xzf -"
echo "  - copy the lab-01 disk back, then: virsh -c qemu:///system define system/libvirt/lab-01.xml"
