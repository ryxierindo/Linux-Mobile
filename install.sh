#!/bin/bash

# TermoOS Setup Script
# Based on Debian via proot-distro

export TERM=xterm-256color

echo "Checking required Termux packages..."

if ! command -v dialog &> /dev/null || ! command -v proot-distro &> /dev/null; then
    echo "First-time setup: Downloading dependencies..."
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg install dialog proot-distro bc ncurses-utils wget curl -y -o Dpkg::Options::="--force-confold"
else
    echo "Dependencies already installed. Starting Setup..."
    sleep 1
fi

# ==========================================
# HARDWARE PROFILER (Calculates Speed Factor)
# ==========================================
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
CORES=$(nproc 2>/dev/null || echo 4)

SPEED_FACTOR=1.0
if [ "$TOTAL_RAM" -lt 4000 ]; then
    SPEED_FACTOR=2.0
    REC_TYPE="Minimal"
elif [ "$TOTAL_RAM" -lt 6000 ]; then
    SPEED_FACTOR=1.5
    REC_TYPE="Simplified"
else
    SPEED_FACTOR=1.0
    REC_TYPE="Full"
fi

dialog --backtitle "TermoOS Installation" --title "Welcome" --msgbox "Welcome to the TermoOS Setup!\n\nSystem will check your specs and guide you through the setup.\n\nHardware Profile:\nRAM: ${TOTAL_RAM}MB\nCORES: ${CORES}\n\nTIP: If arrows freeze, use NUMBER KEYS (1, 2, 3) to select options." 15 50

DE_CHOICE=$(dialog --clear --backtitle "TermoOS Setup" --title "Desktop Environment" \
--menu "Press a NUMBER to choose your Desktop Environment:" 15 55 5 \
"1" "GNOME (Very Heavy)" \
"2" "KDE Plasma (Heavy)" \
"3" "XFCE (Medium/Recommended)" \
"4" "LXQt (Light)" \
"5" "Openbox (Very Light)" \
3>&1 1>&2 2>&3)

CONN_CHOICE=$(dialog --clear --backtitle "TermoOS Setup" --title "Remote Protocol" \
--menu "Press a NUMBER to select connection type:" 12 55 3 \
"1" "VNC (Default, Best for Android)" \
"2" "RDP (Windows Remote Desktop)" \
"3" "VPS (SSH only, No GUI)" \
3>&1 1>&2 2>&3)

TYPE_CHOICE=$(dialog --clear --backtitle "TermoOS Setup" --title "Installation Type" \
--menu "Select Installation Type\n(Auto-Recommended for your device: $REC_TYPE)" 15 60 3 \
"Full" "All modules, heavy, longest install time" \
"Simplified" "Necessary tools + Firefox (Medium)" \
"Minimal" "Only base OS and DE to run (Fastest)" \
3>&1 1>&2 2>&3)

USER_NAME=$(dialog --clear --backtitle "TermoOS Setup" --title "User Setup" --inputbox "Enter a new username for TermoOS:" 8 40 3>&1 1>&2 2>&3)
USER_PASS=$(dialog --clear --backtitle "TermoOS Setup" --title "User Setup" --passwordbox "Enter a password for VNC/System:" 8 40 3>&1 1>&2 2>&3)

dialog --clear --title "Ready" --yesno "Configuration complete. Begin installation?" 8 40
if [ $? -ne 0 ]; then
    clear; echo "Installation aborted."; exit;
fi

# ==========================================
# Map the DE Name for the OS Config
# ==========================================
DE_NAME="XFCE"
if [ "$DE_CHOICE" == "1" ]; then DE_NAME="GNOME"; fi
if [ "$DE_CHOICE" == "2" ]; then DE_NAME="KDE Plasma"; fi
if [ "$DE_CHOICE" == "4" ]; then DE_NAME="LXQt"; fi
if [ "$DE_CHOICE" == "5" ]; then DE_NAME="Openbox"; fi

# ==========================================
# The Master GUI Progress Bar Function
# ==========================================
GUI_ENGINE=$(cat << EOF_ENGINE
START_TIME=\$(date +%s)
SPEED_FACTOR=$SPEED_FACTOR

show_gui() {
    local STEP=\$1
    local TOTAL=\$2
    local DESC=\$3
    local TITLE=\$4
    local BASE_EST_MINS=\$5
    
    local CURRENT_TIME=\$(date +%s)
    local ELAPSED_SECS=\$((CURRENT_TIME - START_TIME))
    local ELAPSED_MINS=\$((ELAPSED_SECS / 60))
    local PERCENT=\$((STEP * 100 / TOTAL))
    
    local PREDICTED_EST=\$(echo "\$BASE_EST_MINS * \$SPEED_FACTOR" | bc | awk '{print int(\$1+0.5)}')

    echo "\$PERCENT" | dialog --title "\$TITLE" --backtitle "TermoOS Setup" \
    --gauge "Module \$STEP/\$TOTAL: \$DESC\n\n[ Detecting EST based on Hardware & Speed... ]" 10 45
    sleep 1.5

    echo "\$PERCENT" | dialog --title "\$TITLE" --backtitle "TermoOS Setup" \
    --gauge "Module \$STEP/\$TOTAL: \$DESC\n\nEST : ~\$PREDICTED_EST min     ELAPSED : \$ELAPSED_MINS min" 10 45
}
EOF_ENGINE
)

eval "$GUI_ENGINE"

# ==========================================
# Optimized Installation Logic
# ==========================================
TOTAL_MODULES=8

ENV_VARS="export DEBIAN_FRONTEND=noninteractive; export DEBCONF_NONINTERACTIVE_SEEN=true"
APT_OPTS="-yq --no-install-recommends -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" -o Dpkg::Options::=\"--force-unsafe-io\""

show_gui 1 $TOTAL_MODULES "proot (linux base)" "Installing TermoOS" 2
proot-distro install debian > /dev/null 2>&1

show_gui 2 $TOTAL_MODULES "apt-get (system updates)" "Installing TermoOS" 3
proot-distro login debian -- bash -c "$ENV_VARS; apt-get update -y && apt-get upgrade $APT_OPTS" > /dev/null 2>&1

show_gui 3 $TOTAL_MODULES "desktop-environment\n(Extracting files, DO NOT CLOSE)" "Installing TermoOS" 10
if [ "$DE_CHOICE" == "1" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS gnome-core" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "2" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS kde-plasma-desktop" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "3" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS xfce4 xfce4-goodies" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "4" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS lxqt-core lxterminal" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "5" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS openbox obconf" > /dev/null 2>&1
fi

show_gui 4 $TOTAL_MODULES "tigervnc (remote display)" "Installing TermoOS" 3
proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tigervnc-standalone-server dbus-x11" > /dev/null 2>&1

show_gui 5 $TOTAL_MODULES "extras (apps & tools)" "Installing TermoOS" 4
if [ "$TYPE_CHOICE" == "Minimal" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS nano dialog curl sudo xterm" > /dev/null 2>&1
elif [ "$TYPE_CHOICE" == "Simplified" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS firefox-esr wget nano dialog curl sudo xterm" > /dev/null 2>&1
else
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS firefox-esr wget nano dialog curl sudo xterm htop neofetch" > /dev/null 2>&1
fi

show_gui 6 $TOTAL_MODULES "vnc-config (startup scripts)" "Installing TermoOS" 1

# Write System Configs
proot-distro login debian -- bash -c "echo 'OS_TYPE=\"$TYPE_CHOICE\"' > /etc/termo-os.conf"
proot-distro login debian -- bash -c "echo 'OS_DE=\"$DE_NAME\"' >> /etc/termo-os.conf"
proot-distro login debian -- bash -c "echo 'VNC_USER=\"$USER_NAME\"' > /etc/termo-vnc.conf"
proot-distro login debian -- bash -c "echo 'VNC_PORT=\"5901\"' >> /etc/termo-vnc.conf"
proot-distro login debian -- bash -c "echo 'VNC_DISPLAY=\":1\"' >> /etc/termo-vnc.conf"
proot-distro login debian -- bash -c "echo 'VNC_PASS=\"$USER_PASS\"' >> /etc/termo-vnc.conf"

# Generate xstartup to link VNC with the Desktop Environment
cat << EOF > xstartup.tmp
#!/bin/bash
xrdb \$HOME/.Xresources
source /etc/termo-os.conf

if [ "\$OS_DE" == "GNOME" ]; then exec dbus-launch gnome-session & fi
if [ "\$OS_DE" == "KDE Plasma" ]; then exec dbus-launch startplasma-x11 & fi
if [ "\$OS_DE" == "XFCE" ]; then exec dbus-launch startxfce4 & fi
if [ "\$OS_DE" == "LXQt" ]; then exec dbus-launch startlxqt & fi
if [ "\$OS_DE" == "Openbox" ]; then exec dbus-launch openbox-session & fi
EOF
proot-distro login debian -- bash -c "mkdir -p ~/.vnc"
cat xstartup.tmp | proot-distro login debian -- bash -c "cat > ~/.vnc/xstartup && chmod +x ~/.vnc/xstartup"
rm xstartup.tmp

cat << EOF > vnc-details.tmp
#!/bin/bash
source /etc/termo-vnc.conf
echo '==========================='
echo '   TermoOS VNC Details     '
echo '==========================='
echo 'IP Address : 127.0.0.1'
echo "Port       : \$VNC_PORT"
echo "Username   : \$VNC_USER"
echo "Password   : \$VNC_PASS"
echo '==========================='
EOF
cat vnc-details.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/vnc-details && chmod +x /usr/local/bin/vnc-details"
rm vnc-details.tmp

cat << EOF > vnc-setup.tmp
#!/bin/bash
source /etc/termo-vnc.conf
NEW_USER=\$(dialog --clear --title "VNC Setup" --inputbox "Enter new Username:" 8 40 "\$VNC_USER" 3>&1 1>&2 2>&3)
NEW_PORT=\$(dialog --clear --title "VNC Setup" --inputbox "Enter new VNC Port (e.g. 5901, 5902):" 8 40 "\$VNC_PORT" 3>&1 1>&2 2>&3)
NEW_PASS=\$(dialog --clear --title "VNC Setup" --passwordbox "Enter new VNC Password:" 8 40 3>&1 1>&2 2>&3)

if [ -z "\$NEW_PASS" ] || [ -z "\$NEW_PORT" ]; then
    clear; echo "Setup cancelled."; exit 1
fi

DISPLAY_NUM=\$((\$NEW_PORT - 5900))
if [ \$DISPLAY_NUM -lt 1 ]; then DISPLAY_NUM=1; NEW_PORT=5901; fi

echo "VNC_USER=\"\$NEW_USER\"" > /etc/termo-vnc.conf
echo "VNC_PORT=\"\$NEW_PORT\"" >> /etc/termo-vnc.conf
echo "VNC_DISPLAY=\":\$DISPLAY_NUM\"" >> /etc/termo-vnc.conf
echo "VNC_PASS=\"\$NEW_PASS\"" >> /etc/termo-vnc.conf

echo "\$NEW_PASS" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
clear
echo "VNC Configuration Updated Successfully!"
EOF
cat vnc-setup.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/vnc-setup && chmod +x /usr/local/bin/vnc-setup"
rm vnc-setup.tmp

cat << EOF > vnc.tmp
#!/bin/bash
if [ "\$1" == "details" ]; then vnc-details; exit 0; fi
if [ "\$1" == "setup" ]; then vnc-setup; exit 0; fi

source /etc/termo-vnc.conf
$GUI_ENGINE

show_gui 1 3 "cleaning old sessions" "TermoOS Startup" 1
vncserver -kill \$VNC_DISPLAY > /dev/null 2>&1
sleep 1
show_gui 2 3 "launching graphical desktop" "TermoOS Startup" 1
vncserver -geometry 1280x720 -depth 24 \$VNC_DISPLAY > /dev/null 2>&1
sleep 1
show_gui 3 3 "finalizing setup" "TermoOS Startup" 1
sleep 1
clear
echo "VNC Server started successfully on port \$VNC_PORT!"
echo "Type 'vnc details' to view login info, or 'vnc setup' to change it."
EOF
cat vnc.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/vnc && chmod +x /usr/local/bin/vnc"
rm vnc.tmp

proot-distro login debian -- bash -c "mkdir -p ~/.vnc && echo '$USER_PASS' | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd" > /dev/null 2>&1

show_gui 7 $TOTAL_MODULES "termo-update (smart app)" "Installing TermoOS" 1

cat << 'EOF' > termo-update.tmp
#!/bin/bash
source /etc/termo-os.conf
clear
echo "======================================"
echo "       TermoOS Updater Engine         "
echo "======================================"
echo " TermoOS Version : 1.0"
echo " Install Type    : $OS_TYPE"
echo " Environment     : $OS_DE"
echo "======================================"
echo "Checking for updates... please wait."

apt-get update -y > /dev/null 2>&1
UPGRADES=$(apt-get -s upgrade | awk '/^Inst/ { print $2 }' | wc -l)

if [ "$UPGRADES" -eq 0 ]; then
    echo -e "\nYou are on the latest version. No updates needed!"
    echo "Press Enter to exit."
    read -r
    exit 0
else
    echo -e "\n$UPGRADES updates are available for your OS and modules."
    read -p "Would you like to install the new updates? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" || "$CONFIRM" == "" ]]; then
        echo "Installing updates..."
        apt-get upgrade -y
        apt-get autoremove -y
        echo "--------------------------------------"
        echo "Updates installed successfully!"
    else
        echo "Update cancelled."
    fi
    echo "Press Enter to exit."
    read -r
fi
EOF
cat termo-update.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/termo-update && chmod +x /usr/local/bin/termo-update"
rm termo-update.tmp

proot-distro login debian -- bash -c "mkdir -p /root/Desktop"
cat << 'EOF' > updates-desktop.tmp
[Desktop Entry]
Name=Updates
Comment=Check for TermoOS Updates
Exec=x-terminal-emulator -e "bash -c '/usr/local/bin/termo-update'"
Icon=system-software-update
Terminal=false
Type=Application
EOF
cat updates-desktop.tmp | proot-distro login debian -- bash -c "cat > /root/Desktop/Updates.desktop && chmod +x /root/Desktop/Updates.desktop"
rm updates-desktop.tmp

show_gui 8 $TOTAL_MODULES "termo-modules (app store)" "Installing TermoOS" 1
proot-distro login debian -- bash -c "curl -s https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/termo-modules.sh -o /usr/local/bin/termo-modules && chmod +x /usr/local/bin/termo-modules" > /dev/null 2>&1

sleep 1
clear

echo -e "\n\nSuccess! TermoOS is installed."
echo "----------------------------------------"
echo "To enter TermoOS, type: proot-distro login debian"
echo "Inside TermoOS, you can use these commands:"
echo " - vnc          (Starts desktop)"
echo " - vnc details  (Shows login info)"
echo " - vnc setup    (Changes port/username/password)"
echo " - termo-update (Terminal Updater)"
echo " - termo-modules(Installs extra apps)"
echo ""
echo "Note: Double-click 'Updates' on your graphical desktop to update from inside the OS!"
echo "----------------------------------------"
