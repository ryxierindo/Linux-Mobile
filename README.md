# Linux VPS + GUI + XRDP in Termux

Run a full Linux desktop with XRDP inside Termux using proot. Supports 20 distros, 8 desktop environments, and opens ports 19132–25565 TCP/UDP.

---

## Quick Install (Copy & Paste in Termux)

### Step 1 — Update Termux & install dependencies
```bash
pkg update -y && pkg install -y wget
```

### Step 2 — Download and run the script
```bash
wget https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/vps-gui.sh
chmod +x vps-gui.sh
bash vps-gui.sh
```


---

## What the Script Does

1. Shows a menu of **20 Linux distros** with version selection
2. Shows a menu of **8 desktop environments**
3. Prompts you to **set a root password**
4. Installs the distro via `proot-distro`
5. Installs the selected GUI + XRDP inside the distro
6. Opens ports **19132–25565 TCP/UDP**
7. Starts XRDP on port **3389**
8. Creates `~/start-vps.sh` to restart anytime

---

## Supported Distros

| # | Distro | Version |
|---|--------|---------|
| 1 | Ubuntu | 22.04 LTS |
| 2 | Ubuntu | 20.04 LTS |
| 3 | Ubuntu | 18.04 LTS |
| 4 | Debian | 12 Bookworm |
| 5 | Debian | 11 Bullseye |
| 6 | Debian | 10 Buster |
| 7 | Kali Linux | Rolling |
| 8 | Kali Linux | 2023.x |
| 9 | Parrot OS | Security |
| 10 | Alpine Linux | 3.18 |
| 11 | Alpine Linux | 3.17 |
| 12 | Fedora | 38 |
| 13 | Fedora | 37 |
| 14 | Arch Linux | Latest |
| 15 | Manjaro | Latest |
| 16 | CentOS Stream | 9 |
| 17 | Rocky Linux | 9 |
| 18 | OpenSUSE | Tumbleweed |
| 19 | Void Linux | Latest |
| 20 | Gentoo | Latest |

---

## Supported Desktop Environments

| # | DE | Type |
|---|----|------|
| 1 | XFCE4 | Lightweight ✅ Recommended |
| 2 | LXDE | Very Lightweight |
| 3 | LXQt | Modern Lightweight |
| 4 | MATE | Classic |
| 5 | KDE Plasma | Full-featured |
| 6 | GNOME | Modern |
| 7 | Openbox | Minimal WM |
| 8 | i3 | Tiling WM |

---

## RDP Connection Info

| Field | Value |
|-------|-------|
| Host | `localhost:3389` or `<device-ip>:3389` |
| Username | `root` |
| Password | *(set during install)* |
| Ports Open | `19132–25565 TCP/UDP` |

---

## Connect via RDP

- **Android**: Use [Microsoft RDP](https://play.google.com/store/apps/details?id=com.microsoft.rdc.androidx) or [AVNC](https://play.google.com/store/apps/details?id=com.gaurav.avnc)
- **PC**: Use Windows Remote Desktop (`mstsc`) or Remmina on Linux
- **iOS**: Use Microsoft Remote Desktop from App Store

---

## Restart VPS After Reboot

```bash
bash ~/start-vps.sh
```

---

## Manual Login to Distro Shell

```bash
# Ubuntu/Debian example
proot-distro login ubuntu --user root

# Kali
proot-distro login kali-rolling --user root

# Alpine
proot-distro login alpine --user root
```

---

## Requirements

- Termux (latest from [F-Droid](https://f-droid.org/packages/com.termux/), NOT Play Store)
- Android 7.0+
- ~2–5 GB free storage (depends on distro + DE)
- Internet connection

---

## Notes

- XRDP runs on port **3389** inside proot (no root needed on Android)
- Ports 19132–25565 are opened via iptables inside the container
- For Minecraft Bedrock: port **19132 UDP**
- For Minecraft Java: port **25565 TCP**
- proot does not require Android root access

---

## Upload to GitHub

```bash
# On your PC or Termux with git installed
git init
git add vps-gui.sh README.md
git commit -m "Linux VPS GUI setup for Termux"
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
git push -u origin main
```
