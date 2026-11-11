# system/ — reinstall kit

Snapshot of the machine-level state that is **not** a stow package.
Do not `stow system`: these files belong in `/etc` or are reference lists.

| File | What it is | How to restore |
|---|---|---|
| `pkglist-native.txt` | `pacman -Qqen` (explicit repo packages) | `sudo pacman -S --needed - < pkglist-native.txt` |
| `pkglist-aur.txt` | `pacman -Qqem` (explicit AUR packages) | `yay -S --needed - < pkglist-aur.txt` |
| `enabled-services.txt` | `systemctl list-unit-files --state=enabled` | enable what you still want, one by one |
| `enabled-user-services.txt` | same, `--user` | `systemctl --user enable …` |
| `etc/ssh/sshd_config.d/10-hardening.conf` | key-only SSH (LAB-004) | `sudo install -Dm644 … /etc/ssh/…`, then `sudo sshd -t` |
| `etc/greetd/config.toml` | tuigreet → `start-hyprland` | `sudo install -Dm644 … /etc/greetd/` |
| `etc/fstab.reference` | old fstab, **reference only** | never copy: UUIDs change on reinstall, use `genfstab` |
| `libvirt/lab-01.xml` | VM definition | `virsh -c qemu:///system define libvirt/lab-01.xml` (disk must be back first) |
| `libvirt/net-default.xml` | NAT network + DHCP reservation for `192.168.122.10` | `virsh … net-define`, `net-autostart default` |
| `restore.sh` | runs the steps above in order | `./system/restore.sh` |

## Refresh before reinstalling

Run this right before you wipe the disk so the lists are current:

```bash
cd ~/homelab/dotfiles/system
pacman -Qqen > pkglist-native.txt
pacman -Qqem > pkglist-aur.txt
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > enabled-services.txt
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > enabled-user-services.txt
virsh -c qemu:///system dumpxml lab-01 > libvirt/lab-01.xml
```

## Not in this repo (on purpose)

| What | Why not GitHub | Where instead |
|---|---|---|
| `~/.ssh/id_ed25519`, `~/.gnupg/private-keys-v1.d` | private keys | encrypted tarball on USB / phone |
| `~/.config/gh/hosts.yml` | GitHub token | just `gh auth login` again |
| `~/walls` (6.9 GB) | too big, binary | external drive |
| `~/Downloads` (3.6 GB) | personal files | external drive, after cleanup |
| `/var/lib/libvirt/images/lab-01.qcow2` | VM disk, GBs | external drive, or rebuild the VM |
| Tailscale identity | per-device | `tailscale up` and re-join |

## Known issues found while backing up

- `wallpaper-timer`: `change_wallpaper.service` runs `~/.config/awww/awww.sh`, which does not exist. Fix or drop it.
- `hypr/hyprtoolkit.conf` is a symlink into `~/.cache/wal/`; it resolves once pywal has run once.
