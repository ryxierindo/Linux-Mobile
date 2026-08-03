#!/bin/bash

# ==========================================
# TermoOS Core Installer (Part 2)
# Handles OS Build & TxDE Extraction
# ==========================================

export TERM=xterm-256color
export PROOT_NO_WARNINGS=1

# Load variables from Part 1
if [ -f "termo_config.env" ]; then
    source termo_config.env
else
    echo "[-] Error: Configuration file missing. Please run install.sh first."
    exit 1
fi

PD_ROOT="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/installed-rootfs/debian"

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

    echo "$PERCENT" | dialog --title "$TITLE" --backtitle "TermoOS Build Engine" \
    --gauge "Module $STEP/$TOTAL: $DESC\n\nEST : ~$PREDICTED_EST min     ELAPSED : $ELAPSED_MINS min" 10 45
}

# ==========================================
# OS INSTALLATION LOGIC
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
if [ "$VNC_APP_NAME" == "NoVNC" ]; then
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
# TXDE CONFIGURATION (Direct Writes)
# ==========================================
show_gui 6 $TOTAL_MODULES "vnc-config (startup scripts)" "Installing TermoOS" 1

mkdir -p "$PD_ROOT/root/Desktop" "$PD_ROOT/root/.config/tint2" "$PD_ROOT/root/.vnc" "$PD_ROOT/usr/local/bin" "$PD_ROOT/etc" "$PD_ROOT/tmp"

# Taskbar
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

# TxDE Features App
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

# Base Shortcuts
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

# Full Apps Logic
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

# Config Files
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

# VNC and System Utilities
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
    echo "Type 'boot Termo details' to view login info."
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

# Windows-Style GUI Updater
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
        echo "50"; UPGRADES=$(apt-get -s upgrade | awk '/^Inst/ { print $2 }' | wc -l)
        echo "100"; sleep 0.5
    } | whiptail --title "Windows Update" --gauge "Checking for updates..." 8 50 0

    if [ "$UPGRADES" -eq 0 ]; then
        whiptail --title "Windows Update" --msgbox "You're up to date!\n\nNo new updates are available for TermoOS." 8 45
    else
        if whiptail --title "Windows Update" --yesno "$UPGRADES updates are available.\n\nWould you like to install them now?" 10 50; then
            clear
            echo "=========================================="
            echo " Installing Updates... Please wait. "
            echo "=========================================="
            apt-get upgrade -y
            apt-get autoremove -y
            echo ""
            echo "Updates installed successfully! Press Enter to return."
            read -r
        fi
    fi
    MAIN_MENU
}

RESET_OS() {
    if whiptail --title "Reset the OS" --yesno "WARNING: This will delete your Desktop, UI settings, passwords, and VNC configs.\n\nThe base Debian OS will NOT be deleted.\n\nContinue with Reset?" 12 60; then
        clear
        echo "[+] Wiping TxDE configurations and user data..."
        rm -rf /root/Desktop /root/.config/tint2 /root/.vnc /root/.config/tigervnc
        rm -f /etc/termo-* /usr/local/bin/txde-* /usr/local/bin/vnc* /usr/local/bin/boot* /usr/local/bin/termo-update
        
        export DEBIAN_FRONTEND=noninteractive
        echo "[+] Removing UI packages..."
        apt-get purge -y openbox tint2 pcmanfm xterm whiptail firefox-esr tigervnc-standalone-server tigervnc-tools novnc websockify > /dev/null 2>&1
        apt-get autoremove -y > /dev/null 2>&1
        
        echo ""
        echo "=========================================="
        echo " Reset Complete! "
        echo "=========================================="
        echo "TermoOS has been reset. Type 'exit' to leave the container,"
        echo "then run 'bash install.sh' to set it up again."
        exit 0
    else
        MAIN_MENU
    fi
}

REINSTALL_OS() {
    if whiptail --title "Reinstall the OS" --yesno "FATAL WARNING: This will completely ERASE the entire TermoOS system and PRoot container.\n\nAre you absolutely sure?" 10 60; then
        clear
        echo "=========================================="
        echo " Factory Reset / Reinstall Instructions "
        echo "=========================================="
        echo "To perform a complete factory wipe, you must exit this session."
        echo ""
        echo "1. Type 'exit' and press Enter."
        echo "2. Paste the following command into Termux:"
        echo ""
        echo "   proot-distro remove debian && bash install.sh"
        echo ""
        echo "Press Enter to acknowledge and close."
        read -r
        exit 0
    else
        MAIN_MENU
    fi
}
MAIN_MENU
EOF
chmod +x "$PD_ROOT/usr/local/bin/termo-update"

cat << 'EOF' > "$PD_ROOT/root/Desktop/updater.desktop"
[Desktop Entry]
Name=Updater
Comment=Check for TermoOS Updates
Exec=x-terminal-emulator -e "bash -c '/usr/local/bin/termo-update'"
Icon=system-software-update
Terminal=false
Type=Application
EOF
chmod +x "$PD_ROOT/root/Desktop/updater.desktop"

show_gui 8 $TOTAL_MODULES "termo-modules (app store script)" "Installing TermoOS" 1
curl -s https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/termo-modules.sh -o "$PD_ROOT/usr/local/bin/termo-modules"
chmod +x "$PD_ROOT/usr/local/bin/termo-modules"

# Cleanup Temp Vars
rm -f termo_config.env

sleep 1
clear
echo -e "\n\nSuccess! TermoOS (TxDE Edition) is installed."
echo "----------------------------------------"
echo "To enter TermoOS, type: proot-distro login debian"
echo "Inside TermoOS, your startup commands are:"
echo " - boot Termo          (Starts desktop with GUI loading bar)"
echo " - boot Termo details  (Shows login info)"
echo " - boot Termo setup    (Changes port/username/password)"
echo " - termo-update        (Windows-Style Updater & Reset tool)"
echo " - txde-features       (Opens the blu
