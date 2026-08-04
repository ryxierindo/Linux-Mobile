#!/bin/bash

# ==========================================
# TermoOS Core Installer (The Ultimate Edition)
# ==========================================

export TERM=xterm-256color
export PROOT_NO_WARNINGS=1

if [ -f "termo_config.env" ]; then source termo_config.env; else exit 1; fi

PD_ROOT="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/installed-rootfs/debian"

START_TIME=$(date +%s)
show_gui() {
    local STEP=$1; local TOTAL=$2; local DESC=$3; local TITLE=$4; local BASE_EST=$5
    local ELAPSED_MINS=$(( ($(date +%s) - START_TIME) / 60 ))
    local PERCENT=$((STEP * 100 / TOTAL))
    
    # Calculate Estimated Time based on the device's RAM speed factor
    local PREDICTED_EST=$(echo "$BASE_EST * $SPEED_FACTOR" | bc | awk '{print int($1+0.5)}')
    if [ -z "$PREDICTED_EST" ]; then PREDICTED_EST=$BASE_EST; fi

    echo "$PERCENT" | dialog --title "$TITLE" --backtitle "TermoOS Build Engine" \
    --gauge "Module $STEP/$TOTAL: $DESC\n\nEST: ~$PREDICTED_EST min     ELAPSED: $ELAPSED_MINS min" 10 50
}

TOTAL=8
ENV_VARS="export PROOT_NO_WARNINGS=1; export DEBIAN_FRONTEND=noninteractive"
APT_OPTS="-yq --no-install-recommends"

show_gui 1 $TOTAL "Installing Linux Base" "TermoOS Build" 2
proot-distro install debian > /dev/null 2>&1

show_gui 2 $TOTAL "Configuring Timezone & Region" "TermoOS Build" 1
proot-distro login debian -- bash -c "$ENV_VARS; apt-get update -y; apt-get install -y tzdata; ln -sf /usr/share/zoneinfo/$USER_TZ /etc/localtime; echo $USER_TZ > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata" > /dev/null 2>&1

show_gui 3 $TOTAL "Installing UI & Wallpapers" "TermoOS Build" 4
proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS openbox tint2 pcmanfm xterm whiptail x11-xserver-utils trash-cli xfonts-base desktop-base" > /dev/null 2>&1

show_gui 4 $TOTAL "Installing VNC & Tools" "TermoOS Build" 2
if [ "$VNC_APP_NAME" == "NoVNC" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tightvncserver dbus-x11 novnc websockify" > /dev/null 2>&1
else
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tightvncserver dbus-x11" > /dev/null 2>&1
fi

show_gui 5 $TOTAL "Installing Desktop Apps" "TermoOS Build" 3
if [ "$TYPE_CHOICE" == "Basic" ]; then
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS nano dialog curl sudo mousepad galculator" > /dev/null 2>&1
else
    proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS firefox-esr wget nano dialog curl sudo mousepad galculator htop neofetch" > /dev/null 2>&1
fi

show_gui 6 $TOTAL "Configuring Desktop Assets" "TermoOS Build" 1
mkdir -p "$PD_ROOT/root/Desktop" "$PD_ROOT/root/.config/tint2" "$PD_ROOT/root/.config/pcmanfm/default" "$PD_ROOT/root/.vnc" "$PD_ROOT/usr/local/bin" "$PD_ROOT/etc" "$PD_ROOT/tmp"

# Pre-set Wallpaper Config
cat << 'EOF' > "$PD_ROOT/root/.config/pcmanfm/default/pcmanfm.conf"
[desktop]
wallpaper_mode=stretch
wallpaper=/usr/share/images/desktop-base/default
desktop_bg=#0078d7
desktop_fg=#ffffff
EOF

# Startup script with Mouse Arrow fix
cat << 'EOF' > "$PD_ROOT/root/.vnc/xstartup"
#!/bin/sh
export DISPLAY=:1
export NO_AT_BRIDGE=1
xsetroot -cursor_name left_ptr &
tint2 &
pcmanfm --desktop &
exec openbox-session
EOF
chmod +x "$PD_ROOT/root/.vnc/xstartup"

# Base Shortcuts
cat << 'EOF' > "$PD_ROOT/root/Desktop/terminal.desktop"
[Desktop Entry]
Name=Terminal
Exec=xterm
Icon=utilities-terminal
Type=Application
EOF
cat << 'EOF' > "$PD_ROOT/root/Desktop/editor.desktop"
[Desktop Entry]
Name=Text Editor
Exec=mousepad
Icon=accessories-text-editor
Type=Application
EOF
cat << 'EOF' > "$PD_ROOT/root/Desktop/calculator.desktop"
[Desktop Entry]
Name=Calculator
Exec=galculator
Icon=accessories-calculator
Type=Application
EOF

show_gui 7 $TOTAL "Building App Store & Updater" "TermoOS Build" 1

# Feature Manager
cat << 'EOF' > "$PD_ROOT/usr/local/bin/txde-features"
#!/bin/bash
export NEWT_COLORS='root=white,blue:window=white,blue:border=white,blue:button=white,blue'
CHOICE=$(whiptail --title "TermoOS Features App" --menu "Select option:" 12 60 3 \
"1" "Enable/Disable Control Panel" "2" "Toggle Desktop Recycle Bin" "3" "Exit" 3>&1 1>&2 2>&3)
case $CHOICE in
    1) if [ -f ~/Desktop/control-panel.desktop ]; then apt-get remove -y lxappearance obconf >/dev/null 2>&1; rm -f ~/Desktop/control-panel.desktop; whiptail --msgbox "Removed." 8 40; else apt-get install -y lxappearance obconf >/dev/null 2>&1; echo -e "[Desktop Entry]\nName=Control Panel\nExec=lxappearance\nIcon=preferences-system\nType=Application" > ~/Desktop/control-panel.desktop; chmod +x ~/Desktop/control-panel.desktop; whiptail --msgbox "Installed." 8 40; fi ;;
    2) if [ -f ~/Desktop/recycle-bin.desktop ]; then rm -f ~/Desktop/recycle-bin.desktop; else echo -e "[Desktop Entry]\nName=Recycle Bin\nExec=pcmanfm ~/.local/share/Trash/files\nIcon=user-trash\nType=Application" > ~/Desktop/recycle-bin.desktop; chmod +x ~/Desktop/recycle-bin.desktop; fi; whiptail --msgbox "Toggled!" 8 40 ;;
    3) exit 0 ;;
esac
EOF
chmod +x "$PD_ROOT/usr/local/bin/txde-features"

# Updater & Reset Script
cat << 'EOF' > "$PD_ROOT/usr/local/bin/termo-update"
#!/bin/bash
export NEWT_COLORS='root=white,blue:window=white,blue:border=white,blue:button=white,blue'
CHOICE=$(whiptail --title "TermoOS Updater & Recovery" --menu "Windows-Style Update & Recovery" 14 65 4 \
"1" "Check for updates" "2" "Reset OS (Wipe Data, Keep Base)" "3" "Reinstall OS (Factory Reset)" "4" "Exit" 3>&1 1>&2 2>&3)

case $CHOICE in
    1) apt-get update -y && apt-get upgrade -y; read -p "Updates finished. Press Enter." ;;
    2) whiptail --title "Reset OS" --yesno "Wipe desktop and settings?" 10 50 && rm -rf /root/Desktop /root/.config/tint2 /root/.vnc /etc/termo-* ;;
    3) whiptail --title "Factory Reset" --msgbox "To perform a complete factory wipe, you must exit this session.\n\n1. Type 'exit' and press Enter.\n2. Run this command in Termux:\n\nproot-distro remove debian && bash install.sh" 12 60 ;;
    4) exit 0 ;;
esac
EOF
chmod +x "$PD_ROOT/usr/local/bin/termo-update"

# App Store Logic (If Full Mode)
if [ "$TYPE_CHOICE" == "Full" ]; then
    cat << 'EOF' > "$PD_ROOT/usr/local/bin/txde-appstore"
#!/bin/bash
APP=$(whiptail --title "App Store" --inputbox "Enter package name to install:" 10 50 3>&1 1>&2 2>&3)
if [ -n "$APP" ]; then xterm -e "apt-get install -y $APP; read -p 'Done. Press Enter'"; fi
EOF
    chmod +x "$PD_ROOT/usr/local/bin/txde-appstore"
    echo -e "[Desktop Entry]\nName=App Store\nExec=/usr/local/bin/txde-appstore\nIcon=system-software-install\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/appstore.desktop"
    echo -e "[Desktop Entry]\nName=Firefox\nExec=firefox-esr\nIcon=firefox\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/firefox.desktop"
fi

# Add System Shortcuts
echo -e "[Desktop Entry]\nName=Updater\nExec=xterm -e /usr/local/bin/termo-update\nIcon=system-software-update\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/updater.desktop"
echo -e "[Desktop Entry]\nName=Features\nExec=xterm -e /usr/local/bin/txde-features\nIcon=preferences-system-session\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/features.desktop"
chmod +x "$PD_ROOT/root/Desktop/"*.desktop

show_gui 8 $TOTAL "Building System Commands" "TermoOS Build" 1

echo "VNC_USER=\"$USER_NAME\"" > "$PD_ROOT/etc/termo-vnc.conf"
echo "VNC_PORT=\"5901\"" >> "$PD_ROOT/etc/termo-vnc.conf"
echo "VNC_DISPLAY=\":1\"" >> "$PD_ROOT/etc/termo-vnc.conf"
echo "VNC_PASS=\"$USER_PASS\"" >> "$PD_ROOT/etc/termo-vnc.conf"
echo "VNC_TYPE=\"$VNC_APP_NAME\"" >> "$PD_ROOT/etc/termo-vnc.conf"

# The GUI Boot Command
cat << 'EOF' > "$PD_ROOT/usr/local/bin/boot-termo"
#!/bin/bash
source /etc/termo-vnc.conf

if [ "$1" == "/details" ]; then
    if [ "$VNC_TYPE" == "NoVNC" ]; then
        whiptail --title "TermoOS Details" --msgbox "Type: Browser (NoVNC)\nURL: http://127.0.0.1:6080/vnc.html\nPassword: $VNC_PASS" 10 50
    else
        whiptail --title "TermoOS Details" --msgbox "Type: App (RealVNC)\nIP Address: 127.0.0.1\nPort: $VNC_PORT\nUsername: $VNC_USER\nPassword: $VNC_PASS" 12 50
    fi
    exit 0
fi

if [ "$1" == "/setup" ]; then
    NEW_PORT=$(dialog --title "VNC Setup" --inputbox "Enter new VNC Port (e.g. 5901):" 8 40 "$VNC_PORT" 3>&1 1>&2 2>&3)
    if [ -z "$NEW_PORT" ]; then exit 1; fi
    NEW_PASS=$(dialog --title "VNC Setup" --passwordbox "Enter new VNC Password:" 8 40 3>&1 1>&2 2>&3)
    if [ -z "$NEW_PASS" ]; then exit 1; fi
    DISPLAY_NUM=$(($NEW_PORT - 5900))
    if [ $DISPLAY_NUM -lt 1 ]; then DISPLAY_NUM=1; NEW_PORT=5901; fi
    
    echo "VNC_USER=\"$VNC_USER\"" > /etc/termo-vnc.conf
    echo "VNC_PORT=\"$NEW_PORT\"" >> /etc/termo-vnc.conf
    echo "VNC_DISPLAY=\":$DISPLAY_NUM\"" >> /etc/termo-vnc.conf
    echo "VNC_PASS=\"$NEW_PASS\"" >> /etc/termo-vnc.conf
    echo "$NEW_PASS" | vncpasswd -f > ~/.vnc/passwd
    whiptail --title "Success" --msgbox "Configuration updated! Run 'boot-termo' to apply." 8 45
    exit 0
fi

START_TIME=$(date +%s)
show_boot() {
    PERCENT=$(( $1 * 100 / $2 ))
    echo "$PERCENT" | dialog --title "TermoOS Boot Engine" --gauge "Status: $3" 8 50
}

show_boot 1 3 "Cleaning old desktop sessions..."
tightvncserver -kill $VNC_DISPLAY > /dev/null 2>&1
pkill websockify > /dev/null 2>&1
sleep 1

show_boot 2 3 "Launching GUI Environment..."
tightvncserver $VNC_DISPLAY -geometry 1280x720 -depth 24 > /dev/null 2>&1
sleep 1

show_boot 3 3 "Finalizing protocols..."
if [ "$VNC_TYPE" == "NoVNC" ]; then
    websockify -D --web=/usr/share/novnc/ 6080 localhost:$VNC_PORT > /dev/null 2>&1
fi
sleep 1

if [ "$VNC_TYPE" == "NoVNC" ]; then
    dialog --title "Boot Successful" --msgbox "NoVNC Server is running!\n\nOpen your browser to:\nhttp://127.0.0.1:6080/vnc.html" 9 50
else
    dialog --title "Boot Successful" --msgbox "RealVNC Desktop is running!\n\nConnect to: 127.0.0.1:$VNC_PORT" 8 45
fi
clear
EOF
chmod +x "$PD_ROOT/usr/local/bin/boot-termo"
ln -sf /usr/local/bin/boot-termo "$PD_ROOT/usr/bin/boot-termo"
ln -sf /usr/local/bin/termo-update "$PD_ROOT/usr/bin/termo-update"
ln -sf /usr/local/bin/txde-features "$PD_ROOT/usr/bin/txde-features"

# Set password silently
echo "$USER_PASS" > "$PD_ROOT/tmp/vncpass.txt"
proot-distro login debian -- bash -c "mkdir -p ~/.vnc && cat /tmp/vncpass.txt | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd" > /dev/null 2>&1
rm -f "$PD_ROOT/tmp/vncpass.txt" termo_config.env

clear
echo "========================================"
echo " Success! TermoOS is installed."
echo "========================================"
echo " Type: proot-distro login debian"
echo " Once inside, your core commands are:"
echo " - boot-termo          (Starts the desktop)"
echo " - boot-termo /details (Shows login info)"
echo " - boot-termo /setup   (Change port/pass)"
echo " - termo-update        (Updater & Recovery)"
echo " - txde-features       (Desktop Features)"
echo "========================================"
