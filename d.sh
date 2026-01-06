#!/usr/bin/env bash
set -e

# ===============================
#  📦 OTA DownloadeR (FINAL)
# ===============================

# === DETEKCIA PROSTREDIA ===
if [[ -d /mnt/c ]]; then
  BASE_DIR="/mnt/c/DownloadeR"
else
  BASE_DIR="/storage/emulated/0/Download/DownloadeR"
fi

COMMON_FILE="$BASE_DIR/ota_common.txt"

# === KONTROLY ===
if [[ ! -f "$COMMON_FILE" ]]; then
  echo "❌ ota_common.txt not found:"
  echo "   $COMMON_FILE"
  exit 1
fi

if ! command -v aria2c >/dev/null; then
  echo "❌ aria2c not installed"
  exit 1
fi

# === LOAD OTA COMMON ===
set -a
source "$COMMON_FILE"
set +a

# === VALIDÁCIA ===
if [[ -z "$DOWNLOAD" || ! "$DOWNLOAD" =~ ^https?:// ]]; then
  echo "❌ Invalid DOWNLOAD URL"
  exit 1
fi

mkdir -p "$BASE_DIR"

TARGET_NAME="${OTA}.zip"
FINAL_PATH="$BASE_DIR/$TARGET_NAME"

# === FUNKCIA: resolve downloadCheck ===
resolve_downloadcheck() {
  curl -sIL --http1.1 \
    -H "User-Agent: Dalvik/2.1.0 (Linux; Android 16)" \
    -H "userId: oplus-ota|16002018" \
    -H "Accept: */*" \
    -H "Accept-Encoding: identity" \
    "$1" | awk '/^location:/I {print $2}' | tr -d '\r' | tail -1
}

FINAL_URL="$DOWNLOAD"

if [[ "$FINAL_URL" == *downloadCheck* ]]; then
  echo "🔄 Resolving downloadCheck..."
  FINAL_URL=$(resolve_downloadcheck "$FINAL_URL")
fi

if [[ -z "$FINAL_URL" || ! "$FINAL_URL" =~ ^https?:// ]]; then
  echo "❌ Failed to resolve final download URL"
  exit 1
fi

# === INFO ===
echo "📥 Downloading OTA:"
echo "   $FINAL_URL"
echo "➡️  Saving to:"
echo "   $FINAL_PATH"
echo ""

# === DOWNLOAD (S OTA HLAVIČKAMI) ===
aria2c \
  --file-allocation=trunc \
  --continue=true \
  --summary-interval=1 \
  --dir="$BASE_DIR" \
  --out="$TARGET_NAME" \
  --header="User-Agent: Dalvik/2.1.0 (Linux; Android 16)" \
  --header="userId: oplus-ota|16002018" \
  --header="Accept: */*" \
  --header="Accept-Encoding: identity" \
  "$FINAL_URL"

# === MD5 KONTROLA ===
if [[ -f "$FINAL_PATH" && -n "$MD5" && "$MD5" != "md5sum" ]]; then
  echo "🔐 Verifying MD5..."
  echo "${MD5}  ${FINAL_PATH}" | md5sum -c -
elif [[ ! -f "$FINAL_PATH" ]]; then
  echo "❌ Download failed – file not found, skipping MD5"
else
  echo "⚠️ MD5 not provided – skipping check"
fi

echo "✅ Done: $FINAL_PATH"
