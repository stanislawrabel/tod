#!/bin/bash

# 🎨 Colors
YELLOW="\033[33m";
BLUE="\033[34m"
RED="\033[31m"
BLACK="\033[30m"
WHITE="\033[37m"
GREEN="\033[32m"
YELLOW_BG="\033[43m"
GREEN_BG="\033[42m"
RED_BG="\033[41m"
RESET="\033[0m"

download_dir="/storage/emulated/0/Download/DownloadeR"

if ! command -v aria2c &> /dev/null; then
  echo "Error: aria2c not installed. Install via command 'pkg install aria2'"
  exit 1
fi

clear
echo -e "${GREEN}+===================================================================================================================+${RESET}"
echo -e "${GREEN}|======${RESET}           ${GREEN}DownloadeR${RESET}         ${YELLOW_BG}${BLACK}  realme   ${RESET}    ${GREEN_BG}${BLACK}   oppo   ${RESET}    ${RED_BG}${WHITE}  OnePlus   ${RESET}           ${RED}by${RESET}  ${BLUE}Stano36${RESET}          ${GREEN}======|${RESET}"
echo -e "${GREEN}+===================================================================================================================+${RESET}"
echo -e
read -p "Enter URL: " url
echo -e "${GREEN}+===================================================================================================================+${RESET}"
if [[ -z "$url" || ! "$url" =~ ^https?:\/\/ ]]; then
  echo "Error: Incorrect URL. URL enter from  'http://' or 'https://'"
  exit 1
fi
echo -e
filename=$(basename "$url")
read -p "Enter a file name  (Default : $filename): " filename_input
filename="${filename_input:-$filename}"
echo -e
echo   "Downloading....."
echo -e
aria2c -c -x 16 -s 16 -d "$download_dir" -o "$filename" "$url"
echo -e
if [ $? -eq 0 ]; then
  echo "File download was successful."
  echo "File saved in : $download_dir"
else
  echo "Error while loading .Check URL and internet connection ."
fi
echo -e
while true; do
    echo -e "🔄 1 - Download from other URL"
    echo -e "❌ 0 - End script"
    echo -e
    read -p "💡 Select an option (1/0): " option
    case "$option" in
        1)
            bash "$0"
            ;;
        0)
            echo -e "👋 Goodbye."
            exit 0
            ;;
        *)
            echo "❌ Invalid option."
            ;;
    esac
done
