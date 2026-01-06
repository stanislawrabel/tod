#!/data/data/com.termux/files/usr/bin/bash

COMMON_FILE="/mnt/c/DownloadeR/ota_common.txt"

if [[ ! -f "$COMMON_FILE" ]]; then
  echo "❌ ota_common.txt not found"
  exit 1
fi

source "$COMMON_FILE"

# === 🧠 CHECK ARIA2 ===
if ! command -v aria2c &>/dev/null; then
  echo -e "${RED}❌ aria2c not installed .${RESET}"
  echo "👉 Run: pkg install aria2 -y"
  exit 1
fi

FINAL_URL="$DOWNLOAD"

if [[ ! "$FINAL_URL" =~ ^https?:// ]]; then
  echo "❌ Invalid FINAL_URL"
  exit 1
fi
# === LOAD COMMON ===


resolve_zip() {
  curl -s -I --http1.1 \
    -H "User-Agent: Dalvik/2.1.0 (Linux; Android 16)" \
    -H "userId: oplus-ota|16002018" \
    -H "Accept: */*" \
    -H "Accept-Encoding: identity" \
    "$1" \
  | grep -i '^location:' \
  | tail -1 \
  | awk '{print $2}' \
  | tr -d '\r'
}

FINAL_URL="$DOWNLOAD"

# === RESOLVE IF NEEDED ===
if [[ "$FINAL_URL" == *"downloadCheck"* ]]; then
  echo "🔄 Resolving downloadCheck…"
  FINAL_URL=$(resolve_zip "$FINAL_URL")
fi

# === VALIDATION ===
if [[ -z "$FINAL_URL" || ! "$FINAL_URL" =~ ^https?:// ]]; then
  echo "❌ Invalid FINAL_URL"
  exit 1
fi

TARGET_DIR="/mnt/c/DownloadeR"
TARGET_NAME="${OTA}.zip"

FINAL_PATH="$TARGET_DIR/$TARGET_NAME"

aria2c \
  --file-allocation=trunc \
  --summary-interval=1 \
  --continue=true \
  --out="$TARGET_NAME" \
  --dir="$TARGET_DIR" \
  "$FINAL_URL"



if [[ -n "$MD5" ]]; then
  echo "🔐 Verifying MD5..."
  echo "${MD5}  ${FINAL_PATH}" | md5sum -c -
else
  echo "⚠️ MD5 not provided – skipping check"
fi


echo "✅ Done: $FINAL_PATH"
