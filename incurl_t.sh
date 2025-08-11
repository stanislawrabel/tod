#!/bin/bash
set -e

# 🛠 Automatický mód
export DEBIAN_FRONTEND=noninteractive
export TERM=xterm

set -e

echo "📦 Updating Termux and installing dependencies..."
yes "" | pkg update -y
yes "" | pkg upgrade -y
echo N | dpkg --configure -a

pkg install -y python python2 git tsu curl
pip install wheel
pip install pycryptodome
pip3 install --upgrade requests pycryptodome git+https://github.com/R0rt1z2/realme-ota

echo "📥 Downloading scripts and data files..."
REPO="https://raw.githubusercontent.com/stanislawrabel/tod/main"

curl -sSL "$REPO/t.sh" -o t.sh
curl -sSL "$REPO/models.txt" -o models.txt
curl -sSL "$REPO/devices.txt" -o devices.txt

chmod +x t.sh

# 🛠️ Adding an alias for easy launch 
if ! grep -q "alias t=" ~/.bashrc; then
    echo "alias t='bash ~/t.sh'" >> ~/.bashrc
    echo -e "\e[32m✅ Alias 't' has been added.\e[0m"
fi
source ~/.bashrc
clear
exit
