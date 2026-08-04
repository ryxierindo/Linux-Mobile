#!/bin/bash

# ==========================================
# TermoOS Setup Wizard
# ==========================================

export TERM=xterm-256color

echo "Checking required Termux packages..."
if ! command -v dialog &> /dev/null || ! command -v proot-distro &> /dev/null; then
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg install dialog proot-distro bc ncurses-utils wget curl -y -o Dpkg::Options::="--force-confold"
fi

TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 4000 ]; then SPEED_FACTOR=2.0; REC_TYPE="Basic"; else SPEED_FACTOR=1.0; REC_TYPE="Full"; fi

dialog --backtitle "TermoOS Installation" --title "Welcome" --msgbox "Welcome to the TermoOS Setup!\n\nHardware Profile:\nRAM: ${TOTAL_RAM}MB\n\nTIP: If arrows freeze, use NUMBER KEYS (1, 2) to select options." 12 50

STEP=1
while [ $STEP -le 7 ]; do
    case $STEP in
        1)
            TYPE_CHOICE=$(dialog --clear --cancel-label "Exit" --backtitle "TermoOS Setup" --title "TermoOS Edition" \
            --menu "Select your TermoOS Edition:\n(Auto-Recommended for your device: TXDE $REC_TYPE)" 14 65 2 "Full" "TXDE Full (Apps, Browser, Wallpapers)" "Basic" "TXDE Basic (Minimal core)" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then clear; exit 0; fi; ((STEP++)) ;;
        2)
            CONN_CHOICE=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Remote Protocol" \
            --menu "Select connection type:" 12 55 3 "1" "VNC (Graphical Desktop)" "2" "RDP (Windows Remote Desktop)" "3" "VPS (SSH only)" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi; ((STEP++)) ;;
        3)
            if [ "$CONN_CHOICE" == "1" ]; then
                VNC_APP_NAME=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "VNC Client Type" \
                --menu "Select your preferred VNC client:" 12 55 2 "NoVNC" "Browser based, easy" "RealVNC" "App based, faster" 3>&1 1>&2 2>&3)
                if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            else
                VNC_APP_NAME="None"
            fi
            ((STEP++)) ;;
        4)
            USER_TZ=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Region & Timezone" \
            --inputbox "Enter your Timezone (e.g. Asia/Kolkata, America/New_York, Europe/London):" 9 55 "Asia/Kolkata" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi; ((STEP++)) ;;
        5)
            USER_HOSTNAME=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Hostname Setup" \
            --inputbox "Enter Hostname (Leave blank for 'localhost'):" 8 50 "localhost" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi; ((STEP++)) ;;
        6)
            USER_NAME=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "User Setup" \
            --inputbox "Enter a new username for TermoOS:" 8 40 "root" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi; ((STEP++)) ;;
        7)
            USER_PASS=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "User Setup" \
            --passwordbox "Enter a password for VNC/System:" 8 40 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            dialog --clear --title "Ready" --yesno "Configuration complete. Begin installation?" 8 40
            if [ $? -ne 0 ]; then ((STEP--)); continue; else break; fi ;;
    esac
done

clear
echo "[+] Saving configuration..."
cat << EOF > termo_config.env
TYPE_CHOICE="$TYPE_CHOICE"
CONN_CHOICE="$CONN_CHOICE"
VNC_APP_NAME="$VNC_APP_NAME"
USER_HOSTNAME="$USER_HOSTNAME"
USER_NAME="$USER_NAME"
USER_PASS="$USER_PASS"
USER_TZ="$USER_TZ"
SPEED_FACTOR="$SPEED_FACTOR"
EOF

cat << 'EOF' > "${PREFIX:-/data/data/com.termux/files/usr}/bin/termo"
#!/bin/bash
proot-distro login debian -- boot-termo "$@"
EOF
chmod +x "${PREFIX:-/data/data/com.termux/files/usr}/bin/termo"

wget -q https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/installer.sh -O installer.sh
chmod +x installer.sh
bash installer.sh
