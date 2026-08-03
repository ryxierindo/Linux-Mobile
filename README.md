# 🐧 TermoOS

A lightweight, modular, and fast Linux distribution built specifically for Android devices using Termux and proot-distro. No root required!

## ✨ Features
* **Smart Installer:** Analyzes your phone's RAM and recommends the best setup.
* **Graphical Setup Wizard:** Beautiful, Windows-like blue screen installer right in your terminal.
* **Custom VNC Commands:** Start your desktop instantly by just typing `vnc`, or view your login credentials by typing `vnc details`.
* **Module Manager:** Keep the base system extremely light, and install extra features (like Office suites or Dev tools) later by typing `termo-modules`.

## 🚀 How to Install

Open Termux on your Android device and paste this single command:

```bash
pkg install curl -y && bash <(curl -s [https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/install.sh](https://raw.githubusercontent.com/ryxierindo/Linux-Mobile/main/install.sh))
