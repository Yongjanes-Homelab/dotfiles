# Reinstall runbook

Goal: wipe the laptop, reinstall Arch, and get back to **this exact setup**
(Hyprland desktop, SSH hardening, Tailscale, libvirt + `lab-01`).

The path is split in two:

- **Parts 0–4, by hand:** from the USB stick to a bare system with WiFi, git and Claude Code.
- **Part 5, Claude:** paste one prompt and Claude runs the rest from this runbook.

| Script | Run on | Does |
|---|---|---|
| `system/pre-reinstall.sh <usb>` | old system | refreshes package/service lists, encrypted secrets tarball, copies walls + VM disk |
| `system/restore.sh` | new system | packages, AUR, stow dotfiles, `/etc` files |

Details of every file: [`system/README.md`](system/README.md).

## The machine (as of 2026-11-11)

| | |
|---|---|
| Laptop | Lenovo LOQ 15IAX9 (UEFI) |
| CPU / GPU | Intel (Alder Lake) + NVIDIA RTX 3050 6GB Laptop → `intel-ucode`, `nvidia-open` |
| WiFi | Realtek RTL8852BE (works with stock `linux-firmware`) |
| Disk | `nvme0n1` 477 GB: `p1` 4 GB vfat `/boot`, `p2` 8 GB swap, `p3` rest ext4 `/` |
| Boot | GRUB, kernel `linux`, cmdline `loglevel=3 quiet`, default mkinitcpio hooks |
| Locale | `en_US.UTF-8`, keymap `us`, timezone `Asia/Kolkata` |
| Host / user | hostname `Yongjanes`, user `Yongjanes` (sudo) |

---

## Part 0 — Before wiping (old system)

1. Plug in a USB / external drive with ~20 GB free (**not** the one you will flash in Part 1).
2. Push anything unpushed:
   - `~/Practice/repoguide` has **no remote** and uncommitted changes: create a GitHub repo and push, or rely on the tarball (it includes `~/Practice`).
3. `./system/pre-reinstall.sh /run/media/$USER/<drive>`
4. Commit + push the refreshed lists in this repo.
5. Check: `ls -lh /run/media/$USER/<drive>`, then test-decrypt:
   `gpg -d secrets-*.tar.gz.gpg | tar -tzf - | head`
6. Copy anything you want from `~/Downloads` (3.6 GB, not covered by the script).
7. Write down your WiFi name + password, and the gpg passphrase you just used.

## Part 1 — Bootable USB

1. Download the latest ISO + `sha256sums.txt` from <https://archlinux.org/download/> (an India mirror is fastest).
2. Verify: `sha256sum -c sha256sums.txt --ignore-missing`
3. Find the stick: `lsblk` (e.g. `/dev/sdb`; **triple-check**, `dd` wipes whatever you point it at).
4. Flash:
   ```bash
   sudo dd if=archlinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
   (From Windows: Rufus, DD mode.)

## Part 2 — Boot the installer

1. Plug in the stick, power on, tap **F12** for the Lenovo boot menu (**F2** = BIOS setup) and pick the USB (UEFI entry).
2. If it refuses to boot: in BIOS, turn **Secure Boot off** (the current system runs without it).
3. At the `root@archiso` prompt:
   ```bash
   iwctl                                   # WiFi
     device list                           # usually wlan0
     station wlan0 connect "<SSID>"
     exit
   ping -c3 archlinux.org                  # must work before going on
   timedatectl set-ntp true
   ```

## Part 3 — Install with archinstall

`archinstall`, then pick:

| Menu | Choice |
|---|---|
| Mirrors | India |
| Locales | keyboard `us`, language `en_US`, encoding `UTF-8` |
| Disk config | best-effort / default layout on `nvme0n1`, **wipe**, ext4, separate `/boot` (≥1 GB; old one was 4 GB) |
| Swap | swap on zram is the archinstall default and fine (old system used an 8 GB partition) |
| Bootloader | **GRUB** |
| Hostname | `Yongjanes` |
| Root password | none (use sudo) |
| User | `Yongjanes`, superuser = yes |
| Profile | **Minimal** (Hyprland comes from `restore.sh`, not from here) |
| Graphics driver | **NVIDIA (open kernel module)** + Intel |
| Audio | **pipewire** |
| Kernels | `linux` |
| Network | **NetworkManager** |
| Additional packages | `git stow base-devel vim` |
| Timezone | `Asia/Kolkata` |
| NTP | yes |

Install → when it asks to chroot, say no → `reboot` and pull the USB.

## Part 4 — Bare minimum on first boot

Log in on the TTY as `Yongjanes`:

```bash
nmcli device wifi connect "<SSID>" password "<password>"
ping -c3 archlinux.org

# secrets first, so SSH keys and Claude's memory are back before Claude starts
udisksctl mount -b /dev/sdX1        # or: sudo mount /dev/sdX1 /mnt
gpg -d /run/media/$USER/<drive>/secrets-*.tar.gz.gpg | tar -C ~ -xzf -
chmod 700 ~/.ssh ~/.gnupg && chmod 600 ~/.ssh/id_ed25519

# this repo
mkdir -p ~/homelab
git clone https://github.com/Yongjanes-Homelab/dotfiles.git ~/homelab/dotfiles

# Claude Code (native installer)
curl -fsSL https://claude.ai/install.sh | bash
exec bash -l
cd ~/homelab/dotfiles && claude
```

## Part 5 — Hand over to Claude

Paste this into Claude Code (the backup drive must still be plugged in):

```text
I just reinstalled Arch on this laptop and I'm at the bare minimum
(Part 4 of REINSTALL.md is done: WiFi, secrets restored, this repo cloned).
Read REINSTALL.md and system/README.md in ~/homelab/dotfiles, then take me
through "Part 6" step by step until the system is back to how it was:
run system/restore.sh, enable the services, re-join Tailscale, bring back
lab-01, wallpapers and notes. The backup drive is mounted at
/run/media/Yongjanes/<drive>. Explain each step in Hinglish before running
it, ask before anything that needs sudo, and do not commit or push
anything: give me the git commands instead.
```

## Part 6 — Rest of the restore (Claude runs this with you)

1. `./system/restore.sh` (packages → AUR → stow → `/etc` files)
2. **Services:** go through `system/enabled-services.txt` (sshd, tailscaled, libvirtd, greetd, docker.socket, libvirt-guests …) and `sudo systemctl enable --now` what is still wanted; same for `enabled-user-services.txt` with `--user`.
3. **Groups:** `sudo usermod -aG libvirt,docker $USER`, then log out and back in.
4. **Tailscale:** `sudo tailscale up` (re-joins as a new device; remove the old one in the admin console).
5. **GitHub CLI:** `gh auth login`
6. **Notes:** `git clone git@github.com:Yongjanes-Homelab/homelab-notes.git ~/homelab/homelab-notes`
7. **Wallpapers:** `rsync -a /run/media/$USER/<drive>/walls ~/`, then run pywal once.
8. **VM:**
   ```bash
   sudo cp --sparse=always /run/media/$USER/<drive>/lab-01-*.qcow2 /var/lib/libvirt/images/lab-01.qcow2
   virsh -c qemu:///system net-define system/libvirt/net-default.xml   # skip if 'default' already exists
   virsh -c qemu:///system net-autostart default
   virsh -c qemu:///system define system/libvirt/lab-01.xml
   virsh -c qemu:///system autostart lab-01 && virsh -c qemu:///system start lab-01
   ssh yongjanes@192.168.122.10
   ```
9. **Reboot and verify:** greetd → Hyprland comes up, `ssh` from the phone over Tailscale works, `lab-01` autostarts.
