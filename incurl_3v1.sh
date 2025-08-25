#!/bin/bash
set -e

# 🛠 Automatický mód
export DEBIAN_FRONTEND=noninteractive
export TERM=xterm

echo "📦 Fixing broken packages and cleaning up..."
dpkg --configure -a || true
apt --fix-broken install -y || true
apt clean

echo "📦 Updating Termux and installing dependencies..."
yes "" | pkg update -y
yes "" | pkg upgrade -y

echo "📦 Installing required packages..."
pkg install -y python python2 git tsu curl
pip install wheel
pip install pycryptodome
pip3 install --upgrade requests pycryptodome git+https://github.com/R0rt1z2/realme-ota

# 🔹 SCRIPTS & FILES
echo "📥 Downloading scripts and data files..."
REPO="https://raw.githubusercontent.com/stanislawrabel/tod/main"

for file in t.sh s.sh d.sh models.txt devices.txt; do
    curl -sSL "$REPO/$file" -o "$file"
done

chmod +x t.sh s.sh d.sh

# 🛠️ Adding aliases
if ! grep -q "alias o=" ~/.bashrc; then
    echo "alias o='bash ~/t.sh'" >> ~/.bashrc
fi
if ! grep -q "alias s=" ~/.bashrc; then
    echo "alias s='bash ~/s.sh'" >> ~/.bashrc
fi
if ! grep -q "alias d=" ~/.bashrc; then
    echo "alias d='bash ~/d.sh'" >> ~/.bashrc
fi

echo -e "\e[32m✅ Aliases added: o, s, d\e[0m"
source ~/.bashrc
clear

echo -e "\e[32m✅ Installation completed. Use commands: o | s | d\e[0m"
exit
