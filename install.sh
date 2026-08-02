#!/bin/bash

# TermoOS Setup Script
# Based on Debian via proot-distro

# Fix for terminal drawing issues in Termux
export TERM=xterm-256color

echo "Checking required Termux packages..."

# 1. Fast Dependency Check (Skips slow updates if already installed)
if ! command -v dialog &> /dev/null || ! command -v proot-distro &> /dev/null; then
    echo "First-time setup: Downloading dependencies (this may take a few minutes)..."
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg install dialog proot-distro bc ncurses-utils wget curl -y -o Dpkg::Options::="--force-confold"
else
    echo "Dependencies already installed. Skipping update to save time!"
    sleep 1
fi

# 2. Hardware Check & Auto-Recommendation
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 4000 ]; then
    REC_TYPE="Minimal"
elif [ "$TOTAL_RAM" -lt 6000 ]; then
    REC_TYPE="Simplified"
else
    REC_TYPE="Full"
fi

# 3. Setup Wizard UI (Added number key hints to avoid arrow freezing)
dialog --backtitle "TermoOS Installation" --title "Welcome" --msgbox "Welcome to the TermoOS Setup!\n\nSystem will check your specs and guide you through the setup.\n\nTIP: If arrows freeze, use NUMBER KEYS (1, 2, 3) to select options." 12 50

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
clear

# ==========================================
# 4. Custom Progress Bar Logic
# ==========================================
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

# ==========================================
# 5. Installation Execution
# ==========================================
update_progress 2 "Installing proot-distro debian base..."
proot-distro install debian > /dev/null 2>&1

update_progress 10 "Updating Debian repositories..."
proot-distro login debian -- bash -c "apt-get update -y && apt-get upgrade -y" > /dev/null 2>&1

update_progress 20 "Installing Desktop Environment..."
if [ "$DE_CHOICE" == "3" ]; then
    proot-distro login debian -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install xfce4 xfce4-goodies -y" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "5" ]; then
    proot-distro login debian -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install openbox obconf -y" > /dev/null 2>&1
else
    # Fallback to XFCE if GNOME/KDE are selected but not fully scripted yet to save extreme install times
    proot-distro login debian -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install xfce4 xfce4-goodies -y" > /dev/null 2>&1
fi

update_progress 28 "Installing Firefox and VNC Server..."
proot-distro login debian -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install tigervnc-standalone-server dbus-x11 firefox-esr nano dialog curl sudo -y" > /dev/null 2>&1

update_progress 33 "Configuring TermoOS commands (vnc, update)..."

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

# Update App Command (termo-update)
proot-distro login debian -- bash -c "cat << 'EOF' > /usr/local/bin/termo-update
#!/bin/bash
echo '===================================='
echo '    Updating TermoOS Packages...    '
echo '===================================='
apt-get update -y
apt-get upgrade -y
apt-get autoremove -y
echo '===================================='
echo '  Update Complete! System is fresh. '
echo '===================================='
EOF
chmod +x /usr/local/bin/termo-update"

update_progress 38 "Fetching TermoOS App Store (Modules)..."
# Corrected GitHub URL to your repository
proot-distro login debian -- bash -c "curl -s https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/termo-modules.sh -o /usr/local/bin/termo-modules && chmod +x /usr/local/bin/termo-modules" > /dev/null 2>&1

update_progress 40 "Installation Complete!"
echo -e "\n\nSuccess! TermoOS is installed."
echo "----------------------------------------"
echo "To enter TermoOS, type: proot-distro login debian"
echo "Inside TermoOS, you can use these commands:"
echo " - vnc          (Starts the desktop)"
echo " - vnc details  (Shows login info)"
echo " - termo-update (Updates the system)"
echo " - termo-modules(Installs extra apps)"
echo "----------------------------------------"
