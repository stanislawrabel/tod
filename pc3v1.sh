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

# 🔹 SCRIPTS & FILES
echo "📥 Downloading OTA downloader script and data..."
curl -sSL "$REPO/o.sh" -o ~/realme-ota/o.sh
curl -sSL "$REPO/s.sh" -o ~/realme-ota/s.sh
curl -sSL "$REPO/d.sh" -o ~/realme-ota/d.sh
curl -sSL "$REPO/models.txt" -o ~/realme-ota/models.txt
curl -sSL "$REPO/devices.txt" -o ~/realme-ota/devices.txt
chmod +x ~/realme-ota/o.sh s.sh d.sh



# Nahrádza celé bloky s aliasmi
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
mkdir -p "$PREFIX/bin"

for name in o s d; do
  target="$HOME/${name}.sh"
  wrapper="$PREFIX/bin/$name"
  cat > "$wrapper" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec bash "$target" "\$@"
EOF
  chmod +x "$wrapper"
done
echo -e "\e[32m✅ Installation completed. Use commands: o | s | d\e[0m"
exit
