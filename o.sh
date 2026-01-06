#!/usr/bin/env bash

BASE_DIR="/mnt/c/DownloadeR"
COMMON_FILE="/mnt/c/DownloadeR/ota_common.txt"

# === FIX WORKING DIRECTORY ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

DEVICES_FILE="$SCRIPT_DIR/devices.txt"
MODELS_FILE="$SCRIPT_DIR/models.txt"
COMMON_OUT="mmt/c/DownloadeR/ota_common.txt"


# 🎨 Farby pre výstup

  PURPLE="\033[35m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  RED="\033[31m"
  BLACK="\033[30m"
  WHITE="\033[37m"
  GREEN="\033[32m"
  YELLOW_BG="\033[43m"
  GREEN_BG="\033[42m"
  RED_BG="\033[41m"
  WHITE_BG="\033[47m"
  BLACK_BG="\033[40" 
  RESET="\033[0m"

# 📌 Regióny, verzie a servery
declare -A REGIONS=(
    [00]="EX Export 00000000"
    [A1]="US NA 10100001"
    [A4]="APC Global 10100100"
    [A5]="OCA Oce_Cen_Australia 10100101"
    [A6]="MEA Middle_East_Africa 10100110"
    [A7]="ROW Global 10100111"  
    [1A]="TW Taiwan 00011010" 
    [1B]="IN India 00011011"
    [1E]="AU Australia 00011110"
    [2C]="SG Singapure 00101100"
    [3B]="JP Japan 00111011" 
    [3C]="VN Vietnam 00111100" 
    [3E]="PH Philippines 00111110"
    [33]="ID Indonesia 00110011" 
    [37]="RU Russia 00110111" 
    [38]="MY Malaysia 00111000"
    [39]="TH Thailand 00111001" 
    [44]="EUEX Europe 01000100" 
    [51]="TR Turkey 01010001"
    [7B]="MX Mexico 01111011" 
    [75]="EG Egypt 01110101" 
    [8D]="EU-NO Europe_Non_GDPR 10001101"
    [82]="HK Hong_Kong 10000010"
    [83]="SA Saudi_Arabia 10000011" 
    [9A]="LATAM Latin_America 10011010" 
    [9E]="BR Brazil 10011110"
    [97]="CN China 10010111"
)
declare -A VERSIONS=(
  [A]="Launch version" 
  [C]="First update" 
  [F]="Second update" 
  [H]="Third update"
)
declare -A SERVERS=(
  [97]="-r 1" 
  [44]="-r 0" 
  [51]="-r 0"
)

declare -A MODEL_NAMES
while IFS='|' read -r code name; do
MODEL_NAMES["$code"]="$name"
done < models.txt
# Načítanie názvov modelov
declare -A MODEL_NAMES
[[ -f models.txt ]] && while IFS='|' read -r code name; do
  MODEL_NAMES["$code"]="$name"
done < models.txt

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
fix_old_zip() {
  local url="$1"

  echo "$url" | sed \
    -e 's|gauss-componentotamanual.allawnofs.com|gauss-opexcostmanual-eu.allawnofs.com|'
}


# 📌 Funkcia na spracovanie OTA
run_ota() {
    region_data=(${REGIONS[$region]})
    region_code=${region_data[0]}
    region_name=${region_data[1]}
    nv_id=${region_data[2]}
    server="${SERVERS[$region]:--r 3}"
    ota_model="$device_model"
    for rm in TR RU EEA T2 CN IN ID MY TH EU; do 
    ota_model="${ota_model//$rm/}"; 
done

    ota_command="realme-ota $server $device_model ${ota_model}_11.${version}.01_0001_100001010001 6 $nv_id"
    
    output=$(eval "$ota_command")
    

    real_ota_version=$(echo "$output" | grep -o '"realOtaVersion": *"[^"]*"' | cut -d '"' -f4)
    real_version_name=$(echo "$output" | grep -o '"realVersionName": *"[^"]*"' | cut -d '"' -f4)
    os_version=$(echo "$output" | grep -o '"realOsVersion": *"[^"]*"' | cut -d '"' -f4)
    android_version=$(echo "$output" | grep -o '"realAndroidVersion": *"[^"]*"' | cut -d '"' -f4)
    security_os=$(echo "$output" | grep -o '"securityPatchVendor": *"[^"]*"' | cut -d '"' -f4)
    ota_f_version=$(echo "$real_ota_version" | grep -oE '_11\.[A-Z]\.[0-9]+' | sed 's/_11\.//')
    ota_date=$(echo "$real_ota_version" | grep -oE '_[0-9]{12}$' | tr -d '_')
    ota_version_full="${ota_model}_11.${ota_f_version}_${region_code}_${ota_date}"
    version_type_id=$(echo "$output" | grep -oP '"versionTypeId"\s*:\s*"\K[^"]+')
    md5=$(echo "$output" | grep -oE '"md5"\s*:\s*"[^"]+"' | head -n1 | cut -d'"' -f4)

# Získať URL k About this update
    about_update_url=$(echo "$output" | grep -oP '"panelUrl"\s*:\s*"\K[^"]+')

## 🟡 Extrahuj celý obsah poľa "header" z JSON výstupu
header_block=$(echo "$output" | sed -n '/"header"\s*:/,/]/p' | tr -d '\n' | sed -E 's/.*"header"[[:space:]]*:[[:space:]]*([^]+).*/\1/')
# 🔍 Skontroluj obsah poľa na výskyt hodnoty
if echo "$header_block" | grep -q 'forbid_ota_local_update=true'; then
    forbid_status="${RED}❌ Forbidden${RESET}"
elif echo "$header_block" | grep -q 'forbid_ota_local_update=false'; then
    forbid_status="${GREEN}✔️ Allowed${RESET}"
else
    forbid_status="${YELLOW}❓ Unknown${RESET}"
fi

clean_model=$(echo "$device_model" | sed 's/IN\|EEA\|RU\|TR\|T2//g')
model_name="${MODEL_NAMES[$clean_model]}"



# 📋 Výpis ako tabuľka

echo -e "\n     ${BLUE}${model_name:-Unknown}${RESET} 
(${clean_model})${GREEN}$device_model${RESET} (code: ${YELLOW}$region_data${RESET})"
echo -e
printf "${BLACK_BG}${WHITE} %-18s${RESET} ${YELLOW}%-33s${RESET} \n" "OTA version:" "$ota_version_full"
printf "${BLACK_BG}${WHITE} %-18s${RESET} ${YELLOW}%-33s${RESET} \n" "Displayed version:" "$real_version_name"
printf "${BKACK_BG}${WHITE} %-18s${RESET} ${YELLOW}%-33s${RESET} \n" "Android version:" "$android_version"
printf "${BLACK_BG}${WHITE} %-18s${RESET} ${YELLOW}%-33s${RESET} \n" "OS version:" "$os_version"
printf "${BLACK_BG}${WHITE} %-18s${RESET} ${YELLOW}%-33s${RESET} \n" "Security patch:" "$security_os"
printf "${BLACK_BG}${WHITE} %-18s${RESET} ${YELLOW}%-33s${RESET} \n" "Version:" "$version_type_id"
printf "${BLACK_BG}${WHITE} %-18s${RESET}  %-33b   \n"  "Local install:"      "$forbid_status" 
printf "${BLACK_BG}${WHITE} %-18s${RESET} ${YELLOW}%-33s${RESET}\n" "MD5:" "$md5"
echo -e

download_link=$(echo "$output" | grep -o 'http[s]*://[^"]*' | head -n 1 | sed 's/["\r\n]*$//')
   modified_link=$(echo "$download_link" | sed 's/componentotamanual/componentotamanual/g')       

fixed_zip=$(fix_old_zip "$download_link")

if [[ "$download_link" == *"downloadCheck"* ]]; then
  resolved_zip=$(resolve_zip "$download_link")
else
  resolved_zip="$fixed_zip"
fi


FINAL_ZIP_URL="$download_link"

if [[ "$download_link" == *"downloadCheck"* ]]; then
    FINAL_ZIP_URL=$(resolve_zip "$download_link")
fi
fixed_zip=$(fix_old_zip "$download_link")

OUT="/mnt/c/DownloadeR/ota_common.txt"

mkdir -p "$(dirname "$OUT")"

    
  cat > "$OUT" <<EOF
MODEL=$device_model
REGION=$region_data
OTA=$ota_version_full
ANDROID="$android_version"
OS="$os_version"
PATCH=$security_os
VERSION=$version_type_id
LOCAL_INSTALL=""
MD5=""
ABOUT="$about_update_url"
DOWNLOAD="$FINAL_ZIP_URL"
EOF


    echo -e "📥    About this update: 
${GREEN}$about_update_url${RESET}"
    if [[ -n "$modified_link" ]]; then
    echo -e "📥    Download link: 
${GREEN}$modified_link${RESET}"
    else
        echo -e "❌ Download link not found."
        
   fi

if [[ -n "$FINAL_ZIP_URL" ]]; then
echo -e "📥    Resolved link:"
echo -e "${GREEN}$resolved_zip${RESET}"
else
  echo "❌ No download link found."
fi



    echo "$ota_version_full" >> "ota_${device_model}.txt"
    echo "$modified_link" >> "ota_${device_model}.txt"
    echo "" >> "ota_${device_model}.txt"

    [[ ! -f ota_links.csv ]] && echo "OTA verzia,Odkaz" > ota_links.csv
    grep -qF "$modified_link" ota_links.csv || echo "$ota_version_full,$modified_link" >> ota_links.csv

}
# 📌 Výber prefixu a modelu
clear

echo -e "${GREEN}+===================================================================================================================+${RESET}"
echo -e "${GREEN}|======${RESET}           ${GREEN}OTA FindeR${RESET}        ${YELLOW_BG}${BLACK}  realme   ${RESET}    ${GREEN_BG}${BLACK}   oppo   ${RESET}     ${RED_BG}${WHITE}  OnePlus   ${RESET}           ${RED}by${RESET}  ${BLUE}Stano36${RESET}          ${GREEN}======|${RESET}"
echo -e "${GREEN}|===================================================================================================================|${RESET}"
printf "| %-5s | %-6s | %-18s || %-5s | %-6s | %-18s || %-5s | %-6s | %-18s |\n" "Mani." "R code" "Region" "Mani." "R code" "Region" "Mani." "R code" "Region"
echo -e "+-------------------------------------------------------------------------------------------------------------------+"

keys=("${!REGIONS[@]}")
length=${#keys[@]}

for ((i = 0; i < length; i+=3)); do
    # 1. stĺpec
    key1="${keys[$i]}"
    region_data1=(${REGIONS[$key1]})
    region_code1=${region_data1[0]}
    region_name1=${region_data1[1]}

    # 2. stĺpec
    if (( i+1 < length )); then
        key2="${keys[$i+1]}"
        region_data2=(${REGIONS[$key2]})
        region_code2=${region_data2[0]}
        region_name2=${region_data2[1]}
    else
        key2=""
        region_code2=""
        region_name2=""
    fi

    # 3. stĺpec
    if (( i+2 < length )); then
        key3="${keys[$i+2]}"
        region_data3=(${REGIONS[$key3]})
        region_code3=${region_data3[0]}
        region_name3=${region_data3[1]}
    else
        key3=""
        region_code3=""
        region_name3=""
    fi

    # Výpis riadku tabuľky
    printf "|${YELLOW} %-5s${RESET} | %-6s | %-18s ||  ${YELLOW}%-4s${RESET} | %-6s | %-18s ||  ${YELLOW}%-4s${RESET} | %-6s | %-18s |\n" \
        "$key1" "$region_code1" "$region_name1" \
        "$key2" "$region_code2" "$region_name2" \
        "$key3" "$region_code3" "$region_name3"
done

echo -e "+-------------------------------------------------------------------------------------------------------------------+"
echo -e "${GREEN}+===================================================================================================================+${RESET}"
echo -e "${GREEN}|======  ${RESET}" "OTA version :  ${BLUE}A${RESET} = Launch version ,   ${BLUE}C${RESET} = First update ,   ${BLUE}F${RESET} = Second update ,   ${BLUE}H${RESET} = Third update "                    "${GREEN}=======|${RESET}"
echo -e "${GREEN}|===========  ${RESET}" "${PURPLE}*#6776#${RESET}    ${GREEN}===============  ${RESET}    ${YELLOW}Manifest:Image${RESET}      ${GREEN}===============  ${RESET}     ${BLUE}OTA version${RESET}   "         "${GREEN}============|${RESET}"
echo -e "${GREEN}+===================================================================================================================+${RESET}"
# Zoznam prefixov
echo -e "Choose model prefix:  ${YELLOW}1) RMX${RESET}, ${GREEN}2) CPH${RESET}, ${BLUE}3) Custom${RESET}, ${PURPLE}4) Selected${RESET}"
read -p "💡 Select an option (1/2/3/4): " choice

if [[ "$choice" == "4" ]]; then
    echo -e "\n📱 ${PURPLE}Selected device list :${RESET}"
echo -e "${GREEN}+========================================================================================+${RESET}"
printf "| %-2s| %-14s|  %-2s| %-2s|| %-2s| %-14s|  %-2s| %-2s|| %-2s| %-14s| %-2s | %-2s|\n" "No"  "Model" "M" "O" "No"  "Model" "M" "O" "No"  "Model" "M" "O"
echo -e "+---+---------------+----+---||---+---------------+----+---||---+---------------+----+---+"

mapfile -t devices < devices.txt
total=${#devices[@]}
third=$(( (total + 2) / 3 ))

for ((i = 0; i < third; i++)); do
    IFS='|' read -r m1 r1 v1 <<< "${devices[$i]}"

    if (( i + third < total )); then
        IFS='|' read -r m2 r2 v2 <<< "${devices[$((i + third))]}"
    else
        m2=""; r2=""; v2=""
    fi

    if (( i + 2 * third < total )); then
        IFS='|' read -r m3 r3 v3 <<< "${devices[$((i + 2 * third))]}"
    else
        m3=""; r3=""; v3=""
    fi

    printf "| ${YELLOW}%-2d${RESET}| %-14s| %-2s| %-2s|| ${YELLOW}%-2d${RESET}| %-14s| %-2s| %-2s|| ${YELLOW}%-2d${RESET}| %-14s| %-2s| %-2s|\n" \
        $((i + 1)) "$m1" "$r1" "$v1" \
        $((i + 1 + third)) "$m2" "$r2" "$v2" \
        $((i + 1 + 2 * third)) "$m3" "$r3" "$v3"
done

echo -e "${GREEN}+========================================================================================+${RESET}"


    read -p "🔢 Select device number: " selected

if [[ "$selected" == "A" || "$selected" == "a" ]]; then
    echo -e "${PURPLE}▶ Running OTA check for all devices ...${RESET}"
    for line in "${devices[@]}"; do
        IFS='|' read -r selected_model region version <<< "$line"
        device_model="$(echo $selected_model | xargs)"
        region="$(echo $region | xargs)"
        version="$(echo $version | xargs)"
        run_ota
    done
   # 🔁 Cyklus pre ďalšie voľby
while true; do
    echo -e "\n🔄 1 - Change only region/version"
    echo -e "🔄 2 - Change device model"
    echo -e "❌ 3 - End script"
    echo -e "⬇️  4 -${GREEN}$Show URLs${RESET} (long press to open the menu)"
    echo -e "     → More > Select URL"
    echo -e "     → ${PURPLE}Tap to copy the link${RESET}, ${BLUE}long press to open in browser${RESET}"
    read -p "💡 Select an option (1/2/3): " option
    case "$option" in
        1)
            read -p "📌 Manifest + OTA version : " input
            region="${input:0:${#input}-1}"
            version="${input: -1}"
            if [[ -z "${REGIONS[$region]}" || -z "${VERSIONS[$version]}" ]]; then
                echo "❌ Invalid input."
                continue
            fi
            run_ota
            ;;
        2)
            bash "$0"  # reštart skriptu
            ;;
        3)
            echo -e "👋 Goodbye."
            exit 0
            ;;
        *)
            echo "❌ Invalid option."
            ;;
    esac
done
fi
if ! [[ "$selected" =~ ^[0-9]+$ ]] || (( selected < 1 || selected > total )); then
    echo "❌ Invalid selection."; exit 1
fi

IFS='|' read -r selected_model region version <<< "${devices[$((selected-1))]}"
device_model="$(echo $selected_model | xargs)"
region="$(echo $region | xargs)"
version="$(echo $version | xargs)"
echo -e "✅ Selected device: ${PURPLE}$selected_name${RESET}  →  ${BLUE}$device_model${RESET}, ${YELLOW}$region${RESET}, ${BLUE}$version${RESET}"
else
    if [[ "$choice" == "1" ]]; then
        COLOR=$YELLOW; prefix="RMX"
    elif [[ "$choice" == "2" ]]; then
        COLOR=$GREEN; prefix="CPH"
    elif [[ "$choice" == "3" ]]; then
        read -p "🧩 Enter your custom prefix (e.g. XYZ): " prefix
        if [[ -z "$prefix" ]]; then
            echo "❌ Prefix cannot be empty."; exit 1
        fi
    else
        echo "❌ Invalid choice."; exit 1
    fi

    echo -e "${COLOR}➡️  You selected option $choice${RESET}"

    read -p "🔢 Enter model number : " model_number
    device_model="${prefix}${model_number}"
    echo -e "✅ Selected model: ${COLOR}$device_model${RESET}"

    read -p "📌 Manifest + OTA version : " input
    region="${input:0:${#input}-1}"
    version="${input: -1}"

    if [[ -z "${REGIONS[$region]}" || -z "${VERSIONS[$version]}" ]]; then
        echo -e "❌ Invalid input! Exiting."
        exit 1
    fi
fi

# ✅ Zavolanie OTA funkcie alebo skriptu
run_ota
# 🔁 Cyklus pre ďalšie voľby
while true; do
    echo -e "\n🔄 1 - Change only region/version"
    echo -e "🔄 2 - Change device model"
    echo -e "❌ 3 - End script"
    echo -e "⬇️  4 -${GREEN}$Show URLs${RESET} (long press to open the menu)"
    echo -e "     → More > Select URL"
    echo -e "     → ${PURPLE}Tap to copy the link${RESET}, ${BLUE}long press to open in browser${RESET}"
    read -p "💡 Select an option (1/2/3): " option
    case "$option" in
        1)
            read -p "📌 Manifest + OTA version : " input
            region="${input:0:${#input}-1}"
            version="${input: -1}"
            if [[ -z "${REGIONS[$region]}" || -z "${VERSIONS[$version]}" ]]; then
                echo "❌ Invalid input."
                continue
            fi
            run_ota
            ;;
        2)
            bash "$0"  # reštart skriptu
            ;;
        3)
            echo -e "👋 Goodbye."
            exit 0
            ;;
        *)
            echo "❌ Invalid option."
            ;;
    esac
done    
 
