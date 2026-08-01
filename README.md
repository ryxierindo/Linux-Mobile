# Linux VPS + GUI — Termux

Run a full Linux desktop with VNC/RDP inside proot. Supports 28 distros, 8 desktop environments. Works on Android (Termux).

---

## Quick Install

### Android — Termux
```bash
# Step 1 — Install Termux from F-Droid (NOT Play Store)
# https://f-droid.org/packages/com.termux/

# Step 2 — Run in Termux
pkg update -y && pkg install -y wget
wget https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/vps-gui.sh
chmod +x vps-gui.sh
bash vps-gui.sh
```

---

## Menu

```
A) Create New VPS   — pick OS, version, desktop, connection, password
B) Start VPS        — start the desktop
C) Stop VPS         — stop the desktop
D) Exit
```

Every step has `0` to go back. Blank or invalid input always reshows the same screen.

---

## After Install — 2 Commands Only

```bash
bash ~/start-vps.sh   # start desktop
bash ~/stop-vps.sh    # stop desktop
```

---

## Supported Distros (28)

| Category | Distros |
|---|---|
| Basic / General | Ubuntu, Debian, Linux Mint, Zorin OS, Pop!_OS, Elementary OS, MX Linux |
| Gaming | Garuda Linux, Nobara, SteamOS |
| Security | Kali Linux, Parrot OS, BlackArch, Whonix |
| Lightweight | Alpine Linux, Void Linux, Puppy Linux, AntiX |
| Enterprise | Fedora, CentOS Stream, Rocky Linux, AlmaLinux, OpenSUSE |
| Advanced | Arch Linux, Manjaro, Gentoo, NixOS, Slackware |

---

## Supported Desktop Environments (8)

| # | DE | Type |
|---|---|---|
| 1 | XFCE4 | Lightweight ✅ Recommended |
| 2 | LXDE | Very Lightweight |
| 3 | LXQt | Modern Lightweight |
| 4 | MATE | Classic |
| 5 | KDE Plasma | Full-featured |
| 6 | GNOME | Modern |
| 7 | Openbox | Minimal WM |
| 8 | i3 | Tiling WM |

---

## Connection

| Type | App | Port |
|---|---|---|
| VNC ✅ Recommended | AVNC (Android) | 5901 |
| RDP | RD Client (Android) | 3390 |

### Connect on Android
- Install **AVNC** from Play Store
- Host: `127.0.0.1` — Port: `5901` — Password: your set password

---

## Requirements

| Platform | Requirements |
|---|---|
| Android | Termux from F-Droid, Android 7+, 2–5 GB free |

---

## Notes

- No Android root required — uses proot
- Scripts are written directly inside the distro — no path issues
- VNC is more reliable than RDP in proot environments
- XFCE4 recommended for best performance on mobile hardware
