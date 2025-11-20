#!/usr/bin/env bash
# Universal OTA Finder — cleaned + fast + original-link only (Variant C)
# by Stano36 — upravené

set -u

# Colors
RED="\e[31m"; GREEN="\e[32m"; PURPLE="\e[35m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

# Regions map: key = manifest code (like 1B, 44, 97)
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

declare -A VERSIONS=([A]="Launch version" [C]="First update" [F]="Second update" [H]="Third update")
declare -A SERVERS=( [97]="-r 1" [44]="-r 0" [51]="-r 0" )  # default server overrides

# Load models.txt once into associative array MODEL_NAMES
declare -A MODEL_NAMES
if [[ -f models.txt ]]; then
  while IFS='|' read -r codes name; do
    [[ -z "$codes" || -z "$name" ]] && continue
    # codes may be comma separated variants
    IFS=',' read -ra variants <<< "$codes"
    for code in "${variants[@]}"; do
      code_trim=$(echo "$code" | xargs)
      MODEL_NAMES["$code_trim"]="$name"
    done
  done < models.txt
fi

# Optional CN-only list (for speed) — add keys as needed
declare -A CN_MODELS
# Example: CN_MODELS[RMX3310]=1
# you can load from cn_models.txt if you prefer
if [[ -f cn_models.txt ]]; then
  while read -r c; do
    [[ -n "$c" ]] && CN_MODELS["$c"]=1
  done < cn_models.txt
fi

# Helper: detect region code from model suffix (returns region key or empty)
detect_region_from_model() {
  local dm="$1"
  if [[ "$dm" =~ EEA$ ]]; then echo "44"
  elif [[ "$dm" =~ IN$ ]]; then echo "1B"
  elif [[ "$dm" =~ TR$ ]]; then echo "51"
  elif [[ "$dm" =~ RU$ ]]; then echo "37"
  elif [[ "$dm" =~ CN$ ]]; then echo "97"
  else echo ""
  fi
}

# Extract original download link (Variant C: show only origin link).
# Accepts $output (the realme-ota raw output)
extract_original_link() {
  local out="$1"
  local link=""

  if command -v jq >/dev/null 2>&1; then
    # use jq to pick manualUrl or url inside components[].componentPackets
    link=$(printf '%s' "$out" | jq -r '
      (.components[]?.componentPackets.manuaLUrl // .components[]?.componentPackets.manualUrl // .components[]?.componentPackets.url) as $l
      | select($l != null) | $l' 2>/dev/null | head -n1 || true)
  else
    # fallback: grep/PCRE
    # try manualUrl then url under componentPackets
    link=$(printf '%s' "$out" | grep -oP '"componentPackets".*?("manualUrl"|"url")\s*:\s*"\K[^"]+' | head -n1 || true)
    # older JSON might put manualUrl earlier; fallback try any .zip or downloadCheck
    if [[ -z "$link" ]]; then
      link=$(printf '%s' "$out" | grep -oP 'https?://[^"]+(?:downloadCheck|component-ota|otacdn|heytapimg|crealme|allawnos|allawnofs)[^"]*' | head -n1 || true)
    fi
  fi

  # Trim whitespace
  link=$(echo "$link" | sed 's/["\r\n]*$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
  printf '%s' "$link"
}

# Main run_ota — takes: device_model (global), version (global), region (global)
run_ota() {
  # require device_model, region, version set
  local region_data region_code region_name nv_id server ota_model ota_command output
  region_data=(${REGIONS[$region]})
  region_code=${region_data[0]:-}
  region_name=${region_data[1]:-Unknown}
  nv_id=${region_data[2]:-00000000}
  server="${SERVERS[$region]:--r 3}"

  ota_model="$device_model"
  # remove known suffixes for building manifest base
  for rm in TR RU EEA T2 CN IN ID MY TH; do
    ota_model="${ota_model//$rm/}"
  done

  ota_command="realme-ota $server $device_model ${ota_model}_11.${version}.01_0001_100001010000 6 $nv_id"
  # run (capture stdout+stderr)
  output=$(eval "$ota_command" 2>&1)

  # If nothing returned, exit
  if [[ -z "$output" ]]; then
    return 1
  fi

  # parse common fields (safe fallbacks)
  real_ota_version=$(printf '%s' "$output" | grep -oP '"realOtaVersion"\s*:\s*"\K[^"]+' || true)
  real_version_name=$(printf '%s' "$output" | grep -oP '"realVersionName"\s*:\s*"\K[^"]+' || true)
  os_version=$(printf '%s' "$output" | grep -oP '"realOsVersion"\s*:\s*"\K[^"]+' || true)
  android_version=$(printf '%s' "$output" | grep -oP '"realAndroidVersion"\s*:\s*"\K[^"]+' || true)
  security_os=$(printf '%s' "$output" | grep -oP '"securityPatchVendor"\s*:\s*"\K[^"]+' || true)
  version_type_id=$(printf '%s' "$output" | grep -oP '"versionTypeId"\s*:\s*"\K[^"]+' || true)

  ota_f_version=$(printf '%s' "$real_ota_version" | grep -oE '_11\.[A-Z]\.[0-9]+' | sed 's/_11\.//' || true)
  ota_date=$(printf '%s' "$real_ota_version" | grep -oE '_[0-9]{12}$' | tr -d '_' || true)
  ota_version_full="${ota_model}_11.${ota_f_version}_${region_code}_${ota_date}"

  # header/forbid detection
  header_block=$(printf '%s' "$output" | sed -n '/"header"\s*:/,/]/p' | tr -d '\n' 2>/dev/null || true)
  if printf '%s' "$header_block" | grep -q 'forbid_ota_local_update=true'; then
    forbid_status="${RED}❌ Forbidden${RESET}"
  elif printf '%s' "$header_block" | grep -q 'forbid_ota_local_update=false'; then
    forbid_status="${GREEN}✔️ Allowed${RESET}"
  else
    forbid_status="${YELLOW}❓ Unknown${RESET}"
  fi

  clean_model=$(echo "$device_model" | sed 's/IN\|EEA\|RU\|TR\|T2//g')
  model_name="${MODEL_NAMES[$clean_model]:-Unknown}"

  # Print compact table header
  echo -e "\n${BLUE}${model_name}${RESET} (${clean_model}) ${GREEN}${region_name}${RESET} (code: ${YELLOW}${region_code}${RESET})"
  echo -e "+--------------------+"
  printf "| %-18s | %s\n" "OTA version:" "${ota_version_full:-N/A}"
  printf "| %-18s | %s\n" "Displayed version:" "${real_version_name:-N/A}"
  printf "| %-18s | %s\n" "Android version:" "${android_version:-N/A}"
  printf "| %-18s | %s\n" "OS version:" "${os_version:-N/A}"
  printf "| %-18s | %s\n" "Security patch:" "${security_os:-N/A}"
  printf "| %-18s | %s\n" "Version:" "${version_type_id:-N/A}"
  printf "| %-18s | %b\n" "Local install:" "$forbid_status"
  echo -e "+--------------------+"

  # About panel
  about_update_url=$(printf '%s' "$output" | grep -oP '"panelUrl"\s*:\s*"\K[^"]+' || true)
  if [[ -n "$about_update_url" ]]; then
    echo -e "  📥 About this update:\n${GREEN}${about_update_url}${RESET}"
  fi

  # Extract original link (variant C behavior: show only origin)
  original_link=$(extract_original_link "$output")

  # If found, print it (only original link). If not found, print nothing (silent).
  if [[ -n "$original_link" ]]; then
    echo -e "  📥 Original direct link:\n${GREEN}${original_link}${RESET}"

    # Save to files
    echo "${ota_version_full}" >> "ota_${device_model}.txt"
    echo "${original_link}" >> "ota_${device_model}.txt"
    echo "" >> "ota_${device_model}.txt"

    [[ ! -f ota_links.csv ]] && echo "OTA verzia,Odkaz" > ota_links.csv
    grep -qF "${original_link}" ota_links.csv || echo "${ota_version_full},${original_link}" >> ota_links.csv
  fi

  return 0
}

# Helper: run search for all regions or limited
run_all_variants_search() {
  local model="$1"
  local version="$2"

  # if model explicitly listed as CN-only, search CN only
  if [[ -n "${CN_MODELS[$model]:-}" ]]; then
    region="97"
    run_ota
    return
  fi

  # otherwise search across all known manifest keys
  for r in "${!REGIONS[@]}"; do
    region="$r"
    run_ota
  done
}

# -------------------------------
# Start menu + main loop
# -------------------------------
clear
echo -e "${GREEN}+=====================================+${RESET}"
echo -e "${GREEN}|==${RESET} ${GREEN}   OTA Finder (clean)${RESET}   ${GREEN}==|${RESET}"
echo -e "${GREEN}+=====================================+${RESET}"

main_menu_select_model() {
  echo -e "📦 Model: 1) RMX, 2) CPH, 3) Custom, 4) Selected (devices.txt), 5) Search by name"
  read -p "💡 Select an option (1/2/3/4/5): " choice
  case "$choice" in
    1) prefix="RMX";;
    2) prefix="CPH";;
    3) read -p "🧩 Enter custom prefix: " prefix;;
    4)
      if [[ ! -f devices.txt ]]; then
        echo -e "${RED}devices.txt not found.${RESET}"; return 1
      fi
      mapfile -t lines < devices.txt
      echo -e "\nSaved devices:"
      for i in "${!lines[@]}"; do
        IFS='|' read -r mm rr vv <<< "${lines[$i]}"
        base=$(echo "$mm" | sed 's/EEA\|IN\|TR\|RU\|CN//g')
        echo "$((i+1)). ${MODEL_NAMES[$base]:-Unknown} ($mm)"
      done
      read -p "🔢 Select device number: " sel
      if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#lines[@]} )); then
        IFS='|' read -r device_model region version <<< "${lines[$((sel-1))]}"
        device_model=$(echo "$device_model" | xargs)
        return 0
      else
        echo "Invalid selection"; return 1
      fi
      ;;
    5)
      read -p "🔍 Search model by name (or leave blank): " sname
      if [[ -z "$sname" ]]; then return 1; fi
      # list matches from models.txt
      matches=()
      for k in "${!MODEL_NAMES[@]}"; do
        name="${MODEL_NAMES[$k]}"
        if [[ "${name,,}" =~ "${sname,,}" ]]; then
          matches+=("$k|$name")
        fi
      done
      if [[ ${#matches[@]} -eq 0 ]]; then
        echo "No matches"; return 1
      fi
      # group by name: show unique names with their variants
      declare -A GROUP
      for entry in "${matches[@]}"; do
        code="${entry%%|*}"; name="${entry##*|}"
        GROUP["$name"]+="${GROUP[$name]:+ }$code"
      done
      i=1
      for nm in "${!GROUP[@]}"; do
        echo "$i) $nm -> ${GROUP[$nm]}"
        idx2[$i]="$nm"
        ((i++))
      done
      read -p "🔢 Select model number (1-$((i-1))): " mc
      selname="${idx2[$mc]}"
      variants="${GROUP[$selname]}"
      device_model=""  # clear — we'll iterate variants later
      model_name_sel="$selname"
      model_variants=($variants)
      return 0
      ;;
    *)
      echo "Invalid option"; return 1;;
  esac

  # if prefix path chosen, ask number
  if [[ -z "${device_model:-}" ]]; then
    read -p "🔢 Enter model number: " num
    device_model="${prefix}${num}"
  fi
  return 0
}

# initial selection
while ! main_menu_select_model; do :; done

# if chosen by search-by-name, model_variants array is set
if [[ -n "${model_variants[*]:-}" ]]; then
  echo -e "\n✅ Selected device: ${PURPLE}${model_name_sel}${RESET}"
  echo -e "📦 Variants: ${YELLOW}${model_variants[*]}${RESET}"
  read -p "🧩 Enter OTA version (A/C/F/H): " version
  version="${version^^}"
  for v in "${model_variants[@]}"; do
    device_model="$v"
    # if CN-only list contains the variant, restrict
    if [[ -n "${CN_MODELS[$device_model]:-}" ]]; then
      region="97"
      run_ota
    else
      run_all_variants_search "$device_model" "$version"
    fi
  done
else
  # single-device flow
  model_name="${MODEL_NAMES[$(echo "$device_model" | sed 's/EEA\|IN\|TR\|RU\|CN//g')]:-Unknown}"
  detected_region="$(detect_region_from_model "$device_model")"
  if [[ -n "$detected_region" ]]; then
    echo -e "Detected region: ${YELLOW}${detected_region}${RESET}"
    read -p "🧩 Enter OTA version (A/C/F/H): " version
    version="${version^^}"
    region="$detected_region"
  else
    read -p "📌 Manifest + OTA version (e.g. 33F): " input
    region="${input:0:${#input}-1}"
    version="${input: -1}"
  fi
  # If model is flagged CN-only, force CN search
  if [[ -n "${CN_MODELS[$device_model]:-}" ]]; then
    region="97"
    run_ota
  else
    run_all_variants_search "$device_model" "$version"
  fi
fi

# Main interaction loop (change version / change device / exit)
while true; do
  echo -e "\n🔄 1 - Change OTA version"
  echo -e "🔄 2 - Change device model"
  echo -e "❌ 3 - End script"
  read -p "💡 Select an option (1/2/3): " option
  case "$option" in
    1)
      if [[ -n "${region:-}" ]]; then
        read -p "🧩 Enter OTA version (A/C/F/H): " version
        version="${version^^}"
      else
        read -p "📌 Manifest + OTA version (e.g. 33F): " input
        region="${input:0:${#input}-1}"
        version="${input: -1}"
      fi
      # keep device_model and rerun
      if [[ -n "${device_model:-}" ]]; then
        if [[ -n "${CN_MODELS[$device_model]:-}" ]]; then region="97"; run_ota; else run_all_variants_search "$device_model" "$version"; fi
      else
        echo "No device selected"
      fi
      ;;
    2)
      # change device model without restarting — fast
      unset device_model region version model_variants model_name_sel model_name
      while ! main_menu_select_model; do :; done
      # repeat selection flow (same as above)
      if [[ -n "${model_variants[*]:-}" ]]; then
        echo -e "\n✅ Selected device: ${PURPLE}${model_name_sel}${RESET}"
        echo -e "📦 Variants: ${YELLOW}${model_variants[*]}${RESET}"
        read -p "🧩 Enter OTA version (A/C/F/H): " version
        version="${version^^}"
        for v in "${model_variants[@]}"; do
          device_model="$v"
          if [[ -n "${CN_MODELS[$device_model]:-}" ]]; then region="97"; run_ota; else run_all_variants_search "$device_model" "$version"; fi
        done
      else
        model_name="${MODEL_NAMES[$(echo "$device_model" | sed 's/EEA\|IN\|TR\|RU\|CN//g')]:-Unknown}"
        detected_region="$(detect_region_from_model "$device_model")"
        if [[ -n "$detected_region" ]]; then
          echo -e "Detected region: ${YELLOW}${detected_region}${RESET}"
          read -p "🧩 Enter OTA version (A/C/F/H): " version
          version="${version^^}"
          region="$detected_region"
        else
          read -p "📌 Manifest + OTA version (e.g. 33F): " input
          region="${input:0:${#input}-1}"
          version="${input: -1}"
        fi
        if [[ -n "${CN_MODELS[$device_model]:-}" ]]; then region="97"; run_ota; else run_all_variants_search "$device_model" "$version"; fi
      fi
      ;;
    3)
      echo -e "👋 Goodbye."; exit 0;;
    *)
      echo "Invalid option";;
  esac
done

