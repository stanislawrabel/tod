#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

REPO_RAW="https://raw.githubusercontent.com/stanislawrabel/tod/main"
OTA_REPO="https://github.com/R0rt1z2/realme-ota.git"

# =========================
# 🔍 DETEKCIA PROSTREDIA
# =========================
if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == *com.termux* ]]; then
    IS_TERMUX=1
    INSTALL_DIR="$HOME/realme-ota"
    BIN_DIR="$PREFIX/bin"
    PYTHON_BIN="python"
else
    IS_TERMUX=0
    INSTALL_DIR="$HOME/realme-ota"
    BIN_DIR="$HOME/.local/bin"
    PYTHON_BIN="python3"
fi

mkdir -p "$BIN_DIR"

echo "📦 Updating system..."
if [[ "$IS_TERMUX" == "1" ]]; then
    pkg update -y
    pkg upgrade -y
    pkg install -y python git curl
else
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y python3 python3-venv python3-pip git curl
fi

# =========================
# 📥 CLONE realme-ota
# =========================
echo "📥 Installing realme-ota..."
rm -rf "$INSTALL_DIR"
git clone "$OTA_REPO" "$INSTALL_DIR"

cd "$INSTALL_DIR"

# =========================
# 🐍 PYTHON VENV
# =========================
echo "🐍 Creating virtual environment..."
$PYTHON_BIN -m venv venv
source venv/bin/activate

pip install --upgrade pip wheel
pip install .

# =========================
# ✅ OVERENIE INŠTALÁCIE
# =========================
if ! python -c "import realme_ota" 2>/dev/null; then
    echo "❌ realme-ota not installed correctly"
    deactivate
    exit 1
fi

deactivate
echo "✅ realme-ota installed correctly"

# =========================
# 📥 DOWNLOAD TVOJICH SKRIPTOV
# =========================
echo "📥 Downloading helper scripts..."

curl -fsSL "$REPO_RAW/o.sh" -o "$INSTALL_DIR/o.sh"
curl -fsSL "$REPO_RAW/s.sh" -o "$INSTALL_DIR/s.sh"
curl -fsSL "$REPO_RAW/d.sh" -o "$INSTALL_DIR/d.sh"
curl -fsSL "$REPO_RAW/models.txt" -o "$INSTALL_DIR/models.txt"
curl -fsSL "$REPO_RAW/devices.txt" -o "$INSTALL_DIR/devices.txt"

chmod +x "$INSTALL_DIR/"*.sh

# =========================
# ⚙️ WRAPPERY (o / s / d)
# =========================
echo "⚙️ Creating launcher commands..."

for name in o s d; do
    cat > "$BIN_DIR/$name" <<EOF
#!/usr/bin/env bash
source "$INSTALL_DIR/venv/bin/activate"
exec bash "$INSTALL_DIR/$name.sh" "\$@"
EOF
    chmod +x "$BIN_DIR/$name"
done

# =========================
# ✅ HOTOVO
# =========================
echo ""
echo "🎉 Installation completed successfully!"
echo "➡️ Commands available:"
echo "   o  → OTA Finder"
echo "   s  → OTA Resolver"
echo "   d  → OTA Downloader"
echo ""echo "⚙️ Creating launchers..."

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
