#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

REPO="https://raw.githubusercontent.com/stanislawrabel/tod/main"
OTA_REPO="https://github.com/R0rt1z2/realme-ota.git"

echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y python3 python3-pip python3-venv git curl nano

echo "📥 Cloning realme-ota..."
if [ ! -d ~/realme-ota ]; then
    git clone "$OTA_REPO" ~/realme-ota
fi

cd ~/realme-ota
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip wheel
pip install .

echo "📥 Downloading OTA downloader script and data..."
curl -sSL "$REPO/t.sh" -o ~/realme-ota/ota_downloader.sh
curl -sSL "$REPO/models.txt" -o ~/realme-ota/models.txt
curl -sSL "$REPO/devices.txt" -o ~/realme-ota/devices.txt
chmod +x ~/realme-ota/ota_downloader.sh

echo "🔗 Adding alias 'ota' to ~/.bashrc..."
if ! grep -q "alias ota=" ~/.bashrc; then
    echo "alias ota='cd ~/realme-ota && source venv/bin/activate && bash ota_downloader.sh'" >> ~/.bashrc
fi
source ~/.bashrc

clear
echo -e "\e[32m✅ Installation completed! You can now run the script with: ota\e[0m"
