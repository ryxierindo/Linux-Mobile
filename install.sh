#!/bin/bash

# TermoOS Setup Script
# Based on Debian via proot-distro
# Hardened for VNC/PRoot Compatibility

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

# ==========================================
# SETUP WIZARD (With Back Button Logic)
# ==========================================
STEP=1
while [ $STEP -le 7 ]; do
    case $STEP in
        1)
            DE_CHOICE=$(dialog --clear --cancel-label "Exit" --backtitle "TermoOS Setup" --title "Desktop Environment" \
            --menu "Choose an independent, PRoot-safe graphical environment:" 15 60 3 \
            "1" "XFCE (Full Desktop - Stable & Recommended)" \
            "2" "Openbox (Lightweight Window Manager)" \
            "3" "CLI Only (Minimal Xterm Interface)" \
            3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ]; then clear; echo "Installation aborted."; exit 0; fi
            ((STEP++))
            ;;
        2)
            CONN_CHOICE=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Remote Protocol" \
            --menu "Press a NUMBER to select connection type:" 12 55 3 \
            "1" "VNC (Graphical Desktop)" \
            "2" "RDP (Windows Remote Desktop)" \
            "3" "VPS (SSH only, No GUI)" \
            3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            ((STEP++))
            ;;
        3)
            if [ "$CONN_CHOICE" == "1" ]; then
                VNC_TYPE_CHOICE=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "VNC Client Type" \
                --menu "Press a NUMBER to select your preferred VNC client:" 12 55 2 \
                "1" "NoVNC (Browser based, easy)" \
                "2" "RealVNC / Standard (App based, faster)" \
                3>&1 1>&2 2>&3)
                
                if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            else
                VNC_TYPE_CHOICE="0"
            fi
            ((STEP++))
            ;;
        4)
            TYPE_CHOICE=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Installation Type" \
            --menu "Select Installation Type\n(Auto-Recommended for your device: $REC_TYPE)" 15 60 3 \
            "Full" "All modules, heavy, longest install time" \
            "Simplified" "Necessary tools + Firefox (Medium)" \
            "Minimal" "Only base OS and DE to run (Fastest)" \
            3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            ((STEP++))
            ;;
        5)
            USER_HOSTNAME=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "Hostname Setup" \
            --inputbox "Enter custom Hostname (Optional):\n(Leave blank to default to 'localhost')" 9 45 3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            if [ -z "$USER_HOSTNAME" ]; then USER_HOSTNAME="localhost"; fi
            ((STEP++))
            ;;
        6)
            USER_NAME=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "User Setup" \
            --inputbox "Enter a new username for TermoOS:" 8 40 3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            ((STEP++))
            ;;
        7)
            USER_PASS=$(dialog --clear --cancel-label "Back" --backtitle "TermoOS Setup" --title "User Setup" \
            --passwordbox "Enter a password for VNC/System:" 8 40 3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ]; then ((STEP--)); continue; fi
            
            dialog --clear --cancel-label "Back" --title "Ready" --yesno "Configuration complete. Begin installation?" 8 40
            if [ $? -ne 0 ]; then 
                ((STEP--))
                continue
            else 
                break
            fi
            ;;
    esac
done

# ==========================================
# Map the DE & Protocol Names for the OS Config
# ==========================================
DE_NAME="XFCE"
if [ "$DE_CHOICE" == "1" ]; then DE_NAME="XFCE"; fi
if [ "$DE_CHOICE" == "2" ]; then DE_NAME="Openbox"; fi
if [ "$DE_CHOICE" == "3" ]; then DE_NAME="CLI"; fi

VNC_APP_NAME="None"
if [ "$VNC_TYPE_CHOICE" == "1" ]; then VNC_APP_NAME="NoVNC"; fi
if [ "$VNC_TYPE_CHOICE" == "2" ]; then VNC_APP_NAME="RealVNC"; fi

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
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS xfce4 xfce4-goodies" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "2" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS openbox obconf pcmanfm-qt lxpanel xterm" > /dev/null 2>&1
elif [ "$DE_CHOICE" == "3" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS xterm fonts-dejavu" > /dev/null 2>&1
fi

show_gui 4 $TOTAL_MODULES "remote display protocols" "Installing TermoOS" 3
if [ "$VNC_TYPE_CHOICE" == "1" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tigervnc-standalone-server tigervnc-tools dbus-x11 novnc websockify" > /dev/null 2>&1
else
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tigervnc-standalone-server tigervnc-tools dbus-x11" > /dev/null 2>&1
fi

show_gui 5 $TOTAL_MODULES "extras (apps & tools)" "Installing TermoOS" 4
if [ "$TYPE_CHOICE" == "Minimal" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS nano dialog curl sudo xterm" > /dev/null 2>&1
elif [ "$TYPE_CHOICE" == "Simplified" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS firefox-esr wget nano dialog curl sudo xterm" > /dev/null 2>&1
else
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS firefox-esr wget nano dialog curl sudo xterm htop neofetch" > /dev/null 2>&1
fi

show_gui 6 $TOTAL_MODULES "vnc-config (startup scripts)" "Installing TermoOS" 1

# Write System Configs & Automatic TermoOS Branding
proot-distro login debian -- bash -c "echo 'OS_TYPE=\"$TYPE_CHOICE\"' > /etc/termo-os.conf"
proot-distro login debian -- bash -c "echo 'OS_DE=\"$DE_NAME\"' >> /etc/termo-os.conf"
proot-distro login debian -- bash -c "echo 'VNC_TYPE=\"$VNC_APP_NAME\"' >> /etc/termo-os.conf"
proot-distro login debian -- bash -c "echo 'VNC_USER=\"$USER_NAME\"' > /etc/termo-vnc.conf"
proot-distro login debian -- bash -c "echo 'VNC_PORT=\"5901\"' >> /etc/termo-vnc.conf"
proot-distro login debian -- bash -c "echo 'VNC_DISPLAY=\":1\"' >> /etc/termo-vnc.conf"
proot-distro login debian -- bash -c "echo 'VNC_PASS=\"$USER_PASS\"' >> /etc/termo-vnc.conf"

# Configure Hostname
proot-distro login debian -- bash -c "echo '$USER_HOSTNAME' > /etc/hostname"
proot-distro login debian -- bash -c "echo '127.0.0.1 localhost $USER_HOSTNAME' > /etc/hosts"

# Automatic TermoOS Branding (`/etc/os-release`)
cat << 'EOF' > os-release.tmp
PRETTY_NAME="TermoOS (based on Debian)"
NAME="TermoOS"
VERSION_ID="1.0"
VERSION="1.0"
VERSION_CODENAME=trixie
ID=debian
ID_LIKE=debian
HOME_URL="https://github.com/ryxierindo/Linux-Mobile"
SUPPORT_URL="https://github.com/ryxierindo/Linux-Mobile/issues"
BUG_REPORT_URL="https://github.com/ryxierindo/Linux-Mobile/issues"
EOF
cat os-release.tmp | proot-distro login debian -- bash -c "cat > /etc/os-release"
rm os-release.tmp

cat << EOF > xstartup.tmp
#!/bin/bash
xrdb \$HOME/.Xresources
source /etc/termo-os.conf

export XDG_SESSION_TYPE=x11

if [ "\$OS_DE" == "XFCE" ]; then exec dbus-launch startxfce4; fi
if [ "\$OS_DE" == "Openbox" ]; then 
    pcmanfm-qt --desktop &
    lxpanel &
    exec dbus-launch openbox-session
fi
if [ "\$OS_DE" == "CLI" ]; then exec xterm -geometry 120x35 -fa 'Monospace' -fs 12 -bg black -fg white; fi
EOF
proot-distro login debian -- bash -c "mkdir -p ~/.vnc"
cat xstartup.tmp | proot-distro login debian -- bash -c "cat > ~/.vnc/xstartup && chmod +x ~/.vnc/xstartup"
rm xstartup.tmp

cat << EOF > vnc-details.tmp
#!/bin/bash
source /etc/termo-vnc.conf
source /etc/termo-os.conf
echo '==========================='
echo '   TermoOS Connection Info '
echo '==========================='
if [ "\$VNC_TYPE" == "NoVNC" ]; then
    echo "Type       : Browser (NoVNC)"
    echo "URL        : http://127.0.0.1:6080/vnc.html"
    echo "Password   : \$VNC_PASS"
else
    echo 'IP Address : 127.0.0.1'
    echo "Port       : \$VNC_PORT"
    echo "Username   : \$VNC_USER"
    echo "Password   : \$VNC_PASS"
fi
echo '==========================='
EOF
cat vnc-details.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/vnc-details && chmod +x /usr/local/bin/vnc-details"
rm vnc-details.tmp

cat << EOF > vnc-setup.tmp
#!/bin/bash
source /etc/termo-vnc.conf

vncserver -kill \$VNC_DISPLAY > /dev/null 2>&1
pkill websockify > /dev/null 2>&1

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
echo "Run 'boot Termo' to restart the server with your new settings."
EOF
cat vnc-setup.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/vnc-setup && chmod +x /usr/local/bin/vnc-setup"
rm vnc-setup.tmp

# The master startup routine ('boot Termo', 'vnc', etc.)
cat << EOF > boot-termo.tmp
#!/bin/bash
if [ "\$1" == "details" ]; then vnc-details; exit 0; fi
if [ "\$1" == "setup" ]; then vnc-setup; exit 0; fi

source /etc/termo-vnc.conf
source /etc/termo-os.conf
$GUI_ENGINE

show_gui 1 3 "cleaning old sessions" "TermoOS Startup" 1
vncserver -kill \$VNC_DISPLAY > /dev/null 2>&1
pkill websockify > /dev/null 2>&1
sleep 1

show_gui 2 3 "launching graphical desktop" "TermoOS Startup" 1
vncserver \$VNC_DISPLAY -geometry 1280x720 -depth 24 -localhost no -SecurityTypes VncAuth,None -extension MIT-SHM > /dev/null 2>&1
sleep 1

show_gui 3 3 "finalizing setup" "TermoOS Startup" 1
if [ "\$VNC_TYPE" == "NoVNC" ]; then
    websockify -D --web=/usr/share/novnc/ 6080 localhost:\$VNC_PORT > /dev/null 2>&1
fi
sleep 1

clear
if [ "\$VNC_TYPE" == "NoVNC" ]; then
    echo "NoVNC Server started successfully!"
    echo "Open your mobile browser and go to: http://127.0.0.1:6080/vnc.html"
else
    echo "TermoOS Desktop started successfully on port \$VNC_PORT!"
    echo "Type 'boot Termo details' to view login info, or 'boot Termo setup' to change it."
fi
EOF
cat boot-termo.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/boot-termo && chmod +x /usr/local/bin/boot-termo"
proot-distro login debian -- bash -c "ln -sf /usr/local/bin/boot-termo /usr/local/bin/vnc"

# Create a multi-word launcher wrapper so 'boot Termo' works out of the box
cat << 'EOF' > boot-wrapper.tmp
#!/bin/bash
if [ "$1" == "Termo" ] || [ "$1" == "termo" ]; then
    shift
    boot-termo "$@"
else
    boot-termo "$@"
fi
EOF
cat boot-wrapper.tmp | proot-distro login debian -- bash -c "cat > /usr/local/bin/boot && chmod +x /usr/local/bin/boot"
rm boot-termo.tmp boot-wrapper.tmp

proot-distro login debian -- bash -c "mkdir -p ~/.config/tigervnc ~/.vnc && echo '$USER_PASS' | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd && cp ~/.vnc/passwd ~/.config/tigervnc/passwd && chmod 600 ~/.config/tigervnc/passwd" > /dev/null 2>&1

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
echo "Inside TermoOS, your startup commands are:"
echo " - boot Termo          (Starts desktop with GUI loading bar)"
echo " - boot Termo details  (Shows login info)"
echo " - boot Termo setup    (Changes port/username/password)"
echo " - termo-update        (Terminal Updater)"
echo " - termo-modules       (Installs extra apps)"
echo "----------------------------------------"
