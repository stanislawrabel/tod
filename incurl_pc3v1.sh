#!/usr/bin/env bash
set -e

# ===============================
# CONFIG
# ===============================
REPO_RAW="https://raw.githubusercontent.com/stanislawrabel/tod/main"
REALME_OTA_REPO="https://github.com/R0rt1z2/realme-ota.git"

INSTALL_DIR="$HOME/realme-ota"
BIN_DIR="$HOME/.local/bin"
VENV_DIR="$INSTALL_DIR/venv"

mkdir -p "$BIN_DIR"

echo "🧹 Cleaning old installation (if exists)..."
rm -rf "$INSTALL_DIR"
rm -f "$BIN_DIR/o" "$BIN_DIR/s" "$BIN_DIR/d"

echo "📦 Updating system..."
sudo apt update -y
sudo apt install -y \
  python3-full \
  python3-venv \
  python3-pip \
  git \
  curl \
  nano

echo "📥 Cloning realme-ota..."
git clone "$REALME_OTA_REPO" "$INSTALL_DIR"

echo "🐍 Creating virtual environment..."
python3 -m venv "$VENV_DIR"

echo "📦 Installing Python dependencies (inside venv)..."
"$VENV_DIR/bin/pip" install --upgrade pip wheel
"$VENV_DIR/bin/pip" install "$INSTALL_DIR"

echo "📥 Downloading scripts and data..."
curl -sSL "$REPO_RAW/o.sh" -o "$INSTALL_DIR/o.sh"
curl -sSL "$REPO_RAW/s.sh" -o "$INSTALL_DIR/s.sh"
curl -sSL "$REPO_RAW/d.sh" -o "$INSTALL_DIR/d.sh"
curl -sSL "$REPO_RAW/models.txt" -o "$INSTALL_DIR/models.txt"
curl -sSL "$REPO_RAW/devices.txt" -o "$INSTALL_DIR/devices.txt"

chmod +x "$INSTALL_DIR/"*.sh

echo "⚙️ Creating launchers..."

for cmd in o s d; do
  cat > "$BIN_DIR/$cmd" <<EOF
#!/usr/bin/env bash
source "$VENV_DIR/bin/activate"
exec bash "$INSTALL_DIR/$cmd.sh" "\$@"
EOF
  chmod +x "$BIN_DIR/$cmd"
done

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

echo
echo "✅ INSTALLATION COMPLETE (WSL)"
echo "➡️ Commands available:"
echo "   o  → OTA FindeR"
echo "   s  → Share OTA links"
echo "   d  → DownloadeR"
echo
echo "🔄 Please restart terminal or run:"
echo "   source ~/.bashrc"
echo
