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

# ─── FIND ROOTFS PATH ─────────────────────────────────────────────────────────
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

# ─── MAIN MENU ────────────────────────────────────────────────────────────────
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
      A) create_new;  return ;;
      B) start_vps;   return ;;
      C) stop_vps;    return ;;
      E) delete_vps;  return ;;
      D) echo -e "\n${Y}Goodbye!${N}\n"; exit 0 ;;
      *) err "Invalid choice. Please enter A, B, C, D or E."; sleep 1 ;;
    esac
  done
}

# ─── DELETE VPS ──────────────────────────────────────────────────────────────
delete_vps() {
  hdr
  echo -e "${R}${B}  DELETE VPS${N}\n"
  if [ ! -f "$HOME/start-vps.sh" ]; then
    err "No VPS found. Nothing to delete."
    read -p "Press Enter to go back..." _; main_menu; return
  fi
  # Read which distro is installed from the shortcut
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
  echo -e "${C}${B}  [5/6] Set Password${N}\n"
  while true; do
    read -s -p "$(echo -e ${C}Password: ${N})" PASS;  echo ""
    [ -z "$PASS" ] && err "Password cannot be empty." && sleep 1 && continue
    read -s -p "$(echo -e ${C}Confirm:  ${N})" PASS2; echo ""
    [ "$PASS" = "$PASS2" ] && break
    err "Passwords do not match. Try again."; sleep 1
  done
  ok "Password set."
  sleep 1

  # ── STEP 6: INSTALL TYPE ────────────────────────────────────────────────────
  while true; do
    hdr
    echo -e "${C}${B}  [6/6] Select Install Type${N}\n"
    echo "   1) Full Linux     — complete desktop, all tools"
    echo "   2) Simplified     — minimal install, less storage & faster"
    echo -e "\n   ${R}0) ← Back${N}\n"
    read -p "$(echo -e ${C}Type [0-2]: ${N})" ITYPE
    case $ITYPE in
      0) create_new; return ;;
      1) INSTALL_TYPE="full";       break ;;
      2) INSTALL_TYPE="simplified"; break ;;
      *) err "Invalid. Enter 0, 1 or 2."; sleep 1 ;;
    esac
  done
  ok "Install type: $INSTALL_TYPE"
  sleep 1

  if [ "$INSTALL_TYPE" = "simplified" ]; then
    # Simplified: strip DE down to bare minimum — no extras, no full DE meta
    case $SESSION in
      startxfce4)       DE="xfce4 xfce4-terminal" ;;
      startlxde)        DE="lxde-core" ;;
      startlxqt)        DE="lxqt-core" ;;
      mate-session)     DE="mate-desktop-environment-core" ;;
      startplasma-x11)  DE="kde-plasma-desktop" ;;
      gnome-session)    DE="gnome-core" ;;
      openbox-session)  DE="openbox" ;;
      i3)               DE="i3 dmenu" ;;
    esac
  fi

  # ── INSTALL ─────────────────────────────────────────────────────────────────
  hdr
  echo -e "${Y}${B}  Installing — please wait...${N}\n"

  # ── install progress: single updating line ───────────────────────────────
  apt_progress() {
    local cur=0 total=0 pkgname="..." start elapsed est em es pct line
    start=$(date +%s)
    while IFS= read -r line; do
      if [[ "$line" =~ ([0-9]+)" newly installed" ]]; then
        total=${BASH_REMATCH[1]}
      fi
      if [[ "$line" =~ ^Unpacking[[:space:]]([^[:space:]:]+) ]]; then
        cur=$((cur+1)); pkgname=${BASH_REMATCH[1]}
        [ $total -lt 1 ] && total=1
        pct=$(( cur * 100 / total ))
        elapsed=$(( $(date +%s) - start ))
        if [ $cur -gt 0 ] && [ $elapsed -gt 0 ]; then
          est=$(( elapsed * (total - cur) / cur ))
        else est=0; fi
        em=$(( est / 60 )); es=$(( est % 60 ))
        printf "\r ${C}Installing:${N} ${W}%d/%d${N}  %-30s  ${G}%d%%${N}  EST: ${Y}%dm %ds${N}   " \
          "$cur" "$total" "$pkgname" "$pct" "$em" "$es"
      fi
    done
    printf "\r ${TICK} Done: ${W}%d/%d packages${N}  ${G}100%%${N}                                    \n" "$cur" "$cur"
  }

  echo -e " ${C}[1/4]${N} Updating Termux packages..."
  { pkg update -yq 2>&1 && pkg install -yq proot-distro wget curl 2>&1; } | apt_progress

  echo -e " ${C}[2/4]${N} Installing $OS $VER..."
  { proot-distro remove "$PD" 2>&1 || true; proot-distro install "$PD" 2>&1; } | apt_progress
  if [ $? -ne 0 ]; then
    err "Failed — falling back to Ubuntu 22.04"
    PD="ubuntu"; OS="Ubuntu"; VER="22.04"
    proot-distro install ubuntu 2>&1 | apt_progress
  fi

  echo -e " ${C}[3/4]${N} Installing desktop inside $OS..."
  proot-distro login "$PD" --user root -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y 2>&1
    apt-get install -y $DE xvfb x11vnc dbus-x11 x11-xserver-utils xauth xterm 2>&1
    echo 'root:$PASS' | chpasswd
    mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml
  " 2>&1 | apt_progress

  echo -e " ${C}[4/4]${N} Writing startup scripts..."

  # Write start.sh inside distro via proot-distro login
  proot-distro login "$PD" --user root -- bash -c "
cat > /root/start.sh << 'STARTEOF'
#!/bin/bash
C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; W='\033[1;37m'; N='\033[0m'
TOTAL=3
START=\$(date +%s)

step() {
  local n=\$1 label=\$2
  local pct=\$(( n * 100 / TOTAL ))
  local elapsed=\$(( \$(date +%s) - START ))
  local est=0
  [ \$n -gt 0 ] && est=\$(( elapsed * (TOTAL - n) / n ))
  printf "\r \${C}Starting:\${N} \${W}%d/%d\${N}  %-28s  \${G}%d%%\${N}  EST: \${Y}%ds\${N}   " \
    "\$n" "\$TOTAL" "\$label" "\$pct" "\$est"
}
done_step() {
  printf "\r \${G}✔\${N} %-28s  \${G}done\${N}                          \n" "\$1"
}

pkill x11vnc 2>/dev/null; pkill Xvfb 2>/dev/null
sleep 1
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null

step 1 'Display server'
Xvfb :1 -screen 0 1280x800x24 +extension GLX +render -noreset &
sleep 2
export DISPLAY=:1
done_step 'Display server'

step 2 'Desktop session'
unset DBUS_SESSION_BUS_ADDRESS SESSION_MANAGER
dbus-launch --exit-with-session $SESSION &>/tmp/de.log &
sleep 3
done_step 'Desktop session'

step 3 'VNC server'
x11vnc -display :1 -rfbport $PORT -passwd '$PASS' -forever -shared -noxdamage -noxfixes -noipv6 -bg -o /tmp/vnc.log 2>/dev/null
sleep 1
if pgrep x11vnc > /dev/null; then
  done_step 'VNC server'
  echo ''
  echo '╔══════════════════════════════════════════╗'
  echo '║        ✅  DESKTOP IS RUNNING!           ║'
  echo '╠══════════════════════════════════════════╣'
  echo '║  OS     : $OS $VER'
  echo '║  Desktop: $SESSION'
  echo '║  App    : $([ "$CONN_TYPE" = "rdp" ] && echo "RD Client" || echo "AVNC")'
  echo '║  Host   : 127.0.0.1'
  echo '║  Port   : $PORT'
  echo '║  Pass   : $PASS'
  echo '╠══════════════════════════════════════════╣'
  echo '║  Stop   : bash ~/stop-vps.sh            ║'
  echo '╚══════════════════════════════════════════╝'
else
  echo '❌ x11vnc failed. Log:'
  cat /tmp/vnc.log
fi
tail -f /tmp/vnc.log
STARTEOF
chmod +x /root/start.sh
" 2>/dev/null

  # Write stop.sh inside distro via proot-distro login
  proot-distro login "$PD" --user root -- bash -c "
cat > /root/stop.sh << 'STOPEOF'
#!/bin/bash
pkill x11vnc 2>/dev/null
pkill Xvfb 2>/dev/null
pkill -f '$SESSION' 2>/dev/null
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/vnc.log /tmp/de.log 2>/dev/null
echo '✔ Desktop stopped.'
STOPEOF
chmod +x /root/stop.sh
" 2>/dev/null

  # Write Termux shortcuts
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
  echo -e "${G}${B}║  Type   : $INSTALL_TYPE                       ${N}"
  echo -e "${G}${B}╠══════════════════════════════════════════╣${N}"
  if [ "$CONN_TYPE" = "rdp" ]; then
    echo -e "${G}${B}║  App    : RD Client                      ║${N}"
  else
    echo -e "${G}${B}║  App    : AVNC                           ║${N}"
  fi
  echo -e "${G}${B}║  Host   : 127.0.0.1                      ║${N}"
  echo -e "${G}${B}║  Port   : $PORT                              ║${N}"
  echo -e "${G}${B}║  Pass   : $PASS                              ${N}"
  echo -e "${G}${B}╚══════════════════════════════════════════╝${N}"
  echo ""
  echo -e "${Y}Starting desktop now...${N}\n"

  proot-distro login "$PD" --user root -- bash /root/start.sh
}

# ─── ENTRY POINT ─────────────────────────────────────────────────────────────
main_menu
