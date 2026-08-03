#!/bin/bash
export TERM=xterm-256color
export PROOT_NO_WARNINGS=1
if [ -f "termo_config.env" ]; then source termo_config.env; else echo "[-] Error: Run install.sh first."; exit 1; fi
PD_ROOT="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/installed-rootfs/debian"

ST=$(date +%s)
SG() { echo "$(( $1*100/$2 ))" | dialog --title "$4" --backtitle "TermoOS Build Engine" --gauge "Module $1/$2: $3\n\nELAPSED : $(( ($(date +%s)-ST)/60 )) min" 10 45; }

TM=8
ENV_VARS="export PROOT_NO_WARNINGS=1; export DEBIAN_FRONTEND=noninteractive; export DEBCONF_NONINTERACTIVE_SEEN=true"
APT_OPTS="-yq --no-install-recommends -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""

SG 1 $TM "proot (linux base)" "Installing TermoOS"
proot-distro install debian >/dev/null 2>&1
SG 2 $TM "apt-get (system updates)" "Installing TermoOS"
proot-distro login debian -- bash -c "$ENV_VARS; apt-get update -y && apt-get upgrade $APT_OPTS" >/dev/null 2>&1
SG 3 $TM "txde-engine (core UI)" "Installing TermoOS"
proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS openbox tint2 pcmanfm xterm whiptail x11-xserver-utils trash-cli" >/dev/null 2>&1
SG 4 $TM "remote display protocols" "Installing TermoOS"
if [ "$VNC_APP_NAME" == "NoVNC" ]; then proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tigervnc-standalone-server tigervnc-tools dbus-x11 novnc websockify" >/dev/null 2>&1
else proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS tigervnc-standalone-server tigervnc-tools dbus-x11" >/dev/null 2>&1; fi
SG 5 $TM "extras (apps & tools)" "Installing TermoOS"
if [ "$TYPE_CHOICE" == "Basic" ]; then proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS nano dialog curl sudo xterm" >/dev/null 2>&1
else proot-distro login debian -- bash -c "$ENV_VARS; apt-get install $APT_OPTS firefox-esr wget nano dialog curl sudo xterm htop neofetch" >/dev/null 2>&1; fi

SG 6 $TM "vnc-config (startup scripts)" "Installing TermoOS"
mkdir -p "$PD_ROOT/root/Desktop" "$PD_ROOT/root/.config/tint2" "$PD_ROOT/root/.vnc" "$PD_ROOT/usr/local/bin" "$PD_ROOT/etc" "$PD_ROOT/tmp"

cat << 'EOF' > "$PD_ROOT/root/.config/tint2/tint2rc"
panel_items = L:T:B:S
panel_position = bottom center horizontal
panel_size = 100% 40px
font_name = sans 9
taskbar_mode = single_desktop
task_text = 1
task_width = 150
time1_format = %H:%M
time2_format = %d-%m-%Y
systray_padding = 4
EOF

cat << 'EOF' > "$PD_ROOT/usr/local/bin/txde-features"
#!/bin/bash
export NEWT_COLORS='root=white,blue:window=white,blue:border=white,blue:button=white,blue'
SP() { (echo "$(($2*100/$3))"; sleep 0.5) | whiptail --title "$1" --gauge "Processing: $2/$3\nPlease wait..." 8 50 $(($2*100/$3)); }
MM() {
[ -f ~/Desktop/firefox.desktop ] && CM="TXDE Full" || CM="TXDE Basic"
CH=$(whiptail --title "Features App" --menu "Mode: [$CM]\nSelect option:" 16 65 5 "1" "Switch DE Mode" "2" "Control Panel" "3" "Firefox" "4" "App Store" "5" "Exit" 3>&1 1>&2 2>&3)
case $CH in 1) SDM ;; 2) TCP ;; 3) TFF ;; 4) TAS ;; 5) exit 0 ;; esac
}
SDM() {
if [ -f ~/Desktop/firefox.desktop ]; then
if whiptail --yesno "Switch to TXDE Basic?" 10 60; then SP "Basic" 0 2; rm -f ~/Desktop/appstore.desktop ~/Desktop/recycle-bin.desktop; SP "Basic" 1 2; rm -f ~/Desktop/firefox.desktop; SP "Basic" 2 2; whiptail --msgbox "Done!" 8 40; fi
else
if whiptail --yesno "Switch to TXDE Full?" 10 60; then SP "Full" 0 3; echo -e '#!/bin/bash\nAPP=$(whiptail --title "App Store" --inputbox "Package name:" 10 50 3>&1 1>&2 2>&3)\n[ -n "$APP" ] && xterm -e "apt-get install -y $APP"' > /usr/local/bin/txde-appstore; chmod +x /usr/local/bin/txde-appstore; echo -e "[Desktop Entry]\nName=App Store\nExec=/usr/local/bin/txde-appstore\nIcon=system-software-install\nType=Application\nTerminal=false" > ~/Desktop/appstore.desktop; chmod +x ~/Desktop/appstore.desktop; SP "Full" 1 3; echo -e "[Desktop Entry]\nName=Recycle Bin\nExec=pcmanfm ~/.local/share/Trash/files\nIcon=user-trash\nType=Application\nTerminal=false" > ~/Desktop/recycle-bin.desktop; chmod +x ~/Desktop/recycle-bin.desktop; SP "Full" 2 3; apt-get install -y firefox-esr >/dev/null 2>&1; echo -e "[Desktop Entry]\nName=Firefox\nExec=firefox-esr\nIcon=firefox\nType=Application\nTerminal=false" > ~/Desktop/firefox.desktop; chmod +x ~/Desktop/firefox.desktop; SP "Full" 3 3; whiptail --msgbox "Done!" 8 40; fi
fi; MM
}
TCP() {
if [ -f ~/Desktop/control-panel.desktop ]; then if whiptail --yesno "Uninstall Control Panel?" 10 60; then apt-get remove -y lxappearance obconf >/dev/null 2>&1; rm -f ~/Desktop/control-panel.desktop /usr/local/bin/termo-control-panel; fi
else if whiptail --yesno "Install Control Panel?" 10 60; then SP "Panel" 0 2; apt-get install -y lxappearance obconf >/dev/null 2>&1; SP "Panel" 1 2; echo -e '#!/bin/bash\nCH=$(whiptail --menu "Setting:" 14 55 3 "1" "Wallpaper" "2" "Themes" "3" "Window Settings" 3>&1 1>&2 2>&3)\ncase $CH in 1) pcmanfm --desktop-pref ;; 2) lxappearance ;; 3) obconf ;; esac' > /usr/local/bin/termo-control-panel; chmod +x /usr/local/bin/termo-control-panel; echo -e "[Desktop Entry]\nName=Control Panel\nExec=/usr/local/bin/termo-control-panel\nIcon=preferences-system\nType=Application\nTerminal=false" > ~/Desktop/control-panel.desktop; chmod +x ~/Desktop/control-panel.desktop; SP "Panel" 2 2; fi; fi; MM
}
TFF() { whiptail --msgbox "Use Mode Switcher" 8 40; MM; }
TAS() { whiptail --msgbox "Use Mode Switcher" 8 40; MM; }
MM
EOF
chmod +x "$PD_ROOT/usr/local/bin/txde-features"

echo -e "[Desktop Entry]\nName=My PC\nExec=pcmanfm ~\nIcon=system-file-manager\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/mypc.desktop"
echo -e "[Desktop Entry]\nName=Terminal\nExec=xterm\nIcon=utilities-terminal\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/terminal.desktop"
echo -e "[Desktop Entry]\nName=Settings\nExec=pcmanfm ~/.config\nIcon=preferences-desktop\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/settings.desktop"
echo -e "[Desktop Entry]\nName=Features App\nExec=xterm -e /usr/local/bin/txde-features\nIcon=preferences-system-session\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/features.desktop"
chmod +x "$PD_ROOT/root/Desktop/"*.desktop

if [ "$TYPE_CHOICE" == "Full" ]; then
echo -e '#!/bin/bash\nAPP=$(whiptail --title "App Store" --inputbox "Enter package name:" 10 50 3>&1 1>&2 2>&3)\n[ -n "$APP" ] && xterm -e "apt-get install -y $APP; read -p Done"' > "$PD_ROOT/usr/local/bin/txde-appstore"; chmod +x "$PD_ROOT/usr/local/bin/txde-appstore"
echo -e "[Desktop Entry]\nName=App Store\nExec=/usr/local/bin/txde-appstore\nIcon=system-software-install\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/appstore.desktop"
echo -e "[Desktop Entry]\nName=Recycle Bin\nExec=pcmanfm ~/.local/share/Trash/files\nIcon=user-trash\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/recycle-bin.desktop"
echo -e "[Desktop Entry]\nName=Firefox\nExec=firefox-esr\nIcon=firefox\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/firefox.desktop"
chmod +x "$PD_ROOT/root/Desktop/"*.desktop
fi

{ echo "OS_TYPE=\"$TYPE_CHOICE\""; echo "OS_DE=\"$DE_NAME\""; echo "VNC_TYPE=\"$VNC_APP_NAME\""; } > "$PD_ROOT/etc/termo-os.conf"
{ echo "VNC_USER=\"$USER_NAME\""; echo "VNC_PORT=\"5901\""; echo "VNC_DISPLAY=\":1\""; echo "VNC_PASS=\"$USER_PASS\""; } > "$PD_ROOT/etc/termo-vnc.conf"
echo "$USER_HOSTNAME" > "$PD_ROOT/etc/hostname"
echo "127.0.0.1 localhost $USER_HOSTNAME" > "$PD_ROOT/etc/hosts"
echo -e 'PRETTY_NAME="TermoOS (TxDE)"\nNAME="TermoOS"\nVERSION_ID="1.0"\nID=debian\nHOME_URL="https://github.com/ryxierindo/Linux-Mobile"' > "$PD_ROOT/etc/os-release"

echo -e '#!/bin/bash\nxrdb $HOME/.Xresources\nsource /etc/termo-os.conf\nexport XDG_SESSION_TYPE=x11\nxsetroot -solid "#0078d7" &\npcmanfm --desktop &\ntint2 &\nexec openbox-session' > "$PD_ROOT/root/.vnc/xstartup"
chmod +x "$PD_ROOT/root/.vnc/xstartup"

cat << 'EOF' > "$PD_ROOT/usr/local/bin/vnc-details"
#!/bin/bash
source /etc/termo-vnc.conf; source /etc/termo-os.conf
echo '==========================='; echo '   TermoOS Connection Info '; echo '==========================='
if [ "$VNC_TYPE" == "NoVNC" ]; then echo "Type       : Browser (NoVNC)"; echo "URL        : http://127.0.0.1:6080/vnc.html"; echo "Password   : $VNC_PASS"
else echo 'IP Address : 127.0.0.1'; echo "Port       : $VNC_PORT"; echo "Username   : $VNC_USER"; echo "Password   : $VNC_PASS"; fi
echo '==========================='
EOF
chmod +x "$PD_ROOT/usr/local/bin/vnc-details"

cat << 'EOF' > "$PD_ROOT/usr/local/bin/vnc-setup"
#!/bin/bash
source /etc/termo-vnc.conf
vncserver -kill $VNC_DISPLAY >/dev/null 2>&1; pkill websockify >/dev/null 2>&1
NU=$(dialog --clear --inputbox "Username:" 8 40 "$VNC_USER" 3>&1 1>&2 2>&3)
NP=$(dialog --clear --inputbox "VNC Port:" 8 40 "$VNC_PORT" 3>&1 1>&2 2>&3)
PW=$(dialog --clear --passwordbox "VNC Password:" 8 40 3>&1 1>&2 2>&3)
[ -z "$PW" ] || [ -z "$NP" ] && { clear; echo "Cancelled."; exit 1; }
DN=$(($NP - 5900)); [ $DN -lt 1 ] && { DN=1; NP=5901; }
echo -e "VNC_USER=\"$NU\"\nVNC_PORT=\"$NP\"\nVNC_DISPLAY=\":$DN\"\nVNC_PASS=\"$PW\"" > /etc/termo-vnc.conf
echo "$PW" | vncpasswd -f > ~/.vnc/passwd; chmod 600 ~/.vnc/passwd
clear; echo "Updated! Run 'boot Termo' to restart."
EOF
chmod +x "$PD_ROOT/usr/local/bin/vnc-setup"

cat << 'EOF' > "$PD_ROOT/usr/local/bin/boot-termo"
#!/bin/bash
[ "$1" == "details" ] && { vnc-details; exit 0; }
[ "$1" == "setup" ] && { vnc-setup; exit 0; }
source /etc/termo-vnc.conf; source /etc/termo-os.conf
S2=$(date +%s)
SG2() { echo "$(( $1*100/$2 ))" | dialog --title "$4" --gauge "Process $1/$2: $3\n\nELAPSED: $(( ($(date +%s)-S2)/60 )) min" 10 45; }
SG2 1 3 "cleaning old sessions" "TermoOS Startup"
vncserver -kill $VNC_DISPLAY >/dev/null 2>&1; pkill websockify >/dev/null 2>&1; sleep 1
SG2 2 3 "launching desktop" "TermoOS Startup"
vncserver $VNC_DISPLAY -geometry 1280x720 -depth 24 -localhost no -SecurityTypes VncAuth,None -extension MIT-SHM >/dev/null 2>&1; sleep 1
SG2 3 3 "finalizing" "TermoOS Startup"
[ "$VNC_TYPE" == "NoVNC" ] && websockify -D --web=/usr/share/novnc/ 6080 localhost:$VNC_PORT >/dev/null 2>&1; sleep 1
clear
[ "$VNC_TYPE" == "NoVNC" ] && { echo "NoVNC Server started!"; echo "Open browser: http://127.0.0.1:6080/vnc.html"; } || { echo "TermoOS Desktop started on port $VNC_PORT!"; }
EOF
chmod +x "$PD_ROOT/usr/local/bin/boot-termo"
ln -sf boot-termo "$PD_ROOT/usr/local/bin/vnc"
echo -e '#!/bin/bash\n[ "${1,,}" == "termo" ] && shift; boot-termo "$@"' > "$PD_ROOT/usr/local/bin/boot"; chmod +x "$PD_ROOT/usr/local/bin/boot"

echo "$USER_PASS" > "$PD_ROOT/tmp/vncpass.txt"
proot-distro login debian -- bash -c "mkdir -p ~/.config/tigervnc ~/.vnc && cat /tmp/vncpass.txt | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd && cp ~/.vnc/passwd ~/.config/tigervnc/passwd && chmod 600 ~/.config/tigervnc/passwd" >/dev/null 2>&1
rm -f "$PD_ROOT/tmp/vncpass.txt"

SG 7 $TM "termo-update (smart app)" "Installing TermoOS"
cat << 'EOF' > "$PD_ROOT/usr/local/bin/termo-update"
#!/bin/bash
export NEWT_COLORS='root=white,blue:window=white,blue:border=white,blue:button=white,blue'
MM() {
CH=$(whiptail --title "Updater & Recovery" --menu "Current Version: 1.0 (TxDE)" 15 65 4 "1" "Check for updates" "2" "Reset OS" "3" "Reinstall OS" "4" "Exit" 3>&1 1>&2 2>&3)
case $CH in 1) CU ;; 2) RO ;; 3) RE ;; *) exit 0 ;; esac
}
CU() {
{ echo "10"; apt-get update -y >/dev/null 2>&1; echo "50"; UG=$(apt-get -s upgrade | awk '/^Inst/ { print $2 }' | wc -l); echo "100"; sleep 0.5; } | whiptail --title "Update" --gauge "Checking..." 8 50 0
if [ "$UG" -eq 0 ]; then whiptail --msgbox "You're up to date!" 8 45
else if whiptail --yesno "$UG updates available. Install?" 10 50; then clear; apt-get upgrade -y; apt-get autoremove -y; read -p "Done! Press Enter."; fi; fi; MM
}
RO() {
if whiptail --yesno "Reset OS UI configs? (Base OS is kept)" 10 60; then clear
rm -rf /root/Desktop /root/.config/tint2 /root/.vnc /root/.config/tigervnc /etc/termo-* /usr/local/bin/txde-* /usr/local/bin/vnc* /usr/local/bin/boot* /usr/local/bin/termo-update
export DEBIAN_FRONTEND=noninteractive
apt-get purge -y openbox tint2 pcmanfm xterm whiptail firefox-esr tigervnc-standalone-server tigervnc-tools novnc websockify >/dev/null 2>&1; apt-get autoremove -y >/dev/null 2>&1
echo "Reset Complete! Type 'exit', then run 'bash install.sh'"; exit 0; else MM; fi
}
RE() {
if whiptail --yesno "FATAL WARNING: ERASE EVERYTHING?" 10 60; then clear
echo -e "To Factory Reset:\n1. Type 'exit' and press Enter.\n2. Paste: proot-distro remove debian && bash install.sh\n"; read -r; exit 0; else MM; fi
}
MM
EOF
chmod +x "$PD_ROOT/usr/local/bin/termo-update"
echo -e "[Desktop Entry]\nName=Updater\nExec=x-terminal-emulator -e '/usr/local/bin/termo-update'\nIcon=system-software-update\nType=Application\nTerminal=false" > "$PD_ROOT/root/Desktop/updater.desktop"
chmod +x "$PD_ROOT/root/Desktop/updater.desktop"

SG 8 $TM "termo-modules (app store)" "Installing TermoOS"
curl -s https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/termo-modules.sh -o "$PD_ROOT/usr/local/bin/termo-modules"
chmod +x "$PD_ROOT/usr/local/bin/termo-modules"
rm -f termo_config.env

clear
echo -e "\n\nSuccess! TermoOS (TxDE Edition) is installed."
echo "----------------------------------------"
echo "To enter TermoOS, type: proot-distro login debian"
echo "Inside TermoOS, your startup commands are:"
echo " - boot Termo          (Starts desktop with GUI loading bar)"
echo " - boot Termo details  (Shows login info)"
echo " - boot Termo setup    (Changes port/username/password)"
echo " - termo-update        (Windows-Style Updater & Reset tool)"
echo " - txde-features       (Opens the blue Feature mode GUI)"
echo "----------------------------------------"
