#!/bin/bash
# =======================================================
# TermoOS TxDE Engine Builder
# =======================================================

MODE="${1:-minimal}"

echo "[+] Updating TermoOS package database..."
apt-get update -y

echo "[+] Purging conflicting heavy desktop environments..."
apt-get purge -y xfce4* lxde* gnome* kde* xubuntu* jwm 2>/dev/null
apt-get autoremove -y

echo "[+] Installing TxDE Core Components..."
apt-get install -y openbox tint2 pcmanfm xterm whiptail x11-xserver-utils trash-cli

# Setup workspace
mkdir -p ~/Desktop ~/.config/tint2 ~/.vnc

echo "[+] Building Core System Apps..."

# 1. My PC
cat << 'EOF' > ~/Desktop/mypc.desktop
[Desktop Entry]
Name=My PC
Exec=pcmanfm ~
Icon=system-file-manager
Type=Application
Terminal=false
EOF

# 2. Terminal
cat << 'EOF' > ~/Desktop/terminal.desktop
[Desktop Entry]
Name=Terminal
Exec=xterm
Icon=utilities-terminal
Type=Application
Terminal=false
EOF

# 3. Settings
cat << 'EOF' > ~/Desktop/settings.desktop
[Desktop Entry]
Name=Settings
Exec=pcmanfm ~/.config
Icon=preferences-desktop
Type=Application
Terminal=false
EOF

# 4. Updater
cat << 'EOF' > /usr/local/bin/txde-updater
#!/bin/bash
whiptail --title "TermoOS System Updater" --infobox "Updating TermoOS OS packages...\nPlease wait." 8 45
apt-get update -y && apt-get upgrade -y
whiptail --title "TermoOS System Updater" --msgbox "TermoOS OS is completely up to date!" 8 45
EOF
chmod +x /usr/local/bin/txde-updater

cat << 'EOF' > ~/Desktop/updater.desktop
[Desktop Entry]
Name=Updater
Exec=xterm -e /usr/local/bin/txde-updater
Icon=system-software-update
Type=Application
Terminal=false
EOF

# 5. Features App (Protected - Never Deleted)
chmod +x txde-feature-manager.sh 2>/dev/null
cp txde-feature-manager.sh /usr/local/bin/txde-features 2>/dev/null
chmod +x /usr/local/bin/txde-features

cat << 'EOF' > ~/Desktop/features.desktop
[Desktop Entry]
Name=Features App
Exec=xterm -e /usr/local/bin/txde-features
Icon=preferences-system-session
Type=Application
Terminal=false
EOF

# Build Full DE apps if Full mode selected
if [ "$MODE" = "full" ]; then
    echo "[+] Installing Full DE components (App Store, Recycle Bin, Firefox)..."
    
    # Recycle Bin
    cat << 'EOF' > ~/Desktop/recycle-bin.desktop
[Desktop Entry]
Name=Recycle Bin
Exec=pcmanfm ~/.local/share/Trash/files
Icon=user-trash
Type=Application
Terminal=false
EOF

    # App Store
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

    # Firefox
    apt-get install -y firefox 2>/dev/null
    cat << 'EOF' > ~/Desktop/firefox.desktop
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
Terminal=false
EOF
fi

chmod +x ~/Desktop/*.desktop

echo "[+] Configuring Tint2 Taskbar..."
cat << 'EOF' > ~/.config/tint2/tint2rc
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

echo "[+] Configuring VNC Startup File..."
cat << 'EOF' > ~/.vnc/xstartup
#!/bin/bash
export XDG_SESSION_TYPE=x11

# Windows Blue Background
xsetroot -solid "#0078d7" &

# Enable Desktop Icons & Wallpaper support
pcmanfm --desktop &

# Start Windows Taskbar
tint2 &

# Launch Window Manager
exec openbox-session
EOF

chmod +x ~/.vnc/xstartup

echo "[+] TermoOS TxDE Installation Complete ($MODE mode)!"

