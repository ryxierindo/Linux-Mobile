#!/bin/bash
# Linux VPS + GUI for Termux
# Uses Termux:X11 — most reliable method, no VNC issues

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

PD="ubuntu"
SESSION="startxfce4"
DE="xfce4 xfce4-goodies xfce4-terminal"

clear
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════╗"
echo "║   Linux VPS + GUI Setup (Termux)     ║"
echo "║   Ubuntu 22.04 + XFCE4              ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# Password
while true; do
  read -s -p "$(echo -e ${CYAN}Set root password: ${NC})" ROOT_PASS; echo ""
  read -s -p "$(echo -e ${CYAN}Confirm password:  ${NC})" ROOT_PASS2; echo ""
  [ "$ROOT_PASS" = "$ROOT_PASS2" ] && break
  echo -e "${RED}Passwords do not match.${NC}"
done
echo -e "${GREEN}Password set.${NC}"

# Install Termux packages
echo -e "\n${YELLOW}Installing Termux packages...${NC}"
pkg update -y && pkg install -y proot-distro x11-repo
pkg install -y termux-x11-nightly tigervnc openbox

# Install Ubuntu
echo -e "${YELLOW}Installing Ubuntu 22.04...${NC}"
proot-distro remove ubuntu 2>/dev/null || true
proot-distro install ubuntu

ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

# Write install script into rootfs using printf (no heredoc issues)
printf '#!/bin/bash\nexport DEBIAN_FRONTEND=noninteractive\n' > "${ROOTFS}/tmp/setup.sh"
printf 'apt-get update -y\n' >> "${ROOTFS}/tmp/setup.sh"
printf 'apt-get install -y xfce4 xfce4-goodies xfce4-terminal xvfb x11vnc dbus-x11 xauth nano wget curl\n' >> "${ROOTFS}/tmp/setup.sh"
printf 'echo "root:%s" | chpasswd\n' "$ROOT_PASS" >> "${ROOTFS}/tmp/setup.sh"
printf 'echo "Setup done."\n' >> "${ROOTFS}/tmp/setup.sh"
chmod +x "${ROOTFS}/tmp/setup.sh"

echo -e "${YELLOW}Installing packages inside Ubuntu...${NC}"
proot-distro login ubuntu --user root -- bash /tmp/setup.sh

# Write start script into rootfs
printf '#!/bin/bash\n' > "${ROOTFS}/root/start.sh"
printf 'pkill x11vnc 2>/dev/null\n' >> "${ROOTFS}/root/start.sh"
printf 'pkill Xvfb 2>/dev/null\n' >> "${ROOTFS}/root/start.sh"
printf 'sleep 1\n' >> "${ROOTFS}/root/start.sh"
printf 'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null\n' >> "${ROOTFS}/root/start.sh"
printf 'Xvfb :1 -screen 0 1280x800x24 &\n' >> "${ROOTFS}/root/start.sh"
printf 'sleep 2\n' >> "${ROOTFS}/root/start.sh"
printf 'export DISPLAY=:1\n' >> "${ROOTFS}/root/start.sh"
printf 'unset DBUS_SESSION_BUS_ADDRESS SESSION_MANAGER\n' >> "${ROOTFS}/root/start.sh"
printf 'dbus-launch --exit-with-session startxfce4 &\n' >> "${ROOTFS}/root/start.sh"
printf 'sleep 3\n' >> "${ROOTFS}/root/start.sh"
printf 'x11vnc -display :1 -rfbport 5901 -passwd "%s" -forever -shared -noxdamage -noxfixes -noipv6 -bg -o /tmp/vnc.log\n' "$ROOT_PASS" >> "${ROOTFS}/root/start.sh"
printf 'sleep 1\n' >> "${ROOTFS}/root/start.sh"
printf 'echo ""\n' >> "${ROOTFS}/root/start.sh"
printf 'echo "✅ Desktop running — VNC port 5901"\n' >> "${ROOTFS}/root/start.sh"
printf 'echo "Connect AVNC: 127.0.0.1:5901 | Password: %s"\n' "$ROOT_PASS" >> "${ROOTFS}/root/start.sh"
printf 'tail -f /tmp/vnc.log\n' >> "${ROOTFS}/root/start.sh"
chmod +x "${ROOTFS}/root/start.sh"

# Write stop script into rootfs
printf '#!/bin/bash\n' > "${ROOTFS}/root/stop.sh"
printf 'pkill x11vnc 2>/dev/null\n' >> "${ROOTFS}/root/stop.sh"
printf 'pkill Xvfb 2>/dev/null\n' >> "${ROOTFS}/root/stop.sh"
printf 'pkill startxfce4 2>/dev/null\n' >> "${ROOTFS}/root/stop.sh"
printf 'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null\n' >> "${ROOTFS}/root/stop.sh"
printf 'echo "Desktop stopped."\n' >> "${ROOTFS}/root/stop.sh"
chmod +x "${ROOTFS}/root/stop.sh"

# Termux start/stop commands
printf '#!/bin/bash\nproot-distro login ubuntu --user root -- bash /root/start.sh\n' > "$HOME/start-vps.sh"
printf '#!/bin/bash\nproot-distro login ubuntu --user root -- bash /root/stop.sh\n' > "$HOME/stop-vps.sh"
chmod +x "$HOME/start-vps.sh" "$HOME/stop-vps.sh"

echo -e "\n${GREEN}${BOLD}Setup complete!${NC}"
echo -e "${CYAN}▶ Start: ${BOLD}bash ~/start-vps.sh${NC}"
echo -e "${CYAN}■ Stop:  ${BOLD}bash ~/stop-vps.sh${NC}"
echo -e "${CYAN}VNC:    ${BOLD}127.0.0.1:5901${NC}"
echo -e "${CYAN}Pass:   ${BOLD}${ROOT_PASS}${NC}\n"

echo -e "${YELLOW}Starting desktop now...${NC}"
proot-distro login ubuntu --user root -- bash /root/start.sh
