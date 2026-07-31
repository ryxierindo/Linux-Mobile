#!/bin/bash
# Linux VPS + GUI for Termux (PRoot)
# No Android root required

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[1m'; N='\033[0m'
M='\033[0;35m'; W='\033[1;37m'
TICK="${G}✔${N}"; CROSS="${R}✘${N}"

ok()  { echo -e " ${TICK} $1"; }
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

# ─── MAIN MENU ────────────────────────────────────────────────────────────────
main_menu() {
  while true; do
    hdr
    echo -e "${W}${B}  MAIN MENU${N}\n"
    echo -e "  ${G}A)${N} Create New VPS"
    echo -e "  ${Y}B)${N} Start VPS"
    echo -e "  ${R}C)${N} Stop VPS"
    echo -e "  ${M}D)${N} Exit"
    echo ""
    read -p "$(echo -e ${C}Choose [A/B/C/D]: ${N})" MENU
    case "${MENU^^}" in
      A) create_new; return ;;
      B) start_vps;  return ;;
      C) stop_vps;   return ;;
      D) echo -e "\n${Y}Goodbye!${N}\n"; exit 0 ;;
      *) err "Invalid choice. Please enter A, B, C or D."; sleep 1 ;;
    esac
  done
}

# ─── START VPS ────────────────────────────────────────────────────────────────
start_vps() {
  hdr
  echo -e "${Y}${B}  START VPS${N}\n"
  if [ ! -f "$HOME/start-vps.sh" ]; then
    err "No VPS found. Please create one first."
    read -p "Press Enter to go back..." _; main_menu; return
  fi
  bash "$HOME/start-vps.sh"
}

# ─── STOP VPS ─────────────────────────────────────────────────────────────────
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

# ─── CREATE NEW ───────────────────────────────────────────────────────────────
create_new() {

  # ── STEP 1: OS ──────────────────────────────────────────────────────────────
  NOTE=""
  while true; do
    hdr
    echo -e "${C}${B}  [1/5] Select Operating System${N}\n"
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
    echo -e "   ${R}0) ← Back to Menu${N}"
    echo ""
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
      *)  err "Invalid. Enter a number between 0 and 28." ; sleep 1 ;;
    esac
  done
  ok "OS: $OS"
  [ -n "$NOTE" ] && echo -e "  ${Y}Note: $NOTE${N}"
  sleep 1

  # ── STEP 2: VERSION ─────────────────────────────────────────────────────────
  while true; do
    hdr
    echo -e "${C}${B}  [2/5] Select Version — $OS${N}\n"
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

  # ── STEP 3: DESKTOP ─────────────────────────────────────────────────────────
  while true; do
    hdr
    echo -e "${C}${B}  [3/5] Select Desktop Environment${N}\n"
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
      1) DE="xfce4 xfce4-goodies xfce4-terminal"; SESSION="startxfce4";       break ;;
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

  # ── STEP 4: CONNECTION ──────────────────────────────────────────────────────
  while true; do
    hdr
    echo -e "${C}${B}  [4/5] Select Connection Type${N}\n"
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

  # ── STEP 5: PASSWORD ────────────────────────────────────────────────────────
  hdr
  echo -e "${C}${B}  [5/5] Set Password${N}\n"
  while true; do
    read -s -p "$(echo -e ${C}Password: ${N})" PASS;  echo ""
    [ -z "$PASS" ] && err "Password cannot be empty." && sleep 1 && continue
    read -s -p "$(echo -e ${C}Confirm:  ${N})" PASS2; echo ""
    [ "$PASS" = "$PASS2" ] && break
    err "Passwords do not match. Try again."; sleep 1
  done
  ok "Password set."
  sleep 1

  # ── INSTALL ─────────────────────────────────────────────────────────────────
  hdr
  echo -e "${Y}${B}  Installing — please wait...${N}\n"

  echo -ne " ${C}[1/4]${N} Updating Termux packages...        "
  pkg update -yq 2>/dev/null && pkg install -yq proot-distro wget curl 2>/dev/null
  echo -e "${TICK}"

  echo -ne " ${C}[2/4]${N} Installing $OS $VER...              "
  proot-distro remove "$PD" 2>/dev/null || true
  proot-distro install "$PD" 2>/dev/null || {
    echo -e "${CROSS}"
    err "Failed — falling back to Ubuntu 22.04"
    PD="ubuntu"; OS="Ubuntu"; VER="22.04"
    proot-distro install ubuntu 2>/dev/null
  }
  echo -e "${TICK}"

  ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/${PD}"

  # install.sh — written with printf, no heredoc expansion bugs
  {
    printf '#!/bin/bash\nexport DEBIAN_FRONTEND=noninteractive\n'
    printf 'apt-get update -yq 2>/dev/null\n'
    printf 'apt-get install -yq %s xvfb x11vnc dbus-x11 x11-xserver-utils xauth xterm fonts-noto papirus-icon-theme arc-theme nano wget curl git 2>/dev/null\n' "$DE"
    printf 'echo "root:%s" | chpasswd\n' "$PASS"
    printf 'mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml\n'
  } > "${ROOTFS}/tmp/install.sh"

  cat >> "${ROOTFS}/tmp/install.sh" << 'THEOF'
cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'X'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Noto Sans 10"/>
  </property>
</channel>
X
cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'X'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Arc-Dark"/>
    <property name="title_font" type="string" value="Noto Sans Bold 9"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="button_layout" type="string" value="O|HMC"/>
  </property>
</channel>
X
THEOF

  chmod +x "${ROOTFS}/tmp/install.sh"

  echo -ne " ${C}[3/4]${N} Installing desktop inside $OS...   "
  proot-distro login "$PD" --user root -- bash /tmp/install.sh 2>/dev/null
  echo -e "${TICK}"

  echo -ne " ${C}[4/4]${N} Writing startup scripts...          "

  # start.sh
  {
    printf '#!/bin/bash\n'
    printf 'pkill x11vnc 2>/dev/null; pkill Xvfb 2>/dev/null; sleep 1\n'
    printf 'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null\n'
    printf 'Xvfb :1 -screen 0 1280x800x24 +extension GLX +render -noreset &\n'
    printf 'sleep 2\n'
    printf 'export DISPLAY=:1\n'
    printf 'unset DBUS_SESSION_BUS_ADDRESS SESSION_MANAGER\n'
    printf 'dbus-launch --exit-with-session %s &>/tmp/de.log &\n' "$SESSION"
    printf 'sleep 3\n'
    printf 'x11vnc -display :1 -rfbport %s -passwd "%s" -forever -shared -noxdamage -noxfixes -noipv6 -bg -o /tmp/vnc.log 2>/dev/null\n' "$PORT" "$PASS"
    printf 'sleep 1\n'
    printf 'if pgrep x11vnc > /dev/null; then\n'
    printf '  echo ""\n'
    printf '  echo "╔══════════════════════════════════════════╗"\n'
    printf '  echo "║        ✅  DESKTOP IS RUNNING!           ║"\n'
    printf '  echo "╠══════════════════════════════════════════╣"\n'
    printf '  echo "║  OS     : %s %s\n' "$OS" "$VER"
    printf '  echo "║  Desktop: %s\n' "$SESSION"
    if [ "$CONN_TYPE" = "rdp" ]; then
      printf '  echo "║  App    : RD Client                      ║"\n'
    else
      printf '  echo "║  App    : AVNC                           ║"\n'
    fi
    printf '  echo "║  Host   : 127.0.0.1                      ║"\n'
    printf '  echo "║  Port   : %s                           ║"\n' "$PORT"
    printf '  echo "║  Pass   : %s\n' "$PASS"
    printf '  echo "╠══════════════════════════════════════════╣"\n'
    printf '  echo "║  ■ Stop : bash ~/stop-vps.sh             ║"\n'
    printf '  echo "╚══════════════════════════════════════════╝"\n'
    printf 'else\n'
    printf '  echo ""\n'
    printf '  echo "❌ x11vnc failed. Check log:"\n'
    printf '  cat /tmp/vnc.log\n'
    printf 'fi\n'
    printf 'tail -f /tmp/vnc.log\n'
  } > "${ROOTFS}/root/start.sh"
  chmod +x "${ROOTFS}/root/start.sh"

  # stop.sh
  {
    printf '#!/bin/bash\n'
    printf 'pkill x11vnc 2>/dev/null\n'
    printf 'pkill Xvfb 2>/dev/null\n'
    printf 'pkill -f "%s" 2>/dev/null\n' "$SESSION"
    printf 'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/vnc.log /tmp/de.log 2>/dev/null\n'
    printf 'echo "✔ Desktop stopped."\n'
  } > "${ROOTFS}/root/stop.sh"
  chmod +x "${ROOTFS}/root/stop.sh"

  # Termux shortcuts
  printf '#!/bin/bash\nproot-distro login %s --user root -- bash /root/start.sh\n' "$PD" > "$HOME/start-vps.sh"
  printf '#!/bin/bash\nproot-distro login %s --user root -- bash /root/stop.sh\n'  "$PD" > "$HOME/stop-vps.sh"
  chmod +x "$HOME/start-vps.sh" "$HOME/stop-vps.sh"

  echo -e "${TICK}"

  # ── DONE ────────────────────────────────────────────────────────────────────
  echo ""
  echo -e "${G}${B}╔══════════════════════════════════════════╗${N}"
  echo -e "${G}${B}║          ✅  SETUP COMPLETE!             ║${N}"
  echo -e "${G}${B}╠══════════════════════════════════════════╣${N}"
  echo -e "${G}${B}║  ▶ Start  : bash ~/start-vps.sh          ║${N}"
  echo -e "${G}${B}║  ■ Stop   : bash ~/stop-vps.sh           ║${N}"
  echo -e "${G}${B}╠══════════════════════════════════════════╣${N}"
  if [ "$CONN_TYPE" = "rdp" ]; then
    echo -e "${G}${B}║  App    : RD Client                      ║${N}"
  else
    echo -e "${G}${B}║  App    : AVNC                           ║${N}"
  fi
  echo -e "${G}${B}║  Host   : 127.0.0.1                      ║${N}"
  echo -e "${G}${B}║  Port   : $PORT                              ║${N}"
  echo -e "${G}${B}║  Pass   : $PASS${N}"
  echo -e "${G}${B}╚══════════════════════════════════════════╝${N}"
  echo ""
  echo -e "${Y}Starting desktop now...${N}\n"

  proot-distro login "$PD" --user root -- bash /root/start.sh
}

# ─── ENTRY POINT ─────────────────────────────────────────────────────────────
main_menu
