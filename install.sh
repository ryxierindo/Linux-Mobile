#!/bin/bash
# Linux VPS + GUI for Termux (PRoot)
# No Android root required

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[1m'; N='\033[0m'
M='\033[0;35m'; W='\033[1;37m'
TICK="${G}✔${N}"; CROSS="${R}✘${N}"

ok() { echo -e " ${TICK} $1"; }
err() { echo -e "\n ${CROSS} ${R}$1${N}\n"; }
hdr() {
  clear
  echo -e "${C}${B}"
  echo "╔══════════════════════════════════════════╗"
  echo "║     Linux VPS + GUI Setup for Termux     ║"
  echo "║     No Root | VNC/RDP | Proot-Distro     ║"
  echo "╚══════════════════════════════════════════╝"
  echo -e "${N}"
}

get_rootfs() {
  local pd="$1"
  local paths=(
    "$PREFIX/var/lib/proot-distro/installed-rootfs/${pd}"
    "$HOME/../usr/var/lib/proot-distro/installed-rootfs/${pd}"
    "/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${pd}"
    "$HOME/.local/share/proot-distro/installed-rootfs/${pd}"
  )
  for p in "${paths[@]}"; do
    [ -d "$p" ] && echo "$p" && return
  done
  echo ""
}

choose_install_profile() {
  local mem_mb=0 disk_mb=0 arch="" recommended=2 reason="good balance for mobile devices"
  if command -v free >/dev/null 2>&1; then
    mem_mb=$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}')
  elif [ -f /proc/meminfo ]; then
    mem_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null)
  fi
  if command -v df >/dev/null 2>&1; then
    disk_mb=$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
  fi
  arch=$(uname -m 2>/dev/null || echo "unknown")

  if [ "$mem_mb" -ge 6000 ] && [ "$disk_mb" -ge 12000 ]; then
    recommended=1; reason="large RAM and storage"
  elif [ "$mem_mb" -ge 3000 ] && [ "$disk_mb" -ge 7000 ]; then
    recommended=2; reason="good balance for mobile devices"
  else
    recommended=3; reason="light device or limited storage"
  fi

  while true; do
    hdr
    echo -e "${C}${B}  [6/6] Select Install Profile${N}\n"
    echo -e "  ${Y}Recommended for your device:${N} ${W}$(case "$recommended" in 1) echo "Full";; 2) echo "Simplified";; 3) echo "Minimal";; esac)${N}"
    echo -e "  ${W}Reason:${N} $reason"
    echo ""
    echo "   1) Full        — all modules, best experience, heavier"
    echo "   2) Simplified  — essentials + optional extras, balanced"
    echo "   3) Minimal     — desktop + VNC/RDP only, lightest"
    echo "   4) Auto        — use the recommended choice"
    echo -e "\n   ${R}0) ← Back${N}\n"
    read -p "$(echo -e ${C}Profile [0-4, Enter]: ${N})" PROFILE_CHOICE
    case "$PROFILE_CHOICE" in
      0) create_new; return ;;
      "") PROFILE_CHOICE="$recommended" ;;
      4) PROFILE_CHOICE="$recommended" ;;
      1|2|3) ;;
      *) err "Invalid. Enter 0, 1, 2, 3 or 4."; sleep 1; continue ;;
    esac

    case "$PROFILE_CHOICE" in
      1) INSTALL_TYPE="full"; PROFILE_LABEL="Full"; PROFILE_REASON="all modules" ;;
      2) INSTALL_TYPE="simplified"; PROFILE_LABEL="Simplified"; PROFILE_REASON="essentials + extras" ;;
      3) INSTALL_TYPE="minimal"; PROFILE_LABEL="Minimal"; PROFILE_REASON="core desktop only" ;;
    esac

    case "$INSTALL_TYPE" in
      full) MODULES="fonts-dejavu-core fonts-noto-core curl git htop nano neofetch zip unzip ca-certificates" ;;
      simplified) MODULES="fonts-dejavu-core curl git htop nano zip unzip ca-certificates" ;;
      minimal) MODULES="curl ca-certificates" ;;
    esac

    ok "Profile: $PROFILE_LABEL"
    echo -e "  ${Y}Device:${N} RAM ${mem_mb}MB | Free storage ${disk_mb}MB | CPU ${arch}"
    echo -e "  ${Y}Mode:${N} $PROFILE_REASON"
    sleep 1
    break
  done
}

main_menu() {
  while true; do
    hdr
    echo -e "${W}${B}  MAIN MENU${N}\n"
    echo -e "  ${G}A)${N} Create New VPS"
    echo -e "  ${Y}B)${N} Start VPS"
    echo -e "  ${R}C)${N} Stop VPS"
    echo -e "  ${R}E)${N} Delete VPS"
    echo -e "  ${M}D)${N} Exit"
    echo ""
    read -p "$(echo -e ${C}Choose [A/B/C/D/E]: ${N})" MENU
    case "${MENU^^}" in
      A) create_new; return ;;
      B) start_vps; return ;;
      C) stop_vps; return ;;
      E) delete_vps; return ;;
      D) echo -e "\n${Y}Goodbye!${N}\n"; exit 0 ;;
      *) err "Invalid choice. Please enter A, B, C, D or E."; sleep 1 ;;
    esac
  done
}

delete_vps() {
  hdr
  echo -e "${R}${B}  DELETE VPS${N}\n"
  if [ ! -f "$HOME/start-vps.sh" ]; then
    err "No VPS found. Nothing to delete."
    read -p "Press Enter to go back..." _; main_menu; return
  fi
  local pd
  pd=$(grep -oP 'proot-distro login \K[^ ]+' "$HOME/start-vps.sh" 2>/dev/null)
  echo -e " ${Y}This will permanently delete the VPS and all its data.${N}"
  [ -n "$pd" ] && echo -e " Distro: ${W}$pd${N}"
  echo ""
  read -p "$(echo -e ${R}Type YES to confirm delete: ${N})" CONFIRM
  if [ "$CONFIRM" != "YES" ]; then
    err "Cancelled."; sleep 1; main_menu; return
  fi
  echo -ne " Stopping VPS...  "
  bash "$HOME/stop-vps.sh" 2>/dev/null
  echo -e "${TICK}"
  if [ -n "$pd" ]; then
    echo -ne " Removing distro ${W}$pd${N}...  "
    proot-distro remove "$pd" 2>/dev/null
    echo -e "${TICK}"
  fi
  echo -ne " Removing shortcuts...  "
  rm -f "$HOME/start-vps.sh" "$HOME/stop-vps.sh"
  echo -e "${TICK}"
  echo ""
  ok "VPS deleted successfully."
  echo ""; read -p "Press Enter to go back to menu..." _
  main_menu
}

start_vps() {
  hdr
  echo -e "${Y}${B}  START VPS${N}\n"
  if [ ! -f "$HOME/start-vps.sh" ]; then
    err "No VPS found. Please create one first."
    read -p "Press Enter to go back..." _; main_menu; return
  fi
  bash "$HOME/start-vps.sh"
}

stop_vps() {
  hdr
  echo -e "${R}${B}  STOP VPS${N}\n"
  if [ ! -f "$HOME/stop-vps.sh" ]; then
    err "No VPS found. Please create one first."
    read -p "Press Enter to go back..." _; main_menu; return
  fi
  bash "$HOME/stop-vps.sh"
  echo ""; read -p "Press Enter to go back to menu..." _
  main_menu
}

create_new() {
  NOTE=""
  while true; do
    hdr
    echo -e "${C}${B}  [1/6] Select Operating System${N}\n"
    echo -e "  ${W}── Basic / General ──${N}"
    echo "   1) Ubuntu          ← Most popular, best support"
    echo "   2) Debian          ← Rock solid, stable"
    echo "   3) Linux Mint      ← Beginner friendly"
    echo "   4) Zorin OS        ← Windows-like feel"
    echo "   5) Pop!_OS         ← Great for daily use"
    echo "   6) Elementary OS   ← macOS-like feel"
    echo "   7) MX Linux        ← Lightweight & reliable"
    echo ""
    echo -e "  ${W}── Gaming ──${N}"
    echo "   8) Garuda Linux    ← Best for gaming"
    echo "   9) Nobara          ← Fedora gaming spin"
    echo "  10) SteamOS         ← Steam Deck OS (Arch base)"
    echo ""
    echo -e "  ${W}── Security / Hacking ──${N}"
    echo "  11) Kali Linux      ← Penetration testing"
    echo "  12) Parrot OS       ← Security & privacy"
    echo "  13) BlackArch       ← Advanced security"
    echo "  14) Whonix          ← Max anonymity"
    echo ""
    echo -e "  ${W}── Lightweight ──${N}"
    echo "  15) Alpine Linux    ← Minimal, very fast"
    echo "  16) Void Linux      ← Fast & independent"
    echo "  17) Puppy Linux     ← Runs on old hardware"
    echo "  18) AntiX           ← Super lightweight"
    echo ""
    echo -e "  ${W}── Enterprise / Server ──${N}"
    echo "  19) Fedora          ← Cutting edge, reliable"
    echo "  20) CentOS Stream   ← Enterprise grade"
    echo "  21) Rocky Linux     ← RHEL compatible"
    echo "  22) AlmaLinux       ← RHEL compatible"
    echo "  23) OpenSUSE        ← Enterprise & desktop"
    echo ""
    echo -e "  ${W}── Advanced / Famous ──${N}"
    echo "  24) Arch Linux      ← DIY, bleeding edge"
    echo "  25) Manjaro         ← Arch made easy"
    echo "  26) Gentoo          ← Compile everything"
    echo "  27) NixOS           ← Reproducible builds"
    echo "  28) Slackware       ← Oldest active distro"
    echo ""
    echo -e "   ${R}0) ← Back to Menu${N}\n"
    read -p "$(echo -e ${C}OS [0-28]: ${N})" OS_CHOICE
    case $OS_CHOICE in
      0)  main_menu; return ;;
      1)  OS="Ubuntu";      PD="ubuntu";              NOTE=""; break ;;
      2)  OS="Debian";      PD="debian";              NOTE=""; break ;;
      3)  OS="Linux Mint";  PD="ubuntu";              NOTE="Mint uses Ubuntu base"; break ;;
      4)  OS="Zorin OS";    PD="ubuntu";              NOTE="Zorin uses Ubuntu base"; break ;;
      5)  OS="Pop!_OS";     PD="ubuntu";              NOTE="Pop uses Ubuntu base"; break ;;
      6)  OS="Elementary";  PD="ubuntu";              NOTE="Elementary uses Ubuntu base"; break ;;
      7)  OS="MX Linux";    PD="debian";              NOTE="MX uses Debian base"; break ;;
      8)  OS="Garuda";      PD="archlinux";           NOTE="Garuda uses Arch base"; break ;;
      9)  OS="Nobara";      PD="fedora";              NOTE="Nobara uses Fedora base"; break ;;
      10) OS="SteamOS";     PD="archlinux";           NOTE="SteamOS uses Arch base"; break ;;
      11) OS="Kali Linux";  PD="kali-rolling";        NOTE=""; break ;;
      12) OS="Parrot OS";   PD="debian";              NOTE="Parrot uses Debian base"; break ;;
      13) OS="BlackArch";   PD="archlinux";           NOTE="BlackArch uses Arch base"; break ;;
      14) OS="Whonix";      PD="debian";              NOTE="Whonix uses Debian base"; break ;;
      15) OS="Alpine";      PD="alpine";              NOTE=""; break ;;
      16) OS="Void Linux";  PD="void";                NOTE=""; break ;;
      17) OS="Puppy Linux"; PD="debian";              NOTE="Puppy uses Debian base"; break ;;
      18) OS="AntiX";       PD="debian";              NOTE="AntiX uses Debian base"; break ;;
      19) OS="Fedora";      PD="fedora";              NOTE=""; break ;;
      20) OS="CentOS";      PD="fedora";              NOTE="CentOS uses Fedora base"; break ;;
      21) OS="Rocky Linux"; PD="fedora";              NOTE="Rocky uses Fedora base"; break ;;
      22) OS="AlmaLinux";   PD="fedora";              NOTE="Alma uses Fedora base"; break ;;
      23) OS="OpenSUSE";    PD="opensuse-tumbleweed"; NOTE=""; break ;;
      24) OS="Arch Linux";  PD="archlinux";           NOTE=""; break ;;
      25) OS="Manjaro";     PD="archlinux";           NOTE="Manjaro uses Arch base"; break ;;
      26) OS="Gentoo";      PD="gentoo";              NOTE=""; break ;;
      27) OS="NixOS";       PD="ubuntu";              NOTE="NixOS uses Ubuntu base in proot"; break ;;
      28) OS="Slackware";   PD="debian";              NOTE="Slackware uses Debian base in proot"; break ;;
      *)  err "Invalid. Enter a number between 0 and 28."; sleep 1 ;;
    esac
  done
  ok "OS: $OS"
  [ -n "$NOTE" ] && echo -e "  ${Y}Note: $NOTE${N}"
  sleep 1

  while true; do
    hdr
    echo -e "${C}${B}  [2/6] Select Version — $OS${N}\n"
    case $PD in
      ubuntu)
        echo "   1) 22.04 LTS Jammy   ← Recommended"
        echo "   2) 20.04 LTS Focal"
        echo "   3) 18.04 LTS Bionic" ;;
      debian)
        echo "   1) Debian 12 Bookworm   ← Recommended"
        echo "   2) Debian 11 Bullseye"
        echo "   3) Debian 10 Buster" ;;
      fedora)
        echo "   1) Fedora 39   ← Recommended"
        echo "   2) Fedora 38"
        echo "   3) Fedora 37" ;;
      kali-rolling)
        echo "   1) Kali Rolling   ← Recommended" ;;
      archlinux)
        echo "   1) Arch Latest   ← Recommended" ;;
      alpine)
        echo "   1) Alpine 3.18   ← Recommended"
        echo "   2) Alpine 3.17" ;;
      opensuse-tumbleweed)
        echo "   1) Tumbleweed Rolling   ← Recommended"
        echo "   2) Leap 15.5" ;;
      void)
        echo "   1) Void Latest   ← Recommended" ;;
      gentoo)
        echo "   1) Gentoo Latest   ← Recommended" ;;
      *)
        echo "   1) Latest   ← Recommended" ;;
    esac
    echo -e "   ${R}0) ← Back${N}\n"
    read -p "$(echo -e ${C}Version: ${N})" V
    case $PD in
      ubuntu)
        case $V in
          0) create_new; return ;;
          1) PD="ubuntu";           VER="22.04"; break ;;
          2) PD="ubuntu-oldlts";    VER="20.04"; break ;;
          3) PD="ubuntu-oldoldlts"; VER="18.04"; break ;;
          *) err "Invalid. Enter 0, 1, 2 or 3."; sleep 1 ;;
        esac ;;
      debian)
        case $V in
          0) create_new; return ;;
          1) PD="debian";              VER="12"; break ;;
          2) PD="debian-oldstable";    VER="11"; break ;;
          3) PD="debian-oldoldstable"; VER="10"; break ;;
          *) err "Invalid. Enter 0, 1, 2 or 3."; sleep 1 ;;
        esac ;;
      fedora)
        case $V in
          0) create_new; return ;;
          1) VER="39"; break ;;
          2) VER="38"; break ;;
          3) VER="37"; break ;;
          *) err "Invalid. Enter 0, 1, 2 or 3."; sleep 1 ;;
        esac ;;
      alpine)
        case $V in
          0) create_new; return ;;
          1) VER="3.18"; break ;;
          2) VER="3.17"; break ;;
          *) err "Invalid. Enter 0, 1 or 2."; sleep 1 ;;
        esac ;;
      opensuse-tumbleweed)
        case $V in
          0) create_new; return ;;
          1) VER="Tumbleweed"; break ;;
          2) PD="opensuse-leap"; VER="15.5"; break ;;
          *) err "Invalid. Enter 0, 1 or 2."; sleep 1 ;;
        esac ;;
      *)
        case $V in
          0) create_new; return ;;
          1) VER="Latest"; break ;;
          *) err "Invalid. Enter 0 or 1."; sleep 1 ;;
        esac ;;
    esac
  done
  ok "Version: $VER"
  sleep 1

  while true; do
    hdr
    echo -e "${C}${B}  [3/6] Select Desktop Environment${N}\n"
    echo "   1) XFCE4       ← Recommended (fast + good looking)"
    echo "   2) LXDE        (very lightweight)"
    echo "   3) LXQt        (modern lightweight)"
    echo "   4) MATE        (classic, stable)"
    echo "   5) KDE Plasma  (full featured, heavy)"
    echo "   6) GNOME       (modern, heavy)"
    echo "   7) Openbox     (minimal window manager)"
    echo "   8) i3          (tiling window manager)"
    echo -e "\n   ${R}0) ← Back${N}\n"
    read -p "$(echo -e ${C}Desktop [0-8]: ${N})" D
    case $D in
      0) create_new; return ;;
      1) DE="xfce4 xfce4-terminal"; SESSION="startxfce4";       break ;;
      2) DE="lxde";                                SESSION="startlxde";        break ;;
      3) DE="lxqt";                                SESSION="startlxqt";        break ;;
      4) DE="mate-desktop-environment";            SESSION="mate-session";     break ;;
      5) DE="kde-plasma-desktop";                  SESSION="startplasma-x11"; break ;;
      6) DE="gnome";                               SESSION="gnome-session";    break ;;
      7) DE="openbox obconf";                      SESSION="openbox-session";  break ;;
      8) DE="i3 i3status dmenu";                   SESSION="i3";               break ;;
      *) err "Invalid. Enter a number between 0 and 8."; sleep 1 ;;
    esac
  done
  ok "Desktop: $SESSION"
  sleep 1

  while true; do
    hdr
    echo -e "${C}${B}  [4/6] Select Connection Type${N}\n"
    echo "   1) VNC  — AVNC app on port 5901   ← Recommended"
    echo "   2) RDP  — RD Client app on port 3390"
    echo -e "\n   ${R}0) ← Back${N}\n"
    read -p "$(echo -e ${C}Connection [0-2]: ${N})" CONN
    case $CONN in
      0) create_new; return ;;
      1) CONN_TYPE="vnc"; PORT="5901"; break ;;
      2) CONN_TYPE="rdp"; PORT="3390"; break ;;
      *) err "Invalid. Enter 0, 1 or 2."; sleep 1 ;;
    esac
  done
  ok "Connection: $CONN_TYPE on port $PORT"
  sleep 1

  hdr
  echo -e "${C}${B}  [5/6] Set Password${N}\n"
  while true; do
    read -s -p "$(echo -e ${C}Password: ${N})" PASS; echo ""
    [ -z "$PASS" ] && err "Password cannot be empty." && sleep 1 && continue
    read -s -p "$(echo -e ${C}Confirm:  ${N})" PASS2; echo ""
    [ "$PASS" = "$PASS2" ] && break
    err "Passwords do not match. Try again."; sleep 1
  done
  ok "Password set."
  sleep 1

  choose_install_profile

  case "$INSTALL_TYPE" in
    simplified)
      case "$SESSION" in
        startxfce4) DE="xfce4 xfce4-terminal" ;;
        startlxde) DE="lxde-core" ;;
        startlxqt) DE="lxqt-core" ;;
        mate-session) DE="mate-desktop-environment-core" ;;
        startplasma-x11) DE="kde-plasma-desktop" ;;
        gnome-session) DE="gnome-core" ;;
        openbox-session) DE="openbox" ;;
        i3) DE="i3 dmenu" ;;
      esac
      ;;
    minimal)
      case "$SESSION" in
        startxfce4) DE="xfce4 xfce4-terminal" ;;
        startlxde) DE="lxde-core" ;;
        startlxqt) DE="lxqt-core" ;;
        mate-session) DE="mate-desktop-environment-core" ;;
        startplasma-x11) DE="kde-plasma-desktop" ;;
        gnome-session) DE="gnome-core" ;;
        openbox-session) DE="openbox" ;;
        i3) DE="i3 dmenu" ;;
      esac
      ;;
  esac

  hdr
  echo -e "${Y}${B}  Installing — please wait...${N}\n"

  START_TIME=$(date +%s)
  progress_bar() {
    local current=$1 total=$2 label=$3 pct filled bar_len=24 elapsed est em es
    pct=$(( current * 100 / total ))
    filled=$(( current * bar_len / total ))
    local bar=""
    local i
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=filled; i<bar_len; i++)); do bar+="."; done
    elapsed=$(( $(date +%s) - START_TIME ))
    est=$(( elapsed * total / current ))
    em=$(( est / 60 )); es=$(( est % 60 ))
    printf "\r ${C}%d/%d${N} %3d%% |%s| ${Y}EST:${N} ${Y}%dm%02ds${N} ${Y}Elapsed:${N} ${Y}%dm%02ds${N}  ${W}%s${N}" \
      "$current" "$total" "$pct" "$bar" "$em" "$es" "$(( elapsed / 60 ))" "$(( elapsed % 60 ))" "$label"
  }

  echo -e " ${C}[1/40]${N} Preparing Termux packages..."
  progress_bar 1 40 "Preparing Termux"
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y proot-distro wget curl git >/dev/null 2>&1 || true

  echo -e " ${C}[2/40]${N} Installing base system..."
  progress_bar 8 40 "Installing base system"
  proot-distro remove "$PD" >/dev/null 2>&1 || true
  if ! proot-distro install "$PD" >/tmp/proot-install.log 2>&1; then
    err "Failed — falling back to Ubuntu 22.04"
    PD="ubuntu"; OS="Ubuntu"; VER="22.04"
    proot-distro install ubuntu >/tmp/proot-install.log 2>&1 || true
  fi

  case "$PD" in
    ubuntu|debian*|kali-rolling)
      DESKTOP_PKGS="$DE xvfb x11vnc dbus-x11 x11-xserver-utils xauth xterm"
      ;;
    fedora|rocky|almalinux|centos)
      DESKTOP_PKGS="$DE xorg-x11-server-Xvfb x11vnc dbus-x11 xauth xterm"
      ;;
    archlinux|manjaro|garuda|nobara|steamos|blackarch)
      DESKTOP_PKGS="$DE xorg-server x11vnc dbus xorg-xauth xterm"
      ;;
    alpine)
      DESKTOP_PKGS="$DE xvfb x11vnc dbus xauth xterm"
      ;;
    opensuse*)
      DESKTOP_PKGS="$DE xorg-x11-server x11vnc dbus-1 xauth xterm"
      ;;
    void)
      DESKTOP_PKGS="$DE xorg-server x11vnc dbus xauth xterm"
      ;;
    *)
      DESKTOP_PKGS="$DE xvfb x11vnc dbus-x11 x11-xserver-utils xauth xterm"
      ;;
  esac

  echo -e " ${C}[3/40]${N} Installing desktop packages..."
  progress_bar 22 40 "Installing desktop packages"
  proot-distro login "$PD" --user root -- env DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 PD="$PD" DESKTOP_PKGS="$DESKTOP_PKGS" MODULES="$MODULES" PASS="$PASS" bash -c '
    case "$PD" in
      ubuntu|debian*|kali-rolling)
        apt-get update -y
        apt-get install -y --no-install-recommends $DESKTOP_PKGS $MODULES
        ;;
      fedora|rocky|almalinux|centos)
        dnf makecache --refresh
        dnf install -y $DESKTOP_PKGS $MODULES
        ;;
      archlinux|manjaro|garuda|nobara|steamos|blackarch)
        pacman -Syu --noconfirm --needed $DESKTOP_PKGS $MODULES
        ;;
      alpine)
        apk update
        apk add --no-cache $DESKTOP_PKGS $MODULES
        ;;
      opensuse*)
        zypper refresh
        zypper install -y $DESKTOP_PKGS $MODULES
        ;;
      void)
        xbps-install -Syu -y
        xbps-install -y $DESKTOP_PKGS $MODULES
        ;;
      *)
        apt-get update -y
        apt-get install -y --no-install-recommends $DESKTOP_PKGS $MODULES
        ;;
    esac
    echo "root:$PASS" | chpasswd
    mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml
    useradd -m -s /bin/bash termux >/dev/null 2>&1 || true
    echo "termux:$PASS" | chpasswd >/dev/null 2>&1 || true
  ' >/tmp/distro-install.log 2>&1 || true

  echo -e " ${C}[4/40]${N} Writing startup scripts..."
  progress_bar 32 40 "Writing startup files"
  proot-distro login "$PD" --user root -- env SESSION="$SESSION" PORT="$PORT" PASS="$PASS" bash -c '
cat > /root/start.sh <<EOF
#!/bin/bash
pkill x11vnc 2>/dev/null
pkill Xvfb 2>/dev/null
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null
sleep 1
Xvfb :1 -screen 0 1280x800x24 +extension GLX +render -noreset &
export DISPLAY=:1
unset DBUS_SESSION_BUS_ADDRESS SESSION_MANAGER
if command -v dbus-launch >/dev/null 2>&1; then
  dbus-launch --exit-with-session "$SESSION" >/tmp/de.log 2>&1 &
fi
sleep 3
x11vnc -display :1 -rfbport "$PORT" -passwd "$PASS" -forever -shared -noxdamage -noxfixes -noipv6 -bg -o /tmp/vnc.log 2>/dev/null
tail -f /tmp/vnc.log
EOF
chmod +x /root/start.sh
cat > /root/stop.sh <<EOF
#!/bin/bash
pkill x11vnc 2>/dev/null
pkill Xvfb 2>/dev/null
pkill -f "$SESSION" 2>/dev/null
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/vnc.log /tmp/de.log 2>/dev/null
echo "✔ Desktop stopped."
EOF
chmod +x /root/stop.sh
' >/tmp/startup.log 2>&1 || true

  echo -e " ${C}[5/40]${N} Finalizing shortcuts..."
  progress_bar 40 40 "Finalizing setup"
  printf '#!/bin/bash\nproot-distro login %s --user root -- bash /root/start.sh\n' "$PD" > "$HOME/start-vps.sh"
  printf '#!/bin/bash\nproot-distro login %s --user root -- bash /root/stop.sh\n' "$PD" > "$HOME/stop-vps.sh"
  chmod +x "$HOME/start-vps.sh" "$HOME/stop-vps.sh"

  echo -e "${TICK}"

  echo ""
  echo -e "${G}${B}╔══════════════════════════════════════════╗${N}"
  echo -e "${G}${B}║          ✅  SETUP COMPLETE!             ║${N}"
  echo -e "${G}${B}╠══════════════════════════════════════════╣${N}"
  echo -e "${G}${B}║  ▶ Start  : bash ~/start-vps.sh          ║${N}"
  echo -e "${G}${B}║  ■ Stop   : bash ~/stop-vps.sh           ║${N}"
  echo -e "${G}${B}║  Type   : $INSTALL_TYPE                       ${N}"
  echo -e "${G}${B}╠══════════════════════════════════════════╣${N}"
  if [ "$CONN_TYPE" = "rdp" ]; then
    echo -e "${G}${B}║  App    : RD Client                      ║${N}"
  else
    echo -e "${G}${B}║  App    : AVNC                           ║${N}"
  fi
  echo -e "${G}${B}