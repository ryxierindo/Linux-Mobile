#!/bin/bash

# TermoOS Module Installer (Runs inside Debian)

# Ensure dialog is installed
if ! command -v dialog &> /dev/null; then
    apt-get update && apt-get install dialog -y
fi

# Show checklist UI
CHOICES=$(dialog --clear --backtitle "TermoOS Module Manager" --title "Install Optional Modules" \
--checklist "Use SPACE to select, ENTER to confirm:" 15 50 5 \
"Fonts" "Install extra fonts and emojis" OFF \
"DevTools" "Python, C++, Git, and Make" OFF \
"Office" "LibreOffice Suite (Heavy)" OFF \
"Media" "VLC Player & Audio tools" OFF \
3>&1 1>&2 2>&3)

clear

if [ -z "$CHOICES" ]; then
    echo "No modules selected. Exiting..."
    exit 0
fi

echo "Installing selected modules. Please wait..."
apt-get update -y

if [[ $CHOICES == *"Fonts"* ]]; then
    echo "--> Installing Fonts..."
    apt-get install fonts-liberation fonts-noto-color-emoji -y
fi

if [[ $CHOICES == *"DevTools"* ]]; then
    echo "--> Installing Developer Tools..."
    apt-get install python3 python3-pip git build-essential -y
fi

if [[ $CHOICES == *"Office"* ]]; then
    echo "--> Installing Office Suite..."
    apt-get install libreoffice -y
fi

if [[ $CHOICES == *"Media"* ]]; then
    echo "--> Installing Media Tools..."
    apt-get install vlc pulseaudio -y
fi

echo "Module installation complete!"
