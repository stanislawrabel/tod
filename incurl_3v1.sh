
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

for file in o.sh s.sh d.sh models.txt devices.txt; do
    curl -sSL "$REPO/$file" -o "$file"
done

chmod +x o.sh s.sh d.sh

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
