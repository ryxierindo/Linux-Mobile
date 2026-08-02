#!/bin/bash

# TermoOS Setup Script
# Based on Debian via proot-distro

echo "Preparing TermoOS Setup Wizard..."
pkg update -y > /dev/null 2>&1
pkg install dialog proot-distro bc ncurses-utils wget curl -y > /dev/null 2>&1

# Hardware Check & Auto-Recommendation
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 4000 ]; then
    REC_TYPE="Minimal"
elif [ "$TOTAL_RAM" -lt 6000 ]; then
    REC_TYPE="Simplified"
else
    REC_TYPE="Full"
fi

# Setup Wizard UI
dialog --backtitle "TermoOS Installation" --title "Welcome" --msgbox "Welcome to the TermoOS Setup!\n\nSystem will check your specs and guide you through the setup." 8 50

DE_CHOICE=$(dialog --clear --backtitle "TermoOS Setup" --title "Desktop Environment" \
--menu "Choose your Desktop Environment (Heavy to Light):" 15 50 5 \
"1" "GNOME (Very Heavy)" \
"2" "KDE Plasma (Heavy)" \
"3" "XFCE (Medium/Recommended)" \
"4" "LXQt (Light)" \
"5" "Openbox (Very Light)" \
3>&1 1>&2 2>&3)

CONN_CHOICE=$(dialog --clear --backtitle "TermoOS Setup" --title "Remote Protocol" \
--menu "How will you connect to your desktop?" 12 50 3 \
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
clear

# Progress Bar Logic
TOTAL_STEPS=40
START_TIME=$(date +%s)

update_progress() {
    local STEP=$1
    local DESC=$2
    local CURRENT_TIME=$(date +%s)
    local ELAPSED=$((CURRENT_TIME - START_TIME))
    local PERCENT=$((STEP * 100 / TOTAL_STEPS))
    local ETA_SECS=0
    if [ $STEP -gt 0 ]; then
        ETA_SECS=$(( (ELAPSED / STEP) * (TOTAL_STEPS - STEP) ))
    fi
    local ETA_MINS=$((ETA_SECS / 60))
    local ELAPSED_MINS=$((ELAPSED / 60))
    local FILLED=$(( (PERCENT * 15) / 100 ))
    local BAR=""
    for ((i=0; i<15; i++)); do
        if [ $i -lt $FILLED ]; then BAR="${BAR}|"; else BAR="${BAR} "; fi
    done
    printf "\r\033[K%d/%d %d%% [%-15s] EST: %d mins Elapsed: %d mins - %s" "$STEP" "$TOTAL_STEPS" "$PERCENT" "$BAR" "$ETA_MINS" "$ELAPSED_MINS" "$DESC"
}

# Installation Execution
update_progress 2 "Installing proot-distro debian base..."
proot-distro install debian > /dev/null 2>&1

update_progress 10 "Updating Debian repositories..."
proot-distro login debian -- bash -c "apt-get update -y && apt-get upgrade -y" > /dev/null 2>&1

update_progress 20 "Installing Desktop Environment..."
if [ "$DE_CHOICE" == "3" ]; then
    proot-distro login debian -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install xfce4 xfce4-goodies -y" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "5" ]; then
    proot-distro login debian -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install openbox obconf -y" > /dev/null 2>&1
fi

update_progress 28 "Installing Firefox and VNC Server..."
proot-distro login debian -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install tigervnc-standalone-server dbus-x11 firefox-esr nano dialog curl sudo -y" > /dev/null 2>&1

update_progress 33 "Configuring TermoOS modules and commands..."

# VNC Details Command
proot-distro login debian -- bash -c "cat << 'EOF' > /usr/local/bin/vnc-details
#!/bin/bash
echo '==========================='
echo '   TermoOS VNC Details     '
echo '==========================='
echo 'IP Address : 127.0.0.1'
echo 'Port       : 5901'
echo 'Username   : root'
echo 'Password   : $USER_PASS'
echo '==========================='
EOF
chmod +x /usr/local/bin/vnc-details"

# VNC Start Command
proot-distro login debian -- bash -c "cat << 'EOF' > /usr/local/bin/vnc
#!/bin/bash
if [ \"\$1\" == \"details\" ]; then
    vnc-details
    exit 0
fi
vncserver -kill :1 > /dev/null 2>&1
vncserver -geometry 1280x720 -depth 24 :1
echo 'VNC Server started! Type \"vnc details\" for info.'
EOF
chmod +x /usr/local/bin/vnc"

# Setup VNC Password
proot-distro login debian -- bash -c "mkdir -p ~/.vnc && echo '$USER_PASS' | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd" > /dev/null 2>&1

update_progress 38 "Fetching TermoOS App Store (Modules)..."
# Replace YourUsername below!
proot-distro login debian -- bash -c "curl -s https://raw.githubusercontent.com/YourUsername/TermoOS/main/termo-modules.sh -o /usr/local/bin/termo-modules && chmod +x /usr/local/bin/termo-modules" > /dev/null 2>&1

update_progress 40 "Installation Complete!"
echo -e "\n\nSuccess! TermoOS is installed."
echo "To start TermoOS, type: proot-distro login debian"
echo "Once inside, type 'vnc' to start the desktop, or 'termo-modules' to install extra software."
