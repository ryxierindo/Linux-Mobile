#!/bin/bash
# =======================================================
# TermoOS TxDE - Features App & Mode Switcher
# =======================================================

export NEWT_COLORS='
root=white,blue
window=white,blue
border=white,blue
button=white,blue
'

SHOW_PROGRESS() {
    TITLE="$1"
    STEP="$2"
    TOTAL="$3"
    PERCENT=$(( STEP * 100 / TOTAL ))
    
    (
        echo "$PERCENT"
        sleep 0.5
    ) | whiptail --title "$TITLE" --gauge "Installing: $STEP/$TOTAL\nPlease wait..." 8 50 $PERCENT
}

MAIN_MENU() {
    # Check current DE mode
    if [ -f ~/Desktop/firefox.desktop ] || [ -f ~/Desktop/appstore.desktop ]; then
        CURRENT_MODE="Full DE"
    else
        CURRENT_MODE="Simplified/Minimal DE"
    fi

    CHOICE=$(whiptail --title "TermoOS TxDE Features App" --menu "Current Mode: [$CURRENT_MODE]\nSelect an option:" 16 65 5 \
    "1" "Switch DE Mode (Full <-> Minimal)" \
    "2" "Control Panel (Enable / Disable)" \
    "3" "Firefox Web Browser (Enable / Disable)" \
    "4" "App Store (Enable / Disable)" \
    "5" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) SWITCH_DE_MODE ;;
        2) TOGGLE_CONTROL_PANEL ;;
        3) TOGGLE_FIREFOX ;;
        4) TOGGLE_APPSTORE ;;
        5) exit 0 ;;
    esac
}

SWITCH_DE_MODE() {
    if [ -f ~/Desktop/firefox.desktop ] || [ -f ~/Desktop/appstore.desktop ]; then
        # Currently Full -> Switch to Minimal
        if whiptail --title "Switch to Minimal DE" --yesno "Switch TermoOS to Simplified / Minimal DE?\n(App Store, Recycle Bin, and Firefox shortcuts will be removed)" 10 60; then
            SHOW_PROGRESS "Switching to Minimal DE" 0 3
            rm -f ~/Desktop/appstore.desktop
            SHOW_PROGRESS "Switching to Minimal DE" 1 3
            rm -f ~/Desktop/recycle-bin.desktop
            SHOW_PROGRESS "Switching to Minimal DE" 2 3
            rm -f ~/Desktop/firefox.desktop
            SHOW_PROGRESS "Switching to Minimal DE" 3 3
            whiptail --title "TermoOS TxDE" --msgbox "Switched to Simplified / Minimal DE successfully!" 8 50
        fi
    else
        # Currently Minimal -> Switch to Full
        if whiptail --title "Switch to Full DE" --yesno "Switch TermoOS to Full DE?\n(Installs App Store, Recycle Bin, and Firefox)" 10 60; then
            SHOW_PROGRESS "Switching to Full DE" 0 3
            
            # 1. App Store
            cat << 'EOF' > /usr/local/bin/txde-appstore
#!/bin/bash
APP=$(whiptail --title "TermoOS App Store" --inputbox "Enter package name to install:" 10 50 3>&1 1>&2 2>&3)
if [ -n "$APP" ]; then
    xterm -e "apt-get install -y $APP; echo Done. Press Enter; read"
fi
EOF
            chmod +x /usr/local/bin/txde-appstore
            cat << 'EOF' > ~/Desktop/appstore.desktop
[Desktop Entry]
Name=App Store
Exec=/usr/local/bin/txde-appstore
Icon=system-software-install
Type=Application
Terminal=false
EOF
            chmod +x ~/Desktop/appstore.desktop
            SHOW_PROGRESS "Switching to Full DE" 1 3

            # 2. Recycle Bin
            cat << 'EOF' > ~/Desktop/recycle-bin.desktop
[Desktop Entry]
Name=Recycle Bin
Exec=pcmanfm ~/.local/share/Trash/files
Icon=user-trash
Type=Application
Terminal=false
EOF
            chmod +x ~/Desktop/recycle-bin.desktop
            SHOW_PROGRESS "Switching to Full DE" 2 3

            # 3. Firefox
            apt-get update -y >/dev/null 2>&1
            apt-get install -y firefox >/dev/null 2>&1
            cat << 'EOF' > ~/Desktop/firefox.desktop
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
Terminal=false
EOF
            chmod +x ~/Desktop/firefox.desktop
            SHOW_PROGRESS "Switching to Full DE" 3 3

            whiptail --title "TermoOS TxDE" --msgbox "Switched to Full DE successfully!" 8 50
        fi
    fi
    MAIN_MENU
}

TOGGLE_CONTROL_PANEL() {
    if [ -f ~/Desktop/control-panel.desktop ]; then
        if whiptail --title "Control Panel" --yesno "Control Panel is ENABLED. Uninstall it?" 10 60; then
            SHOW_PROGRESS "Uninstalling Control Panel" 0 2
            apt-get remove -y lxappearance obconf >/dev/null 2>&1
            SHOW_PROGRESS "Uninstalling Control Panel" 1 2
            rm -f ~/Desktop/control-panel.desktop /usr/local/bin/termo-control-panel
            SHOW_PROGRESS "Uninstalling Control Panel" 2 2
            whiptail --title "TermoOS" --msgbox "Control Panel disabled." 8 40
        fi
    else
        if whiptail --title "Control Panel" --yesno "Control Panel is NOT installed. Install it now?" 10 60; then
            SHOW_PROGRESS "Installing Control Panel" 0 3
            apt-get update -y >/dev/null 2>&1
            SHOW_PROGRESS "Installing Control Panel" 1 3
            apt-get install -y lxappearance obconf >/dev/null 2>&1
            SHOW_PROGRESS "Installing Control Panel" 2 3

            # Build Control Panel Utility
            cat << 'EOF' > /usr/local/bin/termo-control-panel
#!/bin/bash
CHOICE=$(whiptail --title "TermoOS Control Panel" --menu "Choose setting to configure:" 14 55 3 \
"1" "Change Desktop Wallpaper" \
"2" "Appearance & GTK Themes" \
"3" "Window Manager Settings" 3>&1 1>&2 2>&3)

case $CHOICE in
    1) pcmanfm --desktop-pref ;;
    2) lxappearance ;;
    3) obconf ;;
esac
EOF
            chmod +x /usr/local/bin/termo-control-panel

            # Create Desktop Shortcut
            cat << 'EOF' > ~/Desktop/control-panel.desktop
[Desktop Entry]
Name=Control Panel
Exec=/usr/local/bin/termo-control-panel
Icon=preferences-system
Type=Application
Terminal=false
EOF
            chmod +x ~/Desktop/control-panel.desktop
            SHOW_PROGRESS "Installing Control Panel" 3 3
            whiptail --title "TermoOS" --msgbox "Control Panel installed! You can now change wallpapers from Control Panel." 9 55
        fi
    fi
    MAIN_MENU
}

TOGGLE_FIREFOX() {
    if command -v firefox >/dev/null 2>&1; then
        if whiptail --title "Firefox" --yesno "Firefox is installed. Uninstall it?" 10 60; then
            SHOW_PROGRESS "Removing Firefox" 0 1
            apt-get remove -y firefox >/dev/null 2>&1
            SHOW_PROGRESS "Removing Firefox" 1 1
            rm -f ~/Desktop/firefox.desktop
            whiptail --title "TermoOS" --msgbox "Firefox removed." 8 40
        fi
    else
        if whiptail --title "Firefox" --yesno "Install Firefox Web Browser?" 10 60; then
            SHOW_PROGRESS "Installing Firefox" 0 2
            apt-get update -y >/dev/null 2>&1
            SHOW_PROGRESS "Installing Firefox" 1 2
            apt-get install -y firefox >/dev/null 2>&1
            SHOW_PROGRESS "Installing Firefox" 2 2
            cat << 'EOF' > ~/Desktop/firefox.desktop
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
Terminal=false
EOF
            chmod +x ~/Desktop/firefox.desktop
            whiptail --title "TermoOS" --msgbox "Firefox installed successfully!" 8 45
        fi
    fi
    MAIN_MENU
}

TOGGLE_APPSTORE() {
    if [ -f ~/Desktop/appstore.desktop ]; then
        if whiptail --title "App Store" --yesno "Disable App Store?" 10 60; then
            rm -f ~/Desktop/appstore.desktop
            whiptail --title "TermoOS" --msgbox "App Store shortcut removed." 8 45
        fi
    else
        if whiptail --title "App Store" --yesno "Enable App Store?" 10 60; then
            cat << 'EOF' > /usr/local/bin/txde-appstore
#!/bin/bash
APP=$(whiptail --title "TermoOS App Store" --inputbox "Enter package name to install:" 10 50 3>&1 1>&2 2>&3)
if [ -n "$APP" ]; then
    xterm -e "apt-get install -y $APP; echo Done. Press Enter; read"
fi
EOF
            chmod +x /usr/local/bin/txde-appstore
            cat << 'EOF' > ~/Desktop/appstore.desktop
[Desktop Entry]
Name=App Store
Exec=/usr/local/bin/txde-appstore
Icon=system-software-install
Type=Application
Terminal=false
EOF
            chmod +x ~/Desktop/appstore.desktop
            whiptail --title "TermoOS" --msgbox "App Store enabled!" 8 40
        fi
    fi
    MAIN_MENU
}

MAIN_MENU
