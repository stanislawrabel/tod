#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/stanislawrabel/tod/main"
OTA_REPO="https://github.com/R0rt1z2/realme-ota.git"

echo "📦 Updating system..."
sudo apt update
sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y \
  python3 \
  python3-pip \
  git \
  curl \
  aria2 \
  nano

echo "📦 Installing Python packages..."
pip3 install --upgrade pip wheel
pip3 install requests pycryptodome
pip3 install git+https://github.com/R0rt1z2/realme-ota

# overenie
if ! command -v realme-ota >/dev/null; then
  echo "❌ realme-ota not installed correctly"
  exit 1
fi

INSTALL_DIR="$HOME/tod"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

echo "📥 Downloading scripts..."
curl -sSL "$REPO/o.sh" -o "$INSTALL_DIR/o.sh"
curl -sSL "$REPO/s.sh" -o "$INSTALL_DIR/s.sh"
curl -sSL "$REPO/d.sh" -o "$INSTALL_DIR/d.sh"
curl -sSL "$REPO/models.txt" -o "$INSTALL_DIR/models.txt"
curl -sSL "$REPO/devices.txt" -o "$INSTALL_DIR/devices.txt"

chmod +x "$INSTALL_DIR/"*.sh

echo "⚙️ Creating launchers..."

for name in o s d; do
  cat > "$BIN_DIR/$name" <<EOF
#!/bin/bash
exec bash "$INSTALL_DIR/${name}.sh" "\$@"
EOF
  chmod +x "$BIN_DIR/$name"
done

# PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

source ~/.bashrc

echo
echo "✅ INSTALLATION COMPLETE (WSL)"
echo "➡️ Commands available:"
echo "   o  → OTA FindeR"
echo "   s  → Share OTA links"
echo "   d  → DownloadeR"pip install --upgrade pip wheel
pip install .

# 🔹 DOWNLOAD SCRIPTS
echo "📥 Downloading OTA downloader script and data..."
curl -sSL "$REPO/o.sh" -o "$INSTALL_DIR/o.sh"
curl -sSL "$REPO/s.sh" -o "$INSTALL_DIR/s.sh"
curl -sSL "$REPO/d.sh" -o "$INSTALL_DIR/d.sh"
curl -sSL "$REPO/models.txt" -o "$INSTALL_DIR/models.txt"
curl -sSL "$REPO/devices.txt" -o "$INSTALL_DIR/devices.txt"
chmod +x "$INSTALL_DIR/"*.sh

# 🔹 CREATE WRAPPERS
echo "⚙️ Creating launcher commands..."

for name in o s d; do
  wrapper="$BIN_DIR/$name"
  cat > "$wrapper" <<EOF
#!$SHELL_PATH
exec bash "$INSTALL_DIR/${name}.sh" "\$@"
EOF
  chmod +x "$wrapper"
done

echo -e "\n\e[32m✅ Installation completed.\e[0m"
echo -e "➡️ Run tools using:  \e[33mo\e[0m | \e[33ms\e[0m | \e[33md\e[0m"
echo ""
exit
