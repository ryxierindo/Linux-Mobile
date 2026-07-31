#!/bin/bash
# Linux VPS + GUI + XRDP Setup for Termux (PRoot - No Android Root Needed)
# RDP User: root | Ports: 19132-25565 TCP/UDP

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════╗"
  echo "║   Linux VPS + GUI Setup (Termux)     ║"
  echo "║   No Android Root | XRDP Port 3389   ║"
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
  read -p "$(echo -e ${CYAN}Enter number [1-20]: ${NC})" DISTRO_CHOICE

  case $DISTRO_CHOICE in
    1)  DISTRO="ubuntu";  VERSION="22.04";      PD_NAME="ubuntu" ;;
    2)  DISTRO="ubuntu";  VERSION="20.04";      PD_NAME="ubuntu-oldlts" ;;
    3)  DISTRO="ubuntu";  VERSION="18.04";      PD_NAME="ubuntu-oldoldlts" ;;
    4)  DISTRO="debian";  VERSION="12";         PD_NAME="debian" ;;
    5)  DISTRO="debian";  VERSION="11";         PD_NAME="debian-oldstable" ;;
    6)  DISTRO="debian";  VERSION="10";         PD_NAME="debian-oldoldstable" ;;
    7)  DISTRO="kali";    VERSION="Rolling";    PD_NAME="kali-rolling" ;;
    8)  DISTRO="kali";    VERSION="2023.x";     PD_NAME="kali-rolling" ;;
    9)  DISTRO="parrot";  VERSION="Security";   PD_NAME="debian"; echo -e "${YELLOW}Note: Parrot uses Debian base${NC}" ;;
    10) DISTRO="alpine";  VERSION="3.18";       PD_NAME="alpine" ;;
    11) DISTRO="alpine";  VERSION="3.17";       PD_NAME="alpine" ;;
    12) DISTRO="fedora";  VERSION="38";         PD_NAME="fedora" ;;
    13) DISTRO="fedora";  VERSION="37";         PD_NAME="fedora" ;;
    14) DISTRO="arch";    VERSION="Latest";     PD_NAME="archlinux" ;;
    15) DISTRO="manjaro"; VERSION="Latest";     PD_NAME="archlinux"; echo -e "${YELLOW}Note: Manjaro uses Arch base${NC}" ;;
    16) DISTRO="centos";  VERSION="Stream 9";   PD_NAME="fedora"; echo -e "${YELLOW}Note: CentOS uses Fedora base${NC}" ;;
    17) DISTRO="rocky";   VERSION="9";          PD_NAME="fedora"; echo -e "${YELLOW}Note: Rocky uses Fedora base${NC}" ;;
    18) DISTRO="opensuse";VERSION="Tumbleweed"; PD_NAME="opensuse-tumbleweed" ;;
    19) DISTRO="void";    VERSION="Latest";     PD_NAME="void" ;;
    20) DISTRO="gentoo";  VERSION="Latest";     PD_NAME="gentoo" ;;
    *)  echo -e "${RED}Invalid. Defaulting to Ubuntu 22.04${NC}"; DISTRO="ubuntu"; VERSION="22.04"; PD_NAME="ubuntu" ;;
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
  read -p "$(echo -e ${CYAN}Enter number [1-8]: ${NC})" GUI_CHOICE

  case $GUI_CHOICE in
    1) DE_PKG="xfce4 xfce4-goodies"; SESSION="startxfce4" ;;
    2) DE_PKG="lxde";                 SESSION="startlxde" ;;
    3) DE_PKG="lxqt";                 SESSION="startlxqt" ;;
    4) DE_PKG="mate-desktop-environment"; SESSION="mate-session" ;;
    5) DE_PKG="kde-plasma-desktop";   SESSION="startplasma-x11" ;;
    6) DE_PKG="gnome";                SESSION="gnome-session" ;;
    7) DE_PKG="openbox";              SESSION="openbox-session" ;;
    8) DE_PKG="i3";                   SESSION="i3" ;;
    *) echo -e "${RED}Defaulting to XFCE4${NC}"; DE_PKG="xfce4 xfce4-goodies"; SESSION="startxfce4" ;;
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

get_pkg_install() {
  # Returns the install command for the distro
  case $DISTRO in
    ubuntu|debian|kali|parrot)
      echo "apt-get update -y && apt-get install -y"
      ;;
    alpine)
      echo "apk update && apk add"
      ;;
    fedora|centos|rocky)
      echo "dnf update -y && dnf install -y"
      ;;
    arch|manjaro)
      echo "pacman -Syu --noconfirm && pacman -S --noconfirm"
      ;;
    opensuse)
      echo "zypper --non-interactive refresh && zypper --non-interactive install"
      ;;
    void)
      echo "xbps-install -Syu && xbps-install -y"
      ;;
    *)
      echo "apt-get update -y && apt-get install -y"
      ;;
  esac
}

get_de_packages() {
  # Alpine and pacman use different package names
  case $DISTRO in
    alpine)
      case $SESSION in
        startxfce4)    echo "xfce4 xfce4-goodies" ;;
        startlxde)     echo "lxde" ;;
        startlxqt)     echo "lxqt" ;;
        mate-session)  echo "mate-desktop" ;;
        startplasma-x11) echo "plasma-desktop" ;;
        gnome-session) echo "gnome" ;;
        openbox-session) echo "openbox" ;;
        i3)            echo "i3wm" ;;
        *)             echo "xfce4" ;;
      esac
      ;;
    arch|manjaro)
      case $SESSION in
        startxfce4)    echo "xfce4 xfce4-goodies" ;;
        startlxde)     echo "lxde" ;;
        startlxqt)     echo "lxqt" ;;
        mate-session)  echo "mate mate-extra" ;;
        startplasma-x11) echo "plasma kde-applications" ;;
        gnome-session) echo "gnome gnome-extra" ;;
        openbox-session) echo "openbox" ;;
        i3)            echo "i3" ;;
        *)             echo "xfce4 xfce4-goodies" ;;
      esac
      ;;
    *)
      echo "$DE_PKG"
      ;;
  esac
}

install_distro() {
  echo -e "\n${YELLOW}Installing proot-distro...${NC}"
  pkg update -y && pkg install -y proot-distro wget curl

  # Remove existing install to avoid conflicts
  proot-distro remove "$PD_NAME" 2>/dev/null || true

  echo -e "${YELLOW}Installing ${DISTRO} ${VERSION} via proot-distro...${NC}"
  proot-distro install "$PD_NAME" || {
    echo -e "${RED}Failed to install ${PD_NAME}. Falling back to ubuntu.${NC}"
    PD_NAME="ubuntu"; DISTRO="ubuntu"; VERSION="22.04"
    proot-distro install ubuntu
  }
}

setup_inside_distro() {
  local PKG_INSTALL
  PKG_INSTALL=$(get_pkg_install)
  local DE_PACKAGES
  DE_PACKAGES=$(get_de_packages)

  echo -e "\n${YELLOW}Configuring GUI + XRDP inside ${DISTRO}...${NC}"

  # Write the inner setup script — use 'NOEXPAND' to prevent premature expansion
  # Variables we WANT expanded now: ROOT_PASS, SESSION, PKG_INSTALL, DE_PACKAGES
  # Variables we do NOT want expanded: shell vars inside the heredoc used at runtime
  cat > /tmp/vps_inner_setup.sh << HEREDOC
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
set -e

echo ">>> [1/5] Installing packages..."
${PKG_INSTALL} ${DE_PACKAGES} xrdp dbus-x11 x11-xserver-utils xorgxrdp nano wget curl 2>/dev/null || \
${PKG_INSTALL} ${DE_PACKAGES} xrdp dbus nano wget curl

echo ">>> [2/5] Setting root password..."
echo "root:${ROOT_PASS}" | chpasswd

echo ">>> [3/5] Configuring XRDP for root login..."

# Allow root login in xrdp sesman
mkdir -p /etc/xrdp
if [ -f /etc/xrdp/sesman.ini ]; then
  sed -i 's/^AllowRootLogin=.*/AllowRootLogin=true/' /etc/xrdp/sesman.ini
  grep -q "AllowRootLogin" /etc/xrdp/sesman.ini || echo "AllowRootLogin=true" >> /etc/xrdp/sesman.ini
fi

# Set xsession for root — no DISPLAY export, xrdp handles it
cat > /root/.xsession << 'XEOF'
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
exec ${SESSION}
XEOF
chmod +x /root/.xsession

# startwm.sh — xrdp calls this to launch the session
cat > /etc/xrdp/startwm.sh << 'WEOF'
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
exec ${SESSION}
WEOF
chmod +x /etc/xrdp/startwm.sh

# xrdp.ini — ensure port 3389, enable root
if [ -f /etc/xrdp/xrdp.ini ]; then
  sed -i 's/^port=.*/port=3389/' /etc/xrdp/xrdp.ini
  sed -i 's/^#port=.*/port=3389/' /etc/xrdp/xrdp.ini
fi

echo ">>> [4/5] Opening ports 19132-25565..."
mkdir -p /var/run/xrdp /var/log/xrdp
# iptables may not be available in proot — that's fine, proot doesn't filter ports
which iptables > /dev/null 2>&1 && {
  iptables -A INPUT -p tcp --dport 19132:25565 -j ACCEPT 2>/dev/null || true
  iptables -A INPUT -p udp --dport 19132:25565 -j ACCEPT 2>/dev/null || true
} || echo "iptables unavailable — ports are open by default in proot"

echo ">>> [5/5] Starting XRDP..."
# Kill any existing xrdp processes
pkill xrdp 2>/dev/null; pkill xrdp-sesman 2>/dev/null; sleep 1
rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid 2>/dev/null

xrdp-sesman && sleep 1 && xrdp
sleep 2

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           VPS SETUP COMPLETE             ║"
echo "╠══════════════════════════════════════════╣"
echo "║  RDP Port   : 3389                       ║"
echo "║  Username   : root                       ║"
echo "║  Password   : (your set password)        ║"
echo "║  Ports Open : 19132-25565 TCP/UDP        ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Connect: localhost:3389                 ║"
echo "║  Or: <your-device-ip>:3389               ║"
echo "╚══════════════════════════════════════════╝"
HEREDOC

  chmod +x /tmp/vps_inner_setup.sh

  # Copy script into the proot rootfs
  local ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/${PD_NAME}"
  cp /tmp/vps_inner_setup.sh "${ROOTFS}/tmp/vps_inner_setup.sh" 2>/dev/null || true

  proot-distro login "$PD_NAME" --user root -- bash /tmp/vps_inner_setup.sh
}

create_start_script() {
  cat > "$HOME/start-vps.sh" << STARTEOF
#!/bin/bash
# Restart VPS GUI anytime — run: bash ~/start-vps.sh
echo "Starting ${DISTRO} ${VERSION} + ${SESSION} via XRDP..."
proot-distro login ${PD_NAME} --user root -- bash -c "
  pkill xrdp 2>/dev/null; pkill xrdp-sesman 2>/dev/null; sleep 1
  rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid 2>/dev/null
  xrdp-sesman && sleep 1 && xrdp
  echo 'XRDP running on port 3389 | User: root'
  tail -f /dev/null
"
STARTEOF
  chmod +x "$HOME/start-vps.sh"
  echo -e "${GREEN}Restart script saved: ${BOLD}~/start-vps.sh${NC}"
}

# ── MAIN ─────────────────────────────────────────────────────────────────────
banner
select_distro
select_gui
set_password
install_distro
setup_inside_distro
create_start_script

echo -e "\n${GREEN}${BOLD}Done! To restart VPS anytime:${NC}"
echo -e "${CYAN}  bash ~/start-vps.sh${NC}"
echo -e "${CYAN}  RDP → localhost:3389 | User: root${NC}\n"
