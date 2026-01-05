#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/stanislawrabel/tod/main"
OTA_REPO="https://github.com/R0rt1z2/realme-ota.git"

INSTALL_DIR="$HOME/realme-ota"
BIN_DIR="$HOME/.local/bin"
SHELL_PATH="/bin/bash"

mkdir -p "$BIN_DIR"

echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y python3-full python3-venv git curl nano

echo "📥 Cloning realme-ota..."
if [ ! -d "$INSTALL_DIR" ]; then
    git clone "$OTA_REPO" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

echo "🐍 Creating virtualenv..."
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip wheel
pip install .


BIN_D source "$INSTALL_DIR/venv/bin/activate"

if ! python -c "import realme_ota" 2>/dev/null; then
    echo "❌ realme-ota not installed correctly"
    deactivate
    exit 1
fi

deactivate

INSTALL_DIR="$HOME/tod"
IR="$HOME/.local/bin"

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
