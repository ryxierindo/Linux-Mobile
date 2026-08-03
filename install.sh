#!/bin/bash

# ==========================================
# TermoOS Setup Script (TxDE Engine)
# Hardened against PRoot FD Stream Bugs
# ==========================================

export TERM=xterm-256color
export PROOT_NO_WARNINGS=1

echo "Checking required Termux packages..."
if ! command -v dialog &> /dev/null || ! command -v proot-distro &> /dev/null; then
    echo "First-time setup: Downloading dependencies..."
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg install dialog proot-distro bc ncurses-utils wget curl -y -o Dpkg::Options::="--force-confold"
else
    echo "Dependencies already installed. Starting Setup..."
    sleep 1
fi

# Define the absolute path to the Debian PRoot container
PD_ROOT="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/installed-rootfs/debian"

# ==========================================
# HARDWARE PROFILER
# ==========================================
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
CORES=$(nproc 2>/dev/null || echo 4)

SPEED_FACTOR=1.0
if [ "$TOTAL_RAM" -lt 4000 ]; then
    SPEED_FACTOR=2.0; REC_TYPE="TXDE Basic"
else
    SPEED_FACTOR=1.0; REC_TYPE="TXDE Full"
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
            --menu "Select your TermoOS Edition\n(Auto-Recommended for your device: $REC_TYPE)" 15 65 2 \
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
# GUI PROGRESS ENGINE
# ==========================================
START_TIME=$(date +%s)
show_gui() {
    local STEP=$1; local TOTAL=$2; local DESC=$3; local TITLE=$4; local BASE_EST_MINS=$5
    local CURRENT_TIME=$(date +%s)
    local ELAPSED_SECS=$((CURRENT_TIME - START_TIME))
    local ELAPSED_MINS=$((ELAPSED_SECS / 60))
    local PERCENT=$((STEP * 100 / TOTAL))
    local PREDICTED_EST=$(echo "$BASE_EST_MINS * $SPEED_FACTOR" | bc | awk '{print int($1+0.5)}')

    echo "$PERCENT" | dialog --title "$TITLE" --backtitle "TermoOS Setup" \
    --gauge "Module $STEP/$TOTAL: $DESC\n\nEST : ~$PREDICTED_EST min     ELAPSED : $ELAPSED_MINS min" 10 45
}

# ==========================================
# INSTALLATION LOGIC
# ==========================================
TOTAL_MODULES=8
ENV_VARS="export PROOT_NO_WARNINGS=1; export DEBIAN_FRONTEND=noninteractive; export DEBCONF_NONINTERACTIVE_SEEN=true"
APT_OPTS="-yq --no-install-recommends -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""

show_gui 1 $TOTAL_MODULES "proot (linux base)" "Installing TermoOS" 2
proot-distro install debian > /dev/null 2>&1

show_gui 2 $TOTAL_MODULES "apt-get (system updates)" "Installing TermoOS" 3
proot-distro login debian -- bash -c "$ENV_VARS; apt-get update -y && apt-get upgrade $APT_OPTS" > /dev/null 2>&1

show_gui 3 $TOTAL_MODULES "txde-engine (core UI)" "Installing TermoOS" 8
proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS openbox tint2 pcmanfm xterm whiptail x11-xserver-utils trash-cli" > /dev/null 2>&1

show_gui 4 $TOTAL_MODULES "remote display protocols" "Installing TermoOS" 3
if [ "$VNC_TYPE_CHOICE" == "1" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tigervnc-standalone-server tigervnc-tools dbus-x11 novnc websockify" > /dev/null 2>&1
else
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tigervnc-standalone-server tigervnc-tools dbus-x11" > /dev/null 2>&1
fi

show_gui 5 $TOTAL_MODULES "extras (apps & tools)" "Installing TermoOS" 4
if [ "$TYPE_CHOICE" == "Basic" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS nano dialog curl sudo xterm" > /dev/null 2>&1
else
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS firefox-esr wget nano dialog curl sudo xterm htop neofetch" > /dev/null 2>&1
fi

# ==========================================
# TXDE CONFIGURATION (Direct File Writes)
# ==========================================
show_gui 6 $TOTAL_MODULES "vnc-config (startup scripts)" "Installing TermoOS" 1

mkdir -p "$PD_ROOT/root/Desktop" "$PD_ROOT/root/.config/tint2" "$PD_ROOT/root/.vnc" "$PD_ROOT/usr/local/bin" "$PD_ROOT/etc" "$PD_ROOT/tmp"

# 1. Windows Style Taskbar
cat << 'EOF' > "$PD_ROOT/root/.config/tint2/tint2rc"
panel_items = L:T:B:S
panel_position = bottom center horizontal
panel_size = 100% 40px
panel_margin = 0 0
panel_padding = 4 2
font_name = sans 9
taskbar_mode = single_desktop
taskbar_sort_order = mru
task_icon = 1
task_text = 1
task_width = 150
task_padding = 6 2
task_background_id = 0
task_active_background_id = 1
time1_format = %H:%M
time2_format = %d-%m-%Y
systray_padding = 4
systray_sort = ascending
EOF

# 2. TxDE Features App
cat << 'EOF' > "$PD_ROOT/usr/local/bin/txde-features"
#!/bin/bash
export NEWT_COLORS='root=white,blue:window=white,blue:border=white,blue:button=white,blue'
SHOW_PROGRESS() {
    TITLE="$1"; STEP="$2"; TOTAL="$3"; PERCENT=$(( STEP * 100 / TOTAL ))
    (echo "$PERCENT"; sleep 0.5) | whiptail --title "$TITLE" --gauge "Processing: $STEP/$TOTAL\nPlease wait..." 8 50 $PERCENT
}
MAIN_MENU() {
    if [ -f ~/Desktop/firefox.desktop ] || [ -f ~/Desktop/appstore.desktop ]; then CURRENT_MODE="TXDE Full"; else CURRENT_MODE="TXDE Basic"; fi
    CHOICE=$(whiptail --title "TermoOS Features App" --menu "Current Mode: [$CURRENT_MODE]\nSelect option:" 16 65 5 \
    "1" "Switch DE Mode (Full <-> Basic)" "2" "Control Panel (Enable/Disable)" "3" "Firefox Browser (Enable/Disable)" "4" "App Store (Enable/Disable)" "5" "Exit" 3>&1 1>&2 2>&3)
    case $CHOICE in
        1) SWITCH_DE_MODE ;; 2) TOGGLE_CONTROL_PANEL ;; 3) TOGGLE_FIREFOX ;; 4) TOGGLE_APPSTORE ;; 5) exit 0 ;;
    esac
}
SWITCH_DE_MODE() {
    if [ -f ~/Desktop/firefox.desktop ] || [ -f ~/Desktop/appstore.desktop ]; then
        if whiptail --title "Switch Mode" --yesno "Switch to TXDE Basic? (Removes App Store & Firefox shortcuts)" 10 60; then
            SHOW_PROGRESS "Switching to TXDE Basic" 0 2; rm -f ~/Desktop/appstore.desktop ~/Desktop/recycle-bin.desktop; SHOW_PROGRESS "Switching to TXDE Basic" 1 2; rm -f ~/Desktop/firefox.desktop; SHOW_PROGRESS "Switching to TXDE Basic" 2 2; whiptail --msgbox "Switched to TXDE Basic!" 8 40
        fi
    else
        if whiptail --title "Switch Mode" --yesno "Switch to TXDE Full? (Installs App Store, Recycle Bin, Firefox)" 10 60; then
            SHOW_PROGRESS "Switching to TXDE Full" 0 3
            cat << 'INNEREOF' > /usr/local/bin/txde-appstore
#!/bin/bash
APP=$(whiptail --title "App Store" --inputbox "Enter package name:" 10 50 3>&1 1>&2 2>&3)
if [ -n "$APP" ]; then xterm -e "apt-get install -y $APP; read -p 'Done. Press Enter'"; fi
INNEREOF
            chmod +x /usr/local/bin/txde-appstore
            cat << 'INNEREOF' > ~/Desktop/appstore.desktop
[Desktop Entry]
Name=App Store
Exec=/usr/local/bin/txde-appstore
Icon=system-software-install
Type=Application
Terminal=false
INNEREOF
            chmod +x ~/Desktop/appstore.desktop
            SHOW_PROGRESS "Switching to TXDE Full" 1 3
            cat << 'INNEREOF' > ~/Desktop/recycle-bin.desktop
[Desktop Entry]
Name=Recycle Bin
Exec=pcmanfm ~/.local/share/Trash/files
Icon=user-trash
Type=Application
Terminal=false
INNEREOF
            chmod +x ~/Desktop/recycle-bin.desktop
            SHOW_PROGRESS "Switching to TXDE Full" 2 3
            apt-get install -y firefox-esr >/dev/null 2>&1
            cat << 'INNEREOF' > ~/Desktop/firefox.desktop
[Desktop Entry]
Name=Firefox
Exec=firefox-esr
Icon=firefox
Type=Application
Terminal=false
INNEREOF
            chmod +x ~/Desktop/firefox.desktop
            SHOW_PROGRESS "Switching to TXDE Full" 3 3
            whiptail --msgbox "Switched to TXDE Full!" 8 40
        fi
    fi
    MAIN_MENU
}
TOGGLE_CONTROL_PANEL() {
    if [ -f ~/Desktop/control-panel.desktop ]; then
        if whiptail --title "Control Panel" --yesno "Uninstall Control Panel?" 10 60; then apt-get remove -y lxappearance obconf >/dev/null 2>&1; rm -f ~/Desktop/control-panel.desktop /usr/local/bin/termo-control-panel; whiptail --msgbox "Control Panel disabled." 8 40; fi
    else
        if whiptail --title "Control Panel" --yesno "Install Control Panel?" 10 60; then
            SHOW_PROGRESS "Installing Control Panel" 0 2; apt-get install -y lxappearance obconf >/dev/null 2>&1; SHOW_PROGRESS "Installing Control Panel" 1 2
            cat << 'INNEREOF' > /usr/local/bin/termo-control-panel
#!/bin/bash
CHOICE=$(whiptail --title "Control Panel" --menu "Choose setting:" 14 55 3 "1" "Change Wallpaper" "2" "Themes" "3" "Window Settings" 3>&1 1>&2 2>&3)
case $CHOICE in 1) pcmanfm --desktop-pref ;; 2) lxappearance ;; 3) obconf ;; esac
INNEREOF
            chmod +x /usr/local/bin/termo-control-panel
            cat << 'INNEREOF' > ~/Desktop/control-panel.desktop
[Desktop Entry]
Name=Control Panel
Exec=/usr/local/bin/termo-control-panel
Icon=preferences-system
Type=Application
Terminal=false
INNEREOF
            chmod +x ~/Desktop/control-panel.desktop
            SHOW_PROGRESS "Installing Control Panel" 2 2; whiptail --msgbox "Control Panel installed!" 9 55
        fi
    fi
    MAIN_MENU
}
TOGGLE_FIREFOX() { whiptail --msgbox "Use the Mode Switcher to handle Firefox." 8 50; MAIN_MENU; }
TOGGLE_APPSTORE() { whiptail --msgbox "Use the Mode Switcher to handle the App Store." 8 50; MAIN_MENU; }
MAIN_MENU
EOF
chmod +x "$PD_ROOT/usr/local/bin/txde-features"

# 3. Base Shortcuts
cat << 'EOF' > "$PD_ROOT/root/Desktop/mypc.desktop"
[Desktop Entry]
Name=My PC
Exec=pcmanfm ~
Icon=system-file-manager
Type=Application
Terminal=false
EOF
cat << 'EOF' > "$PD_ROOT/root/Desktop/terminal.desktop"
[Desktop Entry]
Name=Terminal
Exec=xterm
Icon=utilities-terminal
Type=Application
Terminal=false
EOF
cat << 'EOF' > "$PD_ROOT/root/Desktop/settings.desktop"
[Desktop Entry]
Name=Settings
Exec=pcmanfm ~/.config
Icon=preferences-desktop
Type=Application
Terminal=false
EOF
cat << 'EOF' > "$PD_ROOT/root/Desktop/features.desktop"
[Desktop Entry]
Name=Features App
Exec=xterm -e /usr/local/bin/txde-features
Icon=preferences-system-session
Type=Application
Terminal=false
EOF
chmod +x "$PD_ROOT/root/Desktop/"*.desktop

# 4. Full Apps
if [ "$TYPE_CHOICE" == "Full" ]; then
    cat << 'EOF' > "$PD_ROOT/usr/local/bin/txde-appstore"
#!/bin/bash
APP=$(whiptail --title "App Store" --inputbox "Enter package name:" 10 50 3>&1 1>&2 2>&3)
if [ -n "$APP" ]; then xterm -e "apt-get install -y $APP; read -p 'Done. Press Enter'"; fi
EOF
    chmod +x "$PD_ROOT/usr/local/bin/txde-appstore"
    
    cat << 'EOF' > "$PD_ROOT/root/Desktop/appstore.desktop"
[Desktop Entry]
Name=App Store
Exec=/usr/local/bin/txde-appstore
Icon=system-software-install
Type=Application
Terminal=false
EOF
    cat << 'EOF' > "$PD_ROOT/root/Desktop/recycle-bin.desktop"
[Desktop Entry]
Name=Recycle Bin
Exec=pcmanfm ~/.local/share/Trash/files
Icon=user-trash
Type=Application
Terminal=false
EOF
    cat << 'EOF' > "$PD_ROOT/root/Desktop/firefox.desktop"
[Desktop Entry]
Name=Firefox
Exec=firefox-esr
Icon=firefox
Type=Application
Terminal=false
EOF
    chmod +x "$PD_ROOT/root/Desktop/"*.desktop
fi

echo "OS_TYPE=\"$TYPE_CHOICE\"" > "$PD_ROOT/etc/termo-os.conf"
echo "OS_DE=\"$DE_NAME\"" >> "$PD_ROOT/etc/termo-os.conf"
echo "VNC_TYPE=\"$VNC_APP_NAME\"" >> "$PD_ROOT/etc/termo-os.conf"
echo "VNC_USER=\"$USER_NAME\"" > "$PD_ROOT/etc/termo-vnc.conf"
echo "VNC_PORT=\"5901\"" >> "$PD_ROOT/etc/termo-vnc.conf"
echo "VNC_DISPLAY=\":1\"" >> "$PD_ROOT/etc/termo-vnc.conf"
echo "VNC_PASS=\"$USER_PASS\"" >> "$PD_ROOT/etc/termo-vnc.conf"
echo "$USER_HOSTNAME" > "$PD_ROOT/etc/hostname"
echo "127.0.0.1 localhost $USER_HOSTNAME" > "$PD_ROOT/etc/hosts"

cat << 'EOF' > "$PD_ROOT/etc/os-release"
PRETTY_NAME="TermoOS (TxDE Edition)"
NAME="TermoOS"
VERSION_ID="1.0"
VERSION="1.0"
VERSION_CODENAME=trixie
ID=debian
ID_LIKE=debian
HOME_URL="https://github.com/ryxierindo/Linux-Mobile"
EOF

cat << 'EOF' > "$PD_ROOT/root/.vnc/xstartup"
#!/bin/bash
xrdb $HOME/.Xresources
source /etc/termo-os.conf
export XDG_SESSION_TYPE=x11
xsetroot -solid "#0078d7" &
pcmanfm --desktop &
tint2 &
exec openbox-session
EOF
chmod +x "$PD_ROOT/root/.vnc/xstartup"

cat << 'EOF' > "$PD_ROOT/usr/local/bin/vnc-details"
#!/bin/bash
source /etc/termo-vnc.conf
source /etc/termo-os.conf
echo '==========================='
echo '   TermoOS Connection Info '
echo '==========================='
if [ "$VNC_TYPE" == "NoVNC" ]; then
    echo "Type       : Browser (NoVNC)"
    echo "URL        : http://127.0.0.1:6080/vnc.html"
    echo "Password   : $VNC_PASS"
else
    echo 'IP Address : 127.0.0.1'
    echo "Port       : $VNC_PORT"
    echo "Username   : $VNC_USER"
    echo "Password   : $VNC_PASS"
fi
echo '==========================='
EOF
chmod +x "$PD_ROOT/usr/local/bin/vnc-details"

cat << 'EOF' > "$PD_ROOT/usr/local/bin/vnc-setup"
#!/bin/bash
source /etc/termo-vnc.conf
vncserver -kill $VNC_DISPLAY > /dev/null 2>&1
pkill websockify > /dev/null 2>&1

NEW_USER=$(dialog --clear --title "VNC Setup" --inputbox "Enter new Username:" 8 40 "$VNC_USER" 3>&1 1>&2 2>&3)
NEW_PORT=$(dialog --clear --title "VNC Setup" --inputbox "Enter new VNC Port (e.g. 5901, 5902):" 8 40 "$VNC_PORT" 3>&1 1>&2 2>&3)
NEW_PASS=$(dialog --clear --title "VNC Setup" --passwordbox "Enter new VNC Password:" 8 40 3>&1 1>&2 2>&3)

if [ -z "$NEW_PASS" ] || [ -z "$NEW_PORT" ]; then clear; echo "Setup cancelled."; exit 1; fi

DISPLAY_NUM=$(($NEW_PORT - 5900))
if [ $DISPLAY_NUM -lt 1 ]; then DISPLAY_NUM=1; NEW_PORT=5901; fi

echo "VNC_USER=\"$NEW_USER\"" > /etc/termo-vnc.conf
echo "VNC_PORT=\"$NEW_PORT\"" >> /etc/termo-vnc.conf
echo "VNC_DISPLAY=\":$DISPLAY_NUM\"" >> /etc/termo-vnc.conf
echo "VNC_PASS=\"$NEW_PASS\"" >> /etc/termo-vnc.conf

echo "$NEW_PASS" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
clear
echo "VNC Configuration Updated Successfully!"
echo "Run 'boot Termo' to restart the server with your new settings."
EOF
chmod +x "$PD_ROOT/usr/local/bin/vnc-setup"

cat << 'EOF' > "$PD_ROOT/usr/local/bin/boot-termo"
#!/bin/bash
if [ "$1" == "details" ]; then vnc-details; exit 0; fi
if [ "$1" == "setup" ]; then vnc-setup; exit 0; fi

source /etc/termo-vnc.conf
source /etc/termo-os.conf

START_TIME=$(date +%s)
show_gui() {
    local STEP=$1; local TOTAL=$2; local DESC=$3; local TITLE=$4
    local ELAPSED_MINS=$(( ($(date +%s) - START_TIME) / 60 ))
    local PERCENT=$((STEP * 100 / TOTAL))
    echo "$PERCENT" | dialog --title "$TITLE" --backtitle "TermoOS Startup" \
    --gauge "Process $STEP/$TOTAL: $DESC\n\nELAPSED : $ELAPSED_MINS min" 10 45
}

show_gui 1 3 "cleaning old sessions" "TermoOS Startup"
vncserver -kill $VNC_DISPLAY > /dev/null 2>&1
pkill websockify > /dev/null 2>&1
sleep 1

show_gui 2 3 "launching graphical desktop" "TermoOS Startup"
vncserver $VNC_DISPLAY -geometry 1280x720 -depth 24 -localhost no -SecurityTypes VncAuth,None -extension MIT-SHM > /dev/null 2>&1
sleep 1

show_gui 3 3 "finalizing setup" "TermoOS Startup"
if [ "$VNC_TYPE" == "NoVNC" ]; then
    websockify -D --web=/usr/share/novnc/ 6080 localhost:$VNC_PORT > /dev/null 2>&1
fi
sleep 1

clear
if [ "$VNC_TYPE" == "NoVNC" ]; then
    echo "NoVNC Server started successfully!"
    echo "Open your mobile browser and go to: http://127.0.0.1:6080/vnc.html"
else
    echo "TermoOS Desktop started successfully on port $VNC_PORT!"
    echo "Type 'boot Termo details' to view login info, or 'boot Termo setup' to change it."
fi
EOF
chmod +x "$PD_ROOT/usr/local/bin/boot-termo"

ln -sf boot-termo "$PD_ROOT/usr/local/bin/vnc"

cat << 'EOF' > "$PD_ROOT/usr/local/bin/boot"
#!/bin/bash
if [ "$1" == "Termo" ] || [ "$1" == "termo" ]; then shift; boot-termo "$@"; else boot-termo "$@"; fi
EOF
chmod +x "$PD_ROOT/usr/local/bin/boot"

echo "$USER_PASS" > "$PD_ROOT/tmp/vncpass.txt"
proot-distro login debian -- bash -c "mkdir -p ~/.config/tigervnc ~/.vnc && cat /tmp/vncpass.txt | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd && cp ~/.vnc/passwd ~/.config/tigervnc/passwd && chmod 600 ~/.config/tigervnc/passwd" > /dev/null 2>&1
rm -f "$PD_ROOT/tmp/vncpass.txt"

show_gui 7 $TOTAL_MODULES "termo-update (smart app)" "Installing TermoOS" 1

# ==========================================
# Windows-Style GUI Updater (termo-update)
# ==========================================
cat << 'EOF' > "$PD_ROOT/usr/local/bin/termo-update"
#!/bin/bash
export NEWT_COLORS='root=white,blue:window=white,blue:border=white,blue:button=white,blue'
source /etc/termo-os.conf

MAIN_MENU() {
    CHOICE=$(whiptail --title "TermoOS Updater & Recovery" --menu "Windows-Style Update & Recovery\nCurrent Version: 1.0 (TxDE Edition)" 15 65 4 \
    "1" "Check for updates" \
    "2" "Reset the OS (Wipe Data/Configs, Keep Base)" \
    "3" "Reinstall the OS (Factory Reset)" \
    "4" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) CHECK_UPDATES ;;
        2) RESET_OS ;;
        3) REINSTALL_OS ;;
        4) exit 0 ;;
        *) exit 0 ;;
    esac
}

CHECK_UPDATES() {
    {
        echo "10"; apt-get update -y >/dev/null 2>&1
        echo "50"; UPGRADES=$(apt-get -s upgrade | awk '/^Inst/
