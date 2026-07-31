#!/bin/bash
# Linux VPS + GUI for Termux (PRoot)
# Xvfb + x11vnc + XRDP bridge — fully working in proot
# VNC Port: 5901 | RDP Port: 3389

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════╗"
  echo "║   Linux VPS + GUI Setup (Termux)     ║"
  echo "║   Xvfb + VNC | No Android Root       ║"
  echo "╚══════════════════════════════════════╝"
  echo -e "${NC}"
}

select_distro() {
  echo -e "${YELLOW}Select Linux Distribution:${NC}\n"
  echo " 1)  Ubuntu 22.04 LTS        11)  Alpine Linux 3.17"
  echo " 2)  Ubuntu 20.04 LTS        12)  Fedora 38"
  echo " 3)  Ubuntu 18.04 LTS        13)  Fedora 37"
  echo " 4)  Debian 12 (Bookworm)    14)  Arch Linux"
  echo " 5)  Debian 11 (Bullseye)    15)  Manjaro Linux"
  echo " 6)  Debian 10 (Buster)      16)  CentOS Stream 9"
  echo " 7)  Kali Linux (Rolling)    17)  Rocky Linux 9"
  echo " 8)  Kali Linux 2023.x       18)  OpenSUSE Tumbleweed"
  echo " 9)  Parrot OS (Security)    19)  Void Linux"
  echo "10)  Alpine Linux 3.18       20)  Gentoo Linux"
  echo ""
  read -p "$(echo -e ${CYAN}Enter number [1-20]: ${NC})" c
  case $c in
    1)  DISTRO="ubuntu";  VERSION="22.04";    PD="ubuntu" ;;
    2)  DISTRO="ubuntu";  VERSION="20.04";    PD="ubuntu-oldlts" ;;
    3)  DISTRO="ubuntu";  VERSION="18.04";    PD="ubuntu-oldoldlts" ;;
    4)  DISTRO="debian";  VERSION="12";       PD="debian" ;;
    5)  DISTRO="debian";  VERSION="11";       PD="debian-oldstable" ;;
    6)  DISTRO="debian";  VERSION="10";       PD="debian-oldoldstable" ;;
    7)  DISTRO="kali";    VERSION="Rolling";  PD="kali-rolling" ;;
    8)  DISTRO="kali";    VERSION="2023.x";   PD="kali-rolling" ;;
    9)  DISTRO="debian";  VERSION="Parrot";   PD="debian" ;;
    10) DISTRO="alpine";  VERSION="3.18";     PD="alpine" ;;
    11) DISTRO="alpine";  VERSION="3.17";     PD="alpine" ;;
    12) DISTRO="fedora";  VERSION="38";       PD="fedora" ;;
    13) DISTRO="fedora";  VERSION="37";       PD="fedora" ;;
    14) DISTRO="arch";    VERSION="Latest";   PD="archlinux" ;;
    15) DISTRO="arch";    VERSION="Manjaro";  PD="archlinux" ;;
    16) DISTRO="fedora";  VERSION="CentOS 9"; PD="fedora" ;;
    17) DISTRO="fedora";  VERSION="Rocky 9";  PD="fedora" ;;
    18) DISTRO="opensuse";VERSION="Tumbleweed";PD="opensuse-tumbleweed" ;;
    19) DISTRO="void";    VERSION="Latest";   PD="void" ;;
    20) DISTRO="gentoo";  VERSION="Latest";   PD="gentoo" ;;
    *)  DISTRO="ubuntu";  VERSION="22.04";    PD="ubuntu" ;;
  esac
  echo -e "${GREEN}Selected: ${BOLD}${DISTRO} ${VERSION}${NC}"
}

select_gui() {
  echo -e "\n${YELLOW}Select Desktop Environment:${NC}\n"
  echo " 1) XFCE4      (Lightweight ✅ Recommended)"
  echo " 2) LXDE       (Very Lightweight)"
  echo " 3) LXQt       (Modern Lightweight)"
  echo " 4) MATE       (Classic)"
  echo " 5) KDE Plasma (Full-featured, Heavy)"
  echo " 6) GNOME      (Modern, Heavy)"
  echo " 7) Openbox    (Minimal WM)"
  echo " 8) i3         (Tiling WM)"
  echo ""
  read -p "$(echo -e ${CYAN}Enter number [1-8]: ${NC})" g
  case $g in
    1) DE="xfce4 xfce4-goodies xfce4-terminal"; SESSION="startxfce4" ;;
    2) DE="lxde";                                SESSION="startlxde" ;;
    3) DE="lxqt";                                SESSION="startlxqt" ;;
    4) DE="mate-desktop-environment";            SESSION="mate-session" ;;
    5) DE="kde-plasma-desktop";                  SESSION="startplasma-x11" ;;
    6) DE="gnome";                               SESSION="gnome-session" ;;
    7) DE="openbox obconf";                      SESSION="openbox-session" ;;
    8) DE="i3 i3status dmenu";                   SESSION="i3" ;;
    *) DE="xfce4 xfce4-goodies xfce4-terminal"; SESSION="startxfce4" ;;
  esac
  echo -e "${GREEN}Selected: ${BOLD}${SESSION}${NC}"
}

set_password() {
  echo ""
  while true; do
    read -s -p "$(echo -e ${CYAN}Set root password: ${NC})" ROOT_PASS; echo ""
    read -s -p "$(echo -e ${CYAN}Confirm password:  ${NC})" ROOT_PASS2; echo ""
    [ "$ROOT_PASS" = "$ROOT_PASS2" ] && break
    echo -e "${RED}Passwords do not match. Try again.${NC}"
  done
  echo -e "${GREEN}Password confirmed.${NC}"
}

install_distro() {
  echo -e "\n${YELLOW}Installing proot-distro...${NC}"
  pkg update -y && pkg install -y proot-distro wget curl
  proot-distro remove "$PD" 2>/dev/null || true
  echo -e "${YELLOW}Installing ${DISTRO} ${VERSION}...${NC}"
  proot-distro install "$PD" || {
    echo -e "${RED}Failed. Falling back to Ubuntu 22.04${NC}"
    PD="ubuntu"; DISTRO="ubuntu"; VERSION="22.04"
    proot-distro install ubuntu
  }
}

setup_inside() {
  echo -e "\n${YELLOW}Setting up desktop inside ${DISTRO}...${NC}"

  cat > /tmp/inner.sh << HEREDOC
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo ""
echo ">>> [1/5] Updating system..."
apt-get update -y && apt-get upgrade -y

echo ""
echo ">>> [2/5] Installing desktop + VNC tools..."
apt-get install -y \
  ${DE} \
  xvfb \
  x11vnc \
  dbus-x11 \
  x11-xserver-utils \
  xauth \
  xterm \
  fonts-noto \
  papirus-icon-theme \
  arc-theme \
  nano wget curl git 2>/dev/null

# fallback if some packages missing
apt-get install -y ${DE} xvfb x11vnc dbus-x11 xauth nano wget curl 2>/dev/null || true

echo ""
echo ">>> [3/5] Setting root password..."
echo "root:${ROOT_PASS}" | chpasswd

echo ""
echo ">>> [4/5] Configuring desktop theme (Arc-Dark + Papirus)..."
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml

cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'EOF'
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
EOF

cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Arc-Dark"/>
    <property name="title_font" type="string" value="Noto Sans Bold 9"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="button_layout" type="string" value="O|HMC"/>
  </property>
</channel>
EOF

echo ""
echo ">>> [5/5] Creating startup script..."

# Main VNC start script inside distro
cat > /root/start-desktop.sh << 'EOF'
#!/bin/bash
# Kill old sessions
pkill x11vnc 2>/dev/null
pkill Xvfb 2>/dev/null
sleep 1
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null

# Start virtual display
Xvfb :1 -screen 0 1280x720x24 &
XVFB_PID=\$!
sleep 2

# Start desktop session on display :1
export DISPLAY=:1
unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
dbus-launch --exit-with-session ${SESSION} &
sleep 3

# Start x11vnc — shares the Xvfb display over VNC port 5901
x11vnc -display :1 \
  -rfbport 5901 \
  -passwd "${ROOT_PASS}" \
  -forever \
  -shared \
  -noxdamage \
  -noxfixes \
  -bg \
  -o /var/log/x11vnc.log

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         ✅ DESKTOP IS RUNNING!           ║"
echo "╠══════════════════════════════════════════╣"
echo "║  VNC Port   : 5901                       ║"
echo "║  Password   : (your set password)        ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Open AVNC app:                          ║"
echo "║  Host: 127.0.0.1   Port: 5901            ║"
echo "╚══════════════════════════════════════════╝"
tail -f /var/log/x11vnc.log
EOF
chmod +x /root/start-desktop.sh

echo ""
echo ">>> Starting desktop now..."
bash /root/start-desktop.sh
HEREDOC

  chmod +x /tmp/inner.sh
  ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/${PD}"
  cp /tmp/inner.sh "${ROOTFS}/tmp/inner.sh" 2>/dev/null || true
  proot-distro login "$PD" --user root -- bash /tmp/inner.sh
}

create_start_script() {
  cat > "$HOME/start-vps.sh" << STARTEOF
#!/bin/bash
echo "Starting ${DISTRO} ${VERSION} + ${SESSION}..."
proot-distro login ${PD} --user root -- bash /root/start-desktop.sh
STARTEOF
  chmod +x "$HOME/start-vps.sh"
  echo -e "${GREEN}Restart script saved: ${BOLD}bash ~/start-vps.sh${NC}"
}

# ── MAIN ─────────────────────────────────────────────────────────────────────
banner
select_distro
select_gui
set_password
install_distro
setup_inside
create_start_script

echo -e "\n${GREEN}${BOLD}Done!${NC}"
echo -e "${CYAN}Restart anytime: ${BOLD}bash ~/start-vps.sh${NC}"
echo -e "${CYAN}Connect AVNC → ${BOLD}127.0.0.1:5901${NC}"
echo -e "${CYAN}Password: ${BOLD}your set password${NC}\n"
