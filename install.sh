#!/bin/bash

# ==========================================
# TermoOS Setup Wizard (Part 1)
# Handles User Configuration & Variables
# ==========================================

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
# HARDWARE PROFILER
# ==========================================
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
CORES=$(nproc 2>/dev/null || echo 4)

SPEED_FACTOR=1.0
if [ "$TOTAL_RAM" -lt 4000 ]; then
    SPEED_FACTOR=2.0; REC_TYPE="Basic"
else
    SPEED_FACTOR=1.0; REC_TYPE="Full"
fi

dialog --backtitle "TermoOS Installation" --title "Welcome" --msgbox "Welcome to the TermoOS Setup!\n\nSystem will check your specs and guide you through the setup.\n\nHardware Profile:\nRAM: ${TOTAL_RAM}MB\nCORES: ${CORES}\n\nTIP: If arrows freeze, use NUMBER KEYS (1, 2) to select options." 15 50

# ==========================================
# SETUP WIZARD
# ==========================================
STEP=1
while [ $STEP -le 6 ]; do
    case $STEP in
        1)
            TYPE_CHOICE=$(dialog --clear --cancel-label "Exit" --backtitle "TermoOS Setup" --title "TermoOS Edition" \
            --menu "Select your TermoOS Edition\n(Auto-Recommended for your device: TXDE $REC_TYPE)" 15 65 2 \
            "Full" "TXDE Full (App Store, Firefox, Recycle Bin)" \
            "Basic" "TXDE Basic (Core features, fast & minimal)" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then clear; echo "Installation aborted."; exit 0; fi
            ((STEP++)) ;;
        2)
            CONN_CHOICE=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Remote Protocol" \
            --menu "Press a NUMBER to select connection type:" 12 55 3 \
            "1" "VNC (Graphical Desktop)" "2" "RDP (Windows Remote Desktop)" "3" "VPS (SSH only)" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            ((STEP++)) ;;
        3)
            if [ "$CONN_CHOICE" == "1" ]; then
                VNC_TYPE_CHOICE=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "VNC Client Type" \
                --menu "Press a NUMBER to select your preferred VNC client:" 12 55 2 \
                "1" "NoVNC (Browser based, easy)" "2" "RealVNC / Standard (App based, faster)" 3>&1 1>&2 2>&3)
                if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            else
                VNC_TYPE_CHOICE="0"
            fi
            ((STEP++)) ;;
        4)
            USER_HOSTNAME=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Hostname Setup" \
            --inputbox "Enter custom Hostname (Optional):\n(Leave blank to default to 'localhost')" 9 45 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            if [ -z "$USER_HOSTNAME" ]; then USER_HOSTNAME="localhost"; fi
            ((STEP++)) ;;
        5)
            USER_NAME=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "User Setup" \
            --inputbox "Enter a new username for TermoOS:" 8 40 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            ((STEP++)) ;;
        6)
            USER_PASS=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "User Setup" \
            --passwordbox "Enter a password for VNC/System:" 8 40 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            
            dialog --clear --cancel-label "Back" --title "Ready" --yesno "Configuration complete. Begin installation?" 8 40
            if [ $? -ne 0 ]; then ((STEP--)); continue; else break; fi ;;
    esac
done

DE_NAME="TxDE"
VNC_APP_NAME="None"
if [ "$VNC_TYPE_CHOICE" == "1" ]; then VNC_APP_NAME="NoVNC"; fi
if [ "$VNC_TYPE_CHOICE" == "2" ]; then VNC_APP_NAME="RealVNC"; fi

# ==========================================
# EXPORT SETTINGS & LAUNCH INSTALLER
# ==========================================
clear
echo "[+] Saving configuration..."
cat << EOF > termo_config.env
TYPE_CHOICE="$TYPE_CHOICE"
DE_NAME="$DE_NAME"
VNC_APP_NAME="$VNC_APP_NAME"
USER_HOSTNAME="$USER_HOSTNAME"
USER_NAME="$USER_NAME"
USER_PASS="$USER_PASS"
SPEED_FACTOR="$SPEED_FACTOR"
EOF

# Termux Outer Shortcut creation
cat << 'EOF' > "${PREFIX:-/data/data/com.termux/files/usr}/bin/termo"
#!/bin/bash
proot-distro login debian -- boot Termo "$@"
EOF
chmod +x "${PREFIX:-/data/data/com.termux/files/usr}/bin/termo"

echo "[+] Fetching the core installer engine (Part 2)..."
if [ ! -f "installer.sh" ]; then
    wget -q https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/installer.sh -O installer.sh
fi

if [ -f "installer.sh" ]; then
    chmod +x installer.sh
    bash installer.sh
else
    echo "[-] Error: Could not find installer.sh locally or remotely."
    exit 1
fi
