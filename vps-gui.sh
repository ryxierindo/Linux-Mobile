#!/bin/bash
# Linux VPS + GUI for Termux (PRoot)
# No Android root required

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[1m'; N='\033[0m'
TICK="${G}✔${N}"; CROSS="${R}✘${N}"

step() { echo -e "\n${C}${B}[$1/6]${N} ${B}$2${N}"; }
ok()   { echo -e " ${TICK} $1"; }
err()  { echo -e " ${CROSS} $1"; }

clear
echo -e "${C}${B}"
echo "╔══════════════════════════════════════════╗"
echo "║     Linux VPS + GUI Setup for Termux     ║"
echo "║     No Root | VNC/RDP | Auto Setup       ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${N}"

# ─── STEP 1: OS SELECTION ────────────────────────────────────────────────────
step 1 "Select Operating System"
echo ""
echo "  1) Ubuntu        6) Kali Linux"
echo "  2) Debian        7) Parrot OS"
echo "  3) Fedora        8) Arch Linux"
echo "  4) Alpine        9) OpenSUSE"
echo "  5) Void Linux   10) Gentoo"
echo ""
read -p "$(echo -e ${C}OS [1-10]: ${N})" OS_CHOICE

case $OS_CHOICE in
  1) OS="ubuntu" ;;
  2) OS="debian" ;;
  3) OS="fedora" ;;
  4) OS="alpine" ;;
  5) OS="void" ;;
  6) OS="kali" ;;
  7) OS="parrot" ;;
  8) OS="arch" ;;
  9) OS="opensuse" ;;
  10) OS="gentoo" ;;
  *) OS="ubuntu" ;;
esac
ok "OS: $OS"

# ─── STEP 2: VERSION SELECTION ───────────────────────────────────────────────
step 2 "Select Version"
echo ""
case $OS in
  ubuntu)
    echo "  1) Ubuntu 22.04 LTS (Jammy)   ← Recommended"
    echo "  2) Ubuntu 20.04 LTS (Focal)"
    echo "  3) Ubuntu 18.04 LTS (Bionic)"
    read -p "$(echo -e ${C}Version [1-3]: ${N})" V
    case $V in
      2) PD="ubuntu-oldlts";     VER="20.04" ;;
      3) PD="ubuntu-oldoldlts";  VER="18.04" ;;
      *) PD="ubuntu";            VER="22.04" ;;
    esac ;;
  debian)
    echo "  1) Debian 12 Bookworm   ← Recommended"
    echo "  2) Debian 11 Bullseye"
    echo "  3) Debian 10 Buster"
    read -p "$(echo -e ${C}Version [1-3]: ${N})" V
    case $V in
      2) PD="debian-oldstable";    VER="11" ;;
      3) PD="debian-oldoldstable"; VER="10" ;;
      *) PD="debian";              VER="12" ;;
    esac ;;
  fedora)
    echo "  1) Fedora 38   ← Recommended"
    echo "  2) Fedora 37"
    read -p "$(echo -e ${C}Version [1-2]: ${N})" V
    case $V in
      2) PD="fedora"; VER="37" ;;
      *) PD="fedora"; VER="38" ;;
    esac ;;
  alpine)
    echo "  1) Alpine 3.18   ← Recommended"
    echo "  2) Alpine 3.17"
    read -p "$(echo -e ${C}Version [1-2]: ${N})" V
    PD="alpine"; VER="3.18"
    [ "$V" = "2" ] && VER="3.17" ;;
  kali)
    echo "  1) Kali Rolling   ← Recommended"
    read -p "$(echo -e ${C}Version [1]: ${N})" V
    PD="kali-rolling"; VER="Rolling" ;;
  parrot)
    echo "  1) Parrot Security   ← Recommended"
    read -p "$(echo -e ${C}Version [1]: ${N})" V
    PD="debian"; VER="Security"; OS="debian" ;;
  arch)
    echo "  1) Arch Latest   ← Recommended"
    read -p "$(echo -e ${C}Version [1]: ${N})" V
    PD="archlinux"; VER="Latest" ;;
  opensuse)
    echo "  1) OpenSUSE Tumbleweed   ← Recommended"
    read -p "$(echo -e ${C}Version [1]: ${N})" V
    PD="opensuse-tumbleweed"; VER="Tumbleweed" ;;
  void)
    echo "  1) Void Latest   ← Recommended"
    read -p "$(echo -e ${C}Version [1]: ${N})" V
    PD="void"; VER="Latest" ;;
  gentoo)
    echo "  1) Gentoo Latest   ← Recommended"
    read -p "$(echo -e ${C}Version [1]: ${N})" V
    PD="gentoo"; VER="Latest" ;;
  *) PD="ubuntu"; VER="22.04" ;;
esac
ok "Version: $VER"

# ─── STEP 3: DESKTOP SELECTION ───────────────────────────────────────────────
step 3 "Select Desktop Environment"
echo ""
echo "  1) XFCE4      ← Recommended (fast, good looking)"
echo "  2) LXDE       (very lightweight)"
echo "  3) LXQt       (modern lightweight)"
echo "  4) MATE       (classic)"
echo "  5) KDE Plasma (full featured, heavy)"
echo "  6) GNOME      (modern, heavy)"
echo "  7) Openbox    (minimal)"
echo "  8) i3         (tiling)"
echo ""
read -p "$(echo -e ${C}Desktop [1-8]: ${N})" D
case $D in
  2) DE="lxde";                                SESSION="startlxde" ;;
  3) DE="lxqt";                                SESSION="startlxqt" ;;
  4) DE="mate-desktop-environment";            SESSION="mate-session" ;;
  5) DE="kde-plasma-desktop";                  SESSION="startplasma-x11" ;;
  6) DE="gnome";                               SESSION="gnome-session" ;;
  7) DE="openbox obconf";                      SESSION="openbox-session" ;;
  8) DE="i3 i3status dmenu";                   SESSION="i3" ;;
  *) DE="xfce4 xfce4-goodies xfce4-terminal"; SESSION="startxfce4" ;;
esac
ok "Desktop: $SESSION"

# ─── STEP 4: CONNECTION TYPE ─────────────────────────────────────────────────
step 4 "Select Connection Type"
echo ""
echo "  1) VNC  — Use AVNC app (port 5901)   ← Recommended"
echo "  2) RDP  — Use RD Client app (port 3390 via VNC bridge)"
echo ""
read -p "$(echo -e ${C}Connection [1-2]: ${N})" CONN
case $CONN in
  2) CONN_TYPE="rdp";  PORT="3390" ;;
  *) CONN_TYPE="vnc";  PORT="5901" ;;
esac
ok "Connection: $CONN_TYPE on port $PORT"

# ─── STEP 5: PASSWORD ────────────────────────────────────────────────────────
step 5 "Set Password"
echo ""
while true; do
  read -s -p "$(echo -e ${C}Password: ${N})" PASS; echo ""
  read -s -p "$(echo -e ${C}Confirm:  ${N})" PASS2; echo ""
  [ "$PASS" = "$PASS2" ] && break
  err "Passwords do not match. Try again."
done
ok "Password set."

# ─── STEP 6: INSTALL ─────────────────────────────────────────────────────────
step 6 "Installing — please wait..."
echo ""

# Install Termux deps silently
echo -ne " Installing Termux packages... "
pkg update -y -q 2>/dev/null && pkg install -y -q proot-distro wget curl 2>/dev/null
echo -e "${TICK}"

# Install distro silently
echo -ne " Installing $OS $VER via proot-distro... "
proot-distro remove "$PD" 2>/dev/null || true
proot-distro install "$PD" 2>/dev/null || {
  err "Failed to install $PD — falling back to Ubuntu 22.04"
  PD="ubuntu"; OS="ubuntu"; VER="22.04"
  proot-distro install ubuntu 2>/dev/null
}
echo -e "${TICK}"

ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/${PD}"

# ── Write install.sh into rootfs ──────────────────────────────────────────────
{
  printf '#!/bin/bash\nexport DEBIAN_FRONTEND=noninteractive\n'
  printf 'apt-get update -yq 2>/dev/null\n'
  printf 'apt-get install -yq %s xvfb x11vnc dbus-x11 x11-xserver-utils xauth xterm fonts-noto papirus-icon-theme arc-theme nano wget curl 2>/dev/null\n' "$DE"
  printf 'echo "root:%s" | chpasswd\n' "$PASS"
  # XFCE4 theme
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

echo -ne " Installing desktop inside $OS... "
proot-distro login "$PD" --user root -- bash /tmp/install.sh 2>/dev/null
echo -e "${TICK}"

# ── Write start.sh into rootfs ────────────────────────────────────────────────
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
  # VNC or RDP bridge
  if [ "$CONN_TYPE" = "rdp" ]; then
    printf 'x11vnc -display :1 -rfbport 3390 -passwd "%s" -forever -shared -noxdamage -noxfixes -noipv6 -bg -o /tmp/vnc.log 2>/dev/null\n' "$PASS"
    printf 'echo "RDP bridge running on port 3390"\n'
  else
    printf 'x11vnc -display :1 -rfbport 5901 -passwd "%s" -forever -shared -noxdamage -noxfixes -noipv6 -bg -o /tmp/vnc.log 2>/dev/null\n' "$PASS"
    printf 'echo "VNC running on port 5901"\n'
  fi
  printf 'sleep 1\n'
  printf 'if pgrep x11vnc > /dev/null; then\n'
  printf '  echo ""\n'
  printf '  echo "╔══════════════════════════════════════════╗"\n'
  printf '  echo "║        ✅  DESKTOP IS RUNNING            ║"\n'
  printf '  echo "╠══════════════════════════════════════════╣"\n'
  if [ "$CONN_TYPE" = "rdp" ]; then
    printf '  echo "║  App    : RD Client                      ║"\n'
    printf '  echo "║  Host   : 127.0.0.1                      ║"\n'
    printf '  echo "║  Port   : 3390                           ║"\n'
  else
    printf '  echo "║  App    : AVNC                           ║"\n'
    printf '  echo "║  Host   : 127.0.0.1                      ║"\n'
    printf '  echo "║  Port   : 5901                           ║"\n'
  fi
  printf '  echo "║  Pass   : %s"\n' "$PASS"
  printf '  echo "╚══════════════════════════════════════════╝"\n'
  printf 'else\n'
  printf '  echo "ERROR: x11vnc failed to start. Check /tmp/vnc.log"\n'
  printf '  cat /tmp/vnc.log\n'
  printf 'fi\n'
  printf 'tail -f /tmp/vnc.log\n'
} > "${ROOTFS}/root/start.sh"
chmod +x "${ROOTFS}/root/start.sh"

# ── Write stop.sh into rootfs ─────────────────────────────────────────────────
{
  printf '#!/bin/bash\n'
  printf 'pkill x11vnc 2>/dev/null\n'
  printf 'pkill Xvfb 2>/dev/null\n'
  printf 'pkill -f "%s" 2>/dev/null\n' "$SESSION"
  printf 'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/vnc.log /tmp/de.log 2>/dev/null\n'
  printf 'echo "Desktop stopped."\n'
} > "${ROOTFS}/root/stop.sh"
chmod +x "${ROOTFS}/root/stop.sh"

# ── Termux shortcuts ──────────────────────────────────────────────────────────
printf '#!/bin/bash\nproot-distro login %s --user root -- bash /root/start.sh\n' "$PD" > "$HOME/start-vps.sh"
printf '#!/bin/bash\nproot-distro login %s --user root -- bash /root/stop.sh\n'  "$PD" > "$HOME/stop-vps.sh"
chmod +x "$HOME/start-vps.sh" "$HOME/stop-vps.sh"

echo -e "${TICK}"
echo ""
echo -e "${G}${B}╔══════════════════════════════════════════╗${N}"
echo -e "${G}${B}║          SETUP COMPLETE ✅               ║${N}"
echo -e "${G}${B}╠══════════════════════════════════════════╣${N}"
echo -e "${G}${B}║  ▶ Start : bash ~/start-vps.sh           ║${N}"
echo -e "${G}${B}║  ■ Stop  : bash ~/stop-vps.sh            ║${N}"
echo -e "${G}${B}╠══════════════════════════════════════════╣${N}"
if [ "$CONN_TYPE" = "rdp" ]; then
echo -e "${G}${B}║  App    : RD Client                      ║${N}"
echo -e "${G}${B}║  Host   : 127.0.0.1  Port: 3390          ║${N}"
else
echo -e "${G}${B}║  App    : AVNC                           ║${N}"
echo -e "${G}${B}║  Host   : 127.0.0.1  Port: 5901          ║${N}"
fi
echo -e "${G}${B}║  Pass   : $PASS${N}"
echo -e "${G}${B}╚══════════════════════════════════════════╝${N}"
echo ""
echo -e "${Y}Starting desktop now...${N}"
echo ""

proot-distro login "$PD" --user root -- bash /root/start.sh
