#!/bin/bash
# 🧩 DownloadeR by Stano36 (Termux edition, aria2c + link check)

# === 🎨 COLORS ===
YELLOW="\033[33m"; BLUE="\033[34m"; RED="\033[31m"
WHITE="\033[37m"; GREEN="\033[32m"; RESET="\033[0m"

# === 📁 PATHS ===
download_dir="/storage/emulated/0/Download/DownloadeR"
log_file="$download_dir/Download_History.txt"

mkdir -p "$download_dir"

# === 🧠 CHECK ARIA2 ===
if ! command -v aria2c &>/dev/null; then
  echo -e "${RED}❌ aria2c not installed .${RESET}"
  echo "👉 Run: pkg install aria2 -y"
  exit 1
fi

clear
echo -e "${GREEN}+========================================+${RESET}"
echo -e "${GREEN}|===${RESET}     ${YELLOW}DownloadeR${RESET}   ${RED}by${RESET} ${BLUE}Stano36${RESET}      ${GREEN}===|${RESET}"
echo -e "${GREEN}+========================================+${RESET}"

while true; do
  read -p "🔗 Enter URL  (Download / downloadCheck): " url
  if [[ -z "$url" || ! "$url" =~ ^https?:// ]]; then
    echo -e "${RED}❌ Invalid URL.${RESET}"
    continue
  fi

  echo -e "\n🧩 I am verifying the validity of the link....\n"

  # === 🔍 HEAD CHECK ===
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url")

  if [[ "$status_code" != "200" ]]; then
    echo -e "${RED}⚠️ Link invalid or expired.  (HTTP $status_code).${RESET}"
    echo -e "🔁 Get a new link via realme-ota and try again..\n"
    continue
  fi

  filename=$(basename "${url%%\?*}")
  read -p "💾 File name  (Default: $filename): " filename_input
  filename="${filename_input:-$filename}"

  echo -e "\n📥 Downloading $filename...\n"
  start_time=$(date '+%Y-%m-%d %H:%M:%S')

  aria2c -c -x 16 -s 16 -d "$download_dir" -o "$filename" "$url"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ File downloaded successfully.${RESET}"
    echo -e "📂 Saved in : ${YELLOW}$download_dir${RESET}\n"
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$(date '+%F %T')] ✅ $filename | $url" >> "$log_file"
  else
    echo -e "${RED}❌ Error while downloading.${RESET}"
    echo -e "[$(date '+%F %T')] ❌ ERROR | $url" >> "$log_file"
  fi

  echo -e "${GREEN}──────────────────────────────────────${RESET}\n"
  echo -e "🔄 1 - Download another file"
  echo -e "❌ 0 - Exit"
  echo -e
  read -p "💡 Select an option  (1/0): " option
  case "$option" in    1) clear ;;
    0) echo -e "👋 End. Log saved in $log_file"; exit 0 ;;
    *) echo -e "${RED}Invalid choice.${RESET}" ;;
  esac
done
