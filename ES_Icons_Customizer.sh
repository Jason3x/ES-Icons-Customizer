#!/bin/bash

#------------------------------------#
#      ES Icons Customizer - R36S    #
#            By Jason                #
#------------------------------------#

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -E "$0" "$@"
fi

CURR_TTY="/dev/tty1"
BACKTITLE="ES Icons Customizer R36S - By Jason -"
SVG_BACKUP_DIR="/home/ark/.es_icons_backup"
BACKUP_FLAG="/home/ark/.es_icons_backup_done"
COLORS_FILE="/home/ark/.es_icon_colors"
WIFI_CHOICE_FILE="/tmp/es_wifi_choice"
BT_CHOICE_FILE="/tmp/es_bt_choice"

if [ -d "/usr/share/emulationstation/resources" ]; then
    RES="/usr/share/emulationstation/resources"
elif [ -d "/etc/emulationstation/resources" ]; then
    RES="/etc/emulationstation/resources"
else
    RES="/usr/bin/emulationstation/resources"
fi

SVG_FILES=(
    "network.svg" "network_active.svg" "network_off.svg"
    "network_share.svg" "network_service.svg"
    "bluetooth.svg" "bluetooth_active.svg" "bluetooth_off.svg"
)

# Couleurs par defaut
active_color="#43a047"
idle_color="#fb8c00"
off_color="#b71c1c"
share_color="#46a1f4"
service_color="#fdd835"

# Charger les couleurs sauvegardees
[ -f "$COLORS_FILE" ] && source "$COLORS_FILE"

# Init console
printf "\033c" > "$CURR_TTY"
printf "\e[?25l" > "$CURR_TTY"
dialog --clear

if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
    setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
else
    setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz
fi

pkill -9 -f gptokeyb || true
pkill -9 -f osk.py    || true

printf "\033c" > "$CURR_TTY"
for i in {1..2}; do
    printf "Starting ES Icons Customizer...\nPlease wait." > "$CURR_TTY"
    sleep 0.6
    printf "\033c" > "$CURR_TTY"
    sleep 0.4
done

printf "\033c" > "$CURR_TTY"
printf "\n\n" > "$CURR_TTY"
printf "      ========================================\n" > "$CURR_TTY"
printf "          Welcome to ES Icons Customizer      \n" > "$CURR_TTY"
printf "                   By Jason                   \n" > "$CURR_TTY"
printf "      ========================================\n" > "$CURR_TTY"
sleep 2
printf "\033c" > "$CURR_TTY"

smooth_progress() {
    local msg=$1 delay=$2 start_val=$3 end_val=$4
    for ((i=start_val; i<=end_val; i++)); do
        echo "$i"
        echo "XXX"; echo -e "$msg"; echo "XXX"
        sleep "$delay"
    done
}

# Dépendance pour la preview
PREVIEW_AVAILABLE=0

# Vérification
check_preview_deps() {
    if command -v rsvg-convert >/dev/null 2>&1 && command -v chafa >/dev/null 2>&1; then
        PREVIEW_AVAILABLE=1
    else
        PREVIEW_AVAILABLE=0
    fi
}

# Installation des dépendances
install_deps() {
    local missing=()
    command -v rsvg-convert >/dev/null 2>&1 || missing+=("librsvg2-bin")
    command -v chafa        >/dev/null 2>&1 || missing+=("chafa")
    [ ${#missing[@]} -eq 0 ] && return 0

    dialog --backtitle "$BACKTITLE" --title " Dependencies " \
        --yesno "\nPackages required for icon preview:\n\n\nInstall now? (requires internet)" \
        11 55 > "$CURR_TTY"
    [ $? -ne 0 ] && return 1

    (
        smooth_progress "Updating package lists..." 0.05 0 20
        apt-get update -y > /dev/null 2>&1
        smooth_progress "Installing Dependencies..." 0.08 21 90
        apt-get install -y "${missing[@]}" > /dev/null 2>&1
        smooth_progress "Done!" 0.02 91 100
    ) | dialog --backtitle "$BACKTITLE" --title " Installing Dependencies " \
        --gauge "\nPlease wait..." 8 55 0 > "$CURR_TTY"

    local failed=()
    command -v rsvg-convert >/dev/null 2>&1 || failed+=("librsvg2-bin")
    command -v chafa        >/dev/null 2>&1 || failed+=("chafa")

    if [ ${#failed[@]} -gt 0 ]; then
        dialog --backtitle "$BACKTITLE" --title " Dependencies " \
            --msgbox "\nInstallation failed:\n  ${failed[*]}\n\nCheck your internet connection." \
            9 50 > "$CURR_TTY"
        return 1
    fi
    dialog --backtitle "$BACKTITLE" --title " Dependencies " \
        --msgbox "\nInstalled successfully!\nPreview is now available." \
        8 48 > "$CURR_TTY"
    return 0
}

# Previsualisation
show_preview() {
    local func_name=$1
    local temp_svg="/tmp/es_preview.svg"
    local temp_png="/tmp/es_preview.png"

    if [ "$PREVIEW_AVAILABLE" -eq 0 ]; then
        dialog --backtitle "$BACKTITLE" --title " Preview " \
            --msgbox "\nPreview unavailable.\n\nUse option 6 in main menu\nto install dependencies." \
            10 50 > "$CURR_TTY"
        return
    fi

    $func_name "$temp_svg"
    rsvg-convert -w 200 -h 200 "$temp_svg" -o "$temp_png" 2>/dev/null

    if [ ! -f "$temp_png" ]; then
        dialog --backtitle "$BACKTITLE" --title " Preview " \
            --msgbox "\nConversion failed." 6 40 > "$CURR_TTY"
        rm -f "$temp_svg"
        return
    fi

    printf "\033c" > "$CURR_TTY"
    chafa --size=30x20 --colors=256 "$temp_png" > "$CURR_TTY"
    printf "\n  [ Press any button to return ]\n" > "$CURR_TTY"
    rm -f "$temp_svg" "$temp_png"

    read -r -n1 -t 30 < /dev/tty1 2>/dev/null || true
    printf "\033c" > "$CURR_TTY"
}

# Sauvegardes des icônes
backup_svgs_if_needed() {
    [ -f "$BACKUP_FLAG" ] && return 0
    mkdir -p "$SVG_BACKUP_DIR"
    local backed=0
    for f in "${SVG_FILES[@]}"; do
        if [ -f "$RES/$f" ]; then
            cp "$RES/$f" "$SVG_BACKUP_DIR/$f"
            backed=$((backed+1))
        fi
    done
    touch "$BACKUP_FLAG"
    [ "$backed" -gt 0 ] && dialog --backtitle "$BACKTITLE" --title " First Run — Backup " \
        --msgbox "\nFirst run detected!\n\n$backed SVG icon(s) backed up to:\n$SVG_BACKUP_DIR\n\nThis backup will not be overwritten." \
        12 55 > "$CURR_TTY"
}

# Restauration des icônes
Restore_Icons() {
    if [ ! -f "$BACKUP_FLAG" ]; then
        dialog --backtitle "$BACKTITLE" --title " Restore " \
            --msgbox "\nNo backup found.\n\nLaunch this script once with\noriginal icons to create a backup." \
            10 55 > "$CURR_TTY"
        return
    fi
    local count=0
    for f in "${SVG_FILES[@]}"; do [ -f "$SVG_BACKUP_DIR/$f" ] && count=$((count+1)); done

    dialog --backtitle "$BACKTITLE" --title " Restore " \
        --yesno "\nRestore original SVG icons?\n\n$count file(s) in backup.\nEmulationStation will restart." \
        10 55 > "$CURR_TTY"
    [ $? -ne 0 ] && return

    (
        smooth_progress "Restoring original icons..." 0.07 0 90
        for f in "${SVG_FILES[@]}"; do
            if [ -f "$SVG_BACKUP_DIR/$f" ]; then cp "$SVG_BACKUP_DIR/$f" "$RES/$f"
            else rm -f "$RES/$f"; fi
        done
        smooth_progress "Done!" 0.03 91 100
        sleep 1
    ) | dialog --backtitle "$BACKTITLE" --title " Restore " \
        --gauge "\nRestoring..." 8 55 0 > "$CURR_TTY"

    dialog --backtitle "$BACKTITLE" --title " Restore " \
        --msgbox "\nOriginal icons restored!\n\nRestarting EmulationStation..." \
        9 50 > "$CURR_TTY"
    touch /tmp/es-restart
    killall emulationstation
    Exit_Script
}


# Couleurs 
# Index : 1=rouge 2=bleu 3=vert 4=gris 5=orange 6=violet 7=jaune 8=blanc
COLOR_VALUES=("" "#b71c1c" "#46a1f4" "#43a047" "#9e9e9e" "#fb8c00" "#8e24aa" "#fdd835" "#ffffff")
COLOR_LABELS=("" "\Z1\ZbRed\Zn" "\Z4\ZbBlue\Zn" "\Z2\ZbGreen\Zn" "\ZbGrey\Zn" "\Z1\ZbOrange\Zn" "\Z5\ZbPurple\Zn" "\Z3\ZbYellow\Zn" "\Z7\ZbWhite\Zn")

# Sauvegarde des couleurs
save_colors() {
    cat > "$COLORS_FILE" << COLOREOF
active_color="$active_color"
idle_color="$idle_color"
off_color="$off_color"
share_color="$share_color"
service_color="$service_color"
COLOREOF
}

# Couleurs connues
color_label() {
    local hex="$1"
    case "$hex" in
        "#b71c1c") echo "\Z1\ZbRed\Zn"    ;;
        "#46a1f4") echo "\Z4\ZbBlue\Zn"   ;;
        "#43a047") echo "\Z2\ZbGreen\Zn"  ;;
        "#9e9e9e") echo "\ZbGrey\Zn"      ;;
        "#fb8c00") echo "\Z1\ZbOrange\Zn" ;;
        "#8e24aa") echo "\Z5\ZbPurple\Zn" ;;
        "#fdd835") echo "\Z3\ZbYellow\Zn" ;;
        "#ffffff") echo "\Z7\ZbWhite\Zn"  ;;
        *)         echo "\Zb$hex\Zn"      ;;
    esac
}

# Saisie manuelle d'une couleur Hex
pick_custom_hex() {
    local current_val="$1"
    local tmp_osk="/tmp/es_osk_out"
 
    while true; do
        pkill -9 -f gptokeyb || true
        export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
        clear > "$CURR_TTY"
 
        # Capturer valeur 
        osk "Custom Color  #RRGGBB" "" > "$tmp_osk"
        local osk_ret=$?
 
        if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
    setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
else
    setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz
fi
        
        clear > "$CURR_TTY"
        /opt/inttools/gptokeyb -1 "dialog" -c "/opt/inttools/keys.gptk" >/dev/null 2>&1 &
 
        # Cancel
        if [ $osk_ret -ne 0 ]; then
            rm -f "$tmp_osk"
            return 1
        fi
 
        local hex_input
        hex_input=$(head -1 "$tmp_osk" 2>/dev/null | tr -d '\r\n\t ')
        rm -f "$tmp_osk"
 
       
        if [[ "$hex_input" =~ [^0-9a-fA-F#] ]]; then
            return 1
        fi
 
        # Strip # si l'utilisateur l'a tapé
        hex_input="${hex_input#\#}"
 
        # Champ vide avec #
        if [ -z "$hex_input" ]; then
            dialog --colors --backtitle "$BACKTITLE" \
                --title " Invalid Color " \
                --msgbox "\n\Z1Empty value!\Zn\n\nExpected: \Zb#RRGGBB\Zn  (6 hex digits)\nExample : \Zb#ff4400\Zn\n\nPlease try again." \
                12 45 > "$CURR_TTY"
            continue
        fi
 
        # Prefixer avec #
        hex_input="#$hex_input"
 
        # Validation format #RRGGBB
        if [[ "$hex_input" =~ ^#[0-9a-fA-F]{6}$ ]]; then
            printf '%s' "${hex_input,,}" > /tmp/es_custom_result
            return 0
        else
            dialog --colors --backtitle "$BACKTITLE" \
                --title " Invalid Color " \
                --msgbox "\n\Z1Invalid format!\Zn\n\nExpected: \Zb#RRGGBB\Zn  (6 hex digits)\nExample : \Zb#ff4400\Zn\n\nPlease try again." \
                12 45 > "$CURR_TTY"
        fi
    done
}

# Choix des couleurs
pick_color() {
    local var_name="$1"
    local current_val="$2"
    local title="$3"
    local current_label
    current_label=$(color_label "$current_val")
    local tmp_choice="/tmp/es_pick_choice"

    dialog --colors --backtitle "$BACKTITLE" --title " Color — $title " \
        --cancel-label "Back" \
        --menu "\nCurrent : $current_label\n\nChoose a color:" 16 45 9 \
        1 "${COLOR_LABELS[1]}" \
        2 "${COLOR_LABELS[2]}" \
        3 "${COLOR_LABELS[3]}" \
        4 "${COLOR_LABELS[4]}" \
        5 "${COLOR_LABELS[5]}" \
        6 "${COLOR_LABELS[6]}" \
        7 "${COLOR_LABELS[7]}" \
        8 "${COLOR_LABELS[8]}" \
        9 "\ZbCustom  #RRGGBB ...\Zn" \
        2>"$tmp_choice" > "$CURR_TTY"
    [ $? -ne 0 ] && { rm -f "$tmp_choice"; return 1; }

    local choice
    choice=$(cat "$tmp_choice" 2>/dev/null)
    rm -f "$tmp_choice"

    if [ "$choice" = "9" ]; then
        rm -f /tmp/es_custom_result
        pick_custom_hex "$current_val" || return 1
        local custom_hex
        custom_hex=$(cat /tmp/es_custom_result 2>/dev/null)
        rm -f /tmp/es_custom_result
        [ -z "$custom_hex" ] && return 1
        eval "$var_name='$custom_hex'"
    elif [ -z "$choice" ]; then
        return 1
    else
        eval "$var_name='${COLOR_VALUES[$choice]}'"
    fi

    save_colors
    return 0
}

# Menu pour les couleurs
Color_Menu() {
    while true; do
        local lbl_active  lbl_idle  lbl_off  lbl_share  lbl_service
        lbl_active=$(color_label  "$active_color")
        lbl_idle=$(color_label    "$idle_color")
        lbl_off=$(color_label     "$off_color")
        lbl_share=$(color_label   "$share_color")
        lbl_service=$(color_label "$service_color")

        selection=$(dialog --colors --backtitle "$BACKTITLE" --title " Color Settings " \
            --cancel-label "Back" \
            --menu "\nConfigure icon colors :\n" 14 52 7 \
            1 "Active  (connected)   $lbl_active" \
            2 "Idle    (up, no IP)   $lbl_idle" \
            3 "Off     (disabled)    $lbl_off" \
            4 "Share   (hotspot)     $lbl_share" \
            5 "Service               $lbl_service" \
            2>&1 > "$CURR_TTY")
        [ $? -ne 0 ] && return

        case $selection in
            1) pick_color "active_color"  "$active_color"  "Active (connected)" ;;
            2) pick_color "idle_color"    "$idle_color"    "Idle (up, no IP)"   ;;
            3) pick_color "off_color"     "$off_color"     "Off (disabled)"     ;;
            4) pick_color "share_color"   "$share_color"   "Share (hotspot)"    ;;
            5) pick_color "service_color" "$service_color" "Service"            ;;
        esac
    done
}


# SVG
_svg_kirby() {
    local color="$1" path="$2" is_off="${3:-0}"
    local d="#1a1a1a" hl="white" ck="#FF8CB0" line=""
    [ "$is_off" = "1" ] && { d="#555555"; hl="#555555"; ck="#888888"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <circle cx="18" cy="20" r="14" fill="$color"/>
  <ellipse cx="13" cy="17" rx="2.8" ry="3.8" fill="$d"/>
  <ellipse cx="23" cy="17" rx="2.8" ry="3.8" fill="$d"/>
  <circle cx="14.3" cy="15.3" r="1.3" fill="#5588FF" opacity="0.9"/>
  <circle cx="24.3" cy="15.3" r="1.3" fill="#5588FF" opacity="0.9"/>
  <circle cx="14.9" cy="14.8" r="0.5" fill="$hl"/>
  <circle cx="24.9" cy="14.8" r="0.5" fill="$hl"/>
  <circle cx="9" cy="22.5" r="3.5" fill="$ck" opacity="0.55"/>
  <circle cx="27" cy="22.5" r="3.5" fill="$ck" opacity="0.55"/>
  <ellipse cx="18" cy="25" rx="2.5" ry="2" fill="$d"/>
  <ellipse cx="13" cy="34.5" rx="4.5" ry="2.5" fill="$color"/>
  <ellipse cx="23" cy="34.5" rx="4.5" ry="2.5" fill="$color"/>
$line
</svg>
SVGEOF
}

_svg_invader() {
    local color="$1" path="$2" is_off="${3:-0}"
    local d="#1a1a2e" line=""
    [ "$is_off" = "1" ] && { d="#555555"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <rect x="10" y="3" width="4" height="5" rx="1" fill="$color"/>
  <rect x="22" y="3" width="4" height="5" rx="1" fill="$color"/>
  <rect x="7" y="8" width="22" height="8" rx="2" fill="$color"/>
  <rect x="10" y="10" width="5" height="5" rx="1" fill="$d"/>
  <rect x="21" y="10" width="5" height="5" rx="1" fill="$d"/>
  <rect x="5" y="16" width="26" height="9" rx="1" fill="$color"/>
  <rect x="1" y="17" width="4" height="5" rx="1" fill="$color"/>
  <rect x="31" y="17" width="4" height="5" rx="1" fill="$color"/>
  <rect x="7" y="25" width="5" height="5" rx="1" fill="$color"/>
  <rect x="24" y="25" width="5" height="5" rx="1" fill="$color"/>
  <rect x="5" y="28" width="5" height="5" rx="1" fill="$color"/>
  <rect x="26" y="28" width="5" height="5" rx="1" fill="$color"/>
$line
</svg>
SVGEOF
}

_svg_ghost() {
    local color="$1" path="$2" is_off="${3:-0}"
    local ew="white" ep="#1a1a1a" eh="white" smile="white" line=""
    [ "$is_off" = "1" ] && { ew="#999999"; ep="#555555"; eh="#999999"; smile="#aaaaaa"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <path d="M5 34 L5 15 Q5 3 18 3 Q31 3 31 15 L31 34 L27.5 29.5 L23.5 34 L18 29.5 L12.5 34 L8.5 29.5 Z" fill="$color"/>
  <circle cx="13" cy="15" r="4.5" fill="$ew"/>
  <circle cx="23" cy="15" r="4.5" fill="$ew"/>
  <circle cx="13.8" cy="16" r="2.5" fill="$ep"/>
  <circle cx="23.8" cy="16" r="2.5" fill="$ep"/>
  <circle cx="14.8" cy="14.8" r="1" fill="$eh"/>
  <circle cx="24.8" cy="14.8" r="1" fill="$eh"/>
  <path d="M13 23 Q18 27 23 23" stroke="$smile" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.7"/>
$line
</svg>
SVGEOF
}

_svg_totoro() {
    local color="$1" path="$2" is_off="${3:-0}"
    local d="#1a1a1a" belly="white" wh="#1a1a1a" line=""
    [ "$is_off" = "1" ] && { d="#555555"; belly="#888888"; wh="#888888"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <ellipse cx="9" cy="8" rx="4" ry="7" fill="$color" transform="rotate(-10,9,8)"/>
  <ellipse cx="27" cy="8" rx="4" ry="7" fill="$color" transform="rotate(10,27,8)"/>
  <ellipse cx="18" cy="23" rx="14" ry="13" fill="$color"/>
  <ellipse cx="18" cy="26" rx="8" ry="9" fill="$belly" opacity="0.18"/>
  <circle cx="13" cy="18" r="4" fill="$belly" opacity="0.85"/>
  <circle cx="23" cy="18" r="4" fill="$belly" opacity="0.85"/>
  <circle cx="13.5" cy="19" r="2.5" fill="$d"/>
  <circle cx="23.5" cy="19" r="2.5" fill="$d"/>
  <circle cx="14.5" cy="18" r="0.8" fill="$belly"/>
  <circle cx="24.5" cy="18" r="0.8" fill="$belly"/>
  <ellipse cx="18" cy="22.5" rx="1.5" ry="1" fill="$d"/>
  <line x1="9" y1="24" x2="15" y2="24" stroke="$wh" stroke-width="0.9" opacity="0.45"/>
  <line x1="9" y1="26" x2="15" y2="25.5" stroke="$wh" stroke-width="0.9" opacity="0.45"/>
  <line x1="21" y1="24" x2="27" y2="24" stroke="$wh" stroke-width="0.9" opacity="0.45"/>
  <line x1="21" y1="25.5" x2="27" y2="26" stroke="$wh" stroke-width="0.9" opacity="0.45"/>
  <path d="M13 28.5 L18 25 L23 28.5" stroke="$wh" stroke-width="1" fill="none" opacity="0.2"/>
$line
</svg>
SVGEOF
}

_svg_robot() {
    local color="$1" path="$2" is_off="${3:-0}"
    local d="#1a1a2e" led="#00FFAA" line=""
    [ "$is_off" = "1" ] && { d="#555555"; led="#888888"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <line x1="18" y1="1" x2="18" y2="7" stroke="$color" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="18" cy="1" r="2.5" fill="$color"/>
  <rect x="4" y="7" width="28" height="22" rx="5" fill="$color"/>
  <rect x="8" y="13" width="8" height="6" rx="1.5" fill="$d"/>
  <rect x="20" y="13" width="8" height="6" rx="1.5" fill="$d"/>
  <rect x="9" y="14" width="6" height="4" rx="1" fill="$led" opacity="0.85"/>
  <rect x="21" y="14" width="6" height="4" rx="1" fill="$led" opacity="0.85"/>
  <rect x="9" y="23" width="3" height="2" rx="0.8" fill="$d" opacity="0.7"/>
  <rect x="14" y="23" width="3" height="2" rx="0.8" fill="$d" opacity="0.7"/>
  <rect x="19" y="23" width="3" height="2" rx="0.8" fill="$d" opacity="0.7"/>
  <rect x="24" y="23" width="3" height="2" rx="0.8" fill="$d" opacity="0.7"/>
  <circle cx="4" cy="17" r="3" fill="$color"/>
  <circle cx="32" cy="17" r="3" fill="$color"/>
$line
</svg>
SVGEOF
}

_svg_alien() {
    local color="$1" path="$2" is_off="${3:-0}"
    local d="#1a1a1a" sub="#333333" line=""
    [ "$is_off" = "1" ] && { d="#555555"; sub="#777777"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <ellipse cx="18" cy="14" rx="14" ry="13" fill="$color"/>
  <ellipse cx="11.5" cy="12" rx="5.5" ry="3.5" fill="$d" transform="rotate(-18,11.5,12)"/>
  <ellipse cx="24.5" cy="12" rx="5.5" ry="3.5" fill="$d" transform="rotate(18,24.5,12)"/>
  <ellipse cx="9.8" cy="10.8" rx="1.5" ry="1" fill="$sub" transform="rotate(-18,9.8,10.8)"/>
  <ellipse cx="22.8" cy="10.8" rx="1.5" ry="1" fill="$sub" transform="rotate(18,22.8,10.8)"/>
  <path d="M15.5 19.5 Q17 21.5 18 20.5 Q19 21.5 20.5 19.5" stroke="$sub" stroke-width="0.9" fill="none"/>
  <path d="M13 23.5 Q18 26.5 23 23.5" stroke="$sub" stroke-width="1.2" fill="none" stroke-linecap="round"/>
  <rect x="14.5" y="26.5" width="7" height="5" rx="3" fill="$color"/>
  <path d="M11.5 31.5 L14.5 28.5 M24.5 31.5 L21.5 28.5" stroke="$color" stroke-width="3" stroke-linecap="round" fill="none"/>
$line
</svg>
SVGEOF
}

_svg_skull() {
    local color="$1" path="$2" is_off="${3:-0}"
    local d="#0f0f1a" line=""
    [ "$is_off" = "1" ] && { d="#555555"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <path d="M4 23 C4 7 32 7 32 23 L32 28 L4 28 Z" fill="$color"/>
  <rect x="7" y="27" width="22" height="8" rx="3" fill="$color"/>
  <rect x="11" y="28.5" width="3" height="5.5" fill="$d" rx="1"/>
  <rect x="16.5" y="28.5" width="3" height="5.5" fill="$d" rx="1"/>
  <rect x="22" y="28.5" width="3" height="5.5" fill="$d" rx="1"/>
  <ellipse cx="13" cy="20" rx="4.5" ry="5.5" fill="$d"/>
  <ellipse cx="23" cy="20" rx="4.5" ry="5.5" fill="$d"/>
  <path d="M16 26 L18 23.5 L20 26 Z" fill="$d"/>
$line
</svg>
SVGEOF
}

_svg_cat() {
    local color="$1" path="$2" is_off="${3:-0}"
    local d="#1a1a1a" pk="#FF99BB" wh="#1a1a1a" hl="white" line=""
    [ "$is_off" = "1" ] && { d="#555555"; pk="#888888"; wh="#888888"; hl="#888888"
        line='  <line x1="4" y1="4" x2="32" y2="32" stroke="#1a1a1a" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>'; }
    cat > "$path" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
  <polygon points="6,16 4,3 14,12" fill="$color"/>
  <polygon points="7.5,13.5 5.5,6 12,11" fill="$pk" opacity="0.5"/>
  <polygon points="30,16 32,3 22,12" fill="$color"/>
  <polygon points="28.5,13.5 30.5,6 24,11" fill="$pk" opacity="0.5"/>
  <ellipse cx="18" cy="22" rx="13" ry="12" fill="$color"/>
  <circle cx="12.5" cy="19" r="3.5" fill="$d"/>
  <ellipse cx="12.5" cy="19" rx="1" ry="3.2" fill="#555555"/>
  <circle cx="13.8" cy="17.8" r="1" fill="$hl"/>
  <circle cx="23.5" cy="19" r="3.5" fill="$d"/>
  <ellipse cx="23.5" cy="19" rx="1" ry="3.2" fill="#555555"/>
  <circle cx="24.8" cy="17.8" r="1" fill="$hl"/>
  <polygon points="18,22.5 16.5,24.5 19.5,24.5" fill="$pk"/>
  <path d="M16.5 24.5 Q15 26.5 14 25.5" stroke="$wh" stroke-width="1.1" fill="none" stroke-linecap="round"/>
  <path d="M19.5 24.5 Q21 26.5 22 25.5" stroke="$wh" stroke-width="1.1" fill="none" stroke-linecap="round"/>
  <line x1="3" y1="22" x2="13" y2="22.5" stroke="$wh" stroke-width="0.9" opacity="0.55"/>
  <line x1="3" y1="24.5" x2="13" y2="24" stroke="$wh" stroke-width="0.9" opacity="0.55"/>
  <line x1="23" y1="22.5" x2="33" y2="22" stroke="$wh" stroke-width="0.9" opacity="0.55"/>
  <line x1="23" y1="24" x2="33" y2="24.5" stroke="$wh" stroke-width="0.9" opacity="0.55"/>
$line
</svg>
SVGEOF
}

# Ecriture des icônes Wifi
write_wifi_kirby()   { local p="${1:-}"; [ -n "$p" ] && { _svg_kirby   "$active_color" "$p"; return; }; _svg_kirby   "$active_color" "$RES/network.svg"; _svg_kirby   "$idle_color" "$RES/network_active.svg"; _svg_kirby   "$off_color" "$RES/network_off.svg" 1; _svg_kirby   "$share_color" "$RES/network_share.svg"; _svg_kirby   "$service_color" "$RES/network_service.svg"; }
write_wifi_invader() { local p="${1:-}"; [ -n "$p" ] && { _svg_invader "$active_color" "$p"; return; }; _svg_invader "$active_color" "$RES/network.svg"; _svg_invader "$idle_color" "$RES/network_active.svg"; _svg_invader "$off_color" "$RES/network_off.svg" 1; _svg_invader "$share_color" "$RES/network_share.svg"; _svg_invader "$service_color" "$RES/network_service.svg"; }
write_wifi_ghost()   { local p="${1:-}"; [ -n "$p" ] && { _svg_ghost   "$active_color" "$p"; return; }; _svg_ghost   "$active_color" "$RES/network.svg"; _svg_ghost   "$idle_color" "$RES/network_active.svg"; _svg_ghost   "$off_color" "$RES/network_off.svg" 1; _svg_ghost   "$share_color" "$RES/network_share.svg"; _svg_ghost   "$service_color" "$RES/network_service.svg"; }
write_wifi_totoro()  { local p="${1:-}"; [ -n "$p" ] && { _svg_totoro  "$active_color" "$p"; return; }; _svg_totoro  "$active_color" "$RES/network.svg"; _svg_totoro  "$idle_color" "$RES/network_active.svg"; _svg_totoro  "$off_color" "$RES/network_off.svg" 1; _svg_totoro  "$share_color" "$RES/network_share.svg"; _svg_totoro  "$service_color" "$RES/network_service.svg"; }
write_wifi_robot()   { local p="${1:-}"; [ -n "$p" ] && { _svg_robot   "$active_color" "$p"; return; }; _svg_robot   "$active_color" "$RES/network.svg"; _svg_robot   "$idle_color" "$RES/network_active.svg"; _svg_robot   "$off_color" "$RES/network_off.svg" 1; _svg_robot   "$share_color" "$RES/network_share.svg"; _svg_robot   "$service_color" "$RES/network_service.svg"; }
write_wifi_alien()   { local p="${1:-}"; [ -n "$p" ] && { _svg_alien   "$active_color" "$p"; return; }; _svg_alien   "$active_color" "$RES/network.svg"; _svg_alien   "$idle_color" "$RES/network_active.svg"; _svg_alien   "$off_color" "$RES/network_off.svg" 1; _svg_alien   "$share_color" "$RES/network_share.svg"; _svg_alien   "$service_color" "$RES/network_service.svg"; }
write_wifi_skull()   { local p="${1:-}"; [ -n "$p" ] && { _svg_skull   "$active_color" "$p"; return; }; _svg_skull   "$active_color" "$RES/network.svg"; _svg_skull   "$idle_color" "$RES/network_active.svg"; _svg_skull   "$off_color" "$RES/network_off.svg" 1; _svg_skull   "$share_color" "$RES/network_share.svg"; _svg_skull   "$service_color" "$RES/network_service.svg"; }
write_wifi_cat()     { local p="${1:-}"; [ -n "$p" ] && { _svg_cat     "$active_color" "$p"; return; }; _svg_cat     "$active_color" "$RES/network.svg"; _svg_cat     "$idle_color" "$RES/network_active.svg"; _svg_cat     "$off_color" "$RES/network_off.svg" 1; _svg_cat     "$share_color" "$RES/network_share.svg"; _svg_cat     "$service_color" "$RES/network_service.svg"; }

# Ecriture des icônes Bluetooth
write_bt_kirby()   { local p="${1:-}"; [ -n "$p" ] && { _svg_kirby   "$active_color" "$p"; return; }; _svg_kirby   "$active_color" "$RES/bluetooth.svg"; _svg_kirby   "$idle_color" "$RES/bluetooth_active.svg"; _svg_kirby   "$off_color" "$RES/bluetooth_off.svg" 1; }
write_bt_invader() { local p="${1:-}"; [ -n "$p" ] && { _svg_invader "$active_color" "$p"; return; }; _svg_invader "$active_color" "$RES/bluetooth.svg"; _svg_invader "$idle_color" "$RES/bluetooth_active.svg"; _svg_invader "$off_color" "$RES/bluetooth_off.svg" 1; }
write_bt_ghost()   { local p="${1:-}"; [ -n "$p" ] && { _svg_ghost   "$active_color" "$p"; return; }; _svg_ghost   "$active_color" "$RES/bluetooth.svg"; _svg_ghost   "$idle_color" "$RES/bluetooth_active.svg"; _svg_ghost   "$off_color" "$RES/bluetooth_off.svg" 1; }
write_bt_totoro()  { local p="${1:-}"; [ -n "$p" ] && { _svg_totoro  "$active_color" "$p"; return; }; _svg_totoro  "$active_color" "$RES/bluetooth.svg"; _svg_totoro  "$idle_color" "$RES/bluetooth_active.svg"; _svg_totoro  "$off_color" "$RES/bluetooth_off.svg" 1; }
write_bt_robot()   { local p="${1:-}"; [ -n "$p" ] && { _svg_robot   "$active_color" "$p"; return; }; _svg_robot   "$active_color" "$RES/bluetooth.svg"; _svg_robot   "$idle_color" "$RES/bluetooth_active.svg"; _svg_robot   "$off_color" "$RES/bluetooth_off.svg" 1; }
write_bt_alien()   { local p="${1:-}"; [ -n "$p" ] && { _svg_alien   "$active_color" "$p"; return; }; _svg_alien   "$active_color" "$RES/bluetooth.svg"; _svg_alien   "$idle_color" "$RES/bluetooth_active.svg"; _svg_alien   "$off_color" "$RES/bluetooth_off.svg" 1; }
write_bt_skull()   { local p="${1:-}"; [ -n "$p" ] && { _svg_skull   "$active_color" "$p"; return; }; _svg_skull   "$active_color" "$RES/bluetooth.svg"; _svg_skull   "$idle_color" "$RES/bluetooth_active.svg"; _svg_skull   "$off_color" "$RES/bluetooth_off.svg" 1; }
write_bt_cat()     { local p="${1:-}"; [ -n "$p" ] && { _svg_cat     "$active_color" "$p"; return; }; _svg_cat     "$active_color" "$RES/bluetooth.svg"; _svg_cat     "$idle_color" "$RES/bluetooth_active.svg"; _svg_cat     "$off_color" "$RES/bluetooth_off.svg" 1; }

# Noms des icones 
ICON_NAMES=("" "Kirby" "Space Invader" "Ghost" "Totoro" "Robot" "Alien" "Skull" "Cat")

# Application des icônes Wifi
_apply_wifi() {
    local w=$1
    rm -f "$RES/network.svg" "$RES/network_active.svg" "$RES/network_off.svg" \
          "$RES/network_share.svg" "$RES/network_service.svg"
    case $w in
        1) write_wifi_kirby   ;; 2) write_wifi_invader ;;
        3) write_wifi_ghost   ;; 4) write_wifi_totoro  ;;
        5) write_wifi_robot   ;; 6) write_wifi_alien   ;;
        7) write_wifi_skull   ;; 8) write_wifi_cat     ;;
    esac
}

Apply_WiFi() {
    local w wifi_name
    w=$(cat "$WIFI_CHOICE_FILE")
    wifi_name="${ICON_NAMES[$w]}"
    _apply_wifi "$w"
    (smooth_progress "\nApplying WiFi: $wifi_name..." 0.03 0 100) \
        | dialog --backtitle "$BACKTITLE" --title " Apply " \
            --gauge "\nWriting WiFi icons..." 8 55 0 > "$CURR_TTY"
    dialog --backtitle "$BACKTITLE" --title " Apply " \
        --msgbox "\nWiFi icon applied!\n\n  WiFi : $wifi_name\n  Colors used from current settings.\n\nRestarting EmulationStation..." \
        11 58 > "$CURR_TTY"
    touch /tmp/es-restart; killall emulationstation; Exit_Script
}

# Application des icônes Bluetooth
_apply_bt() {
    local b=$1
    rm -f "$RES/bluetooth.svg" "$RES/bluetooth_active.svg" "$RES/bluetooth_off.svg"
    case $b in
        1) write_bt_kirby   ;; 2) write_bt_invader ;;
        3) write_bt_ghost   ;; 4) write_bt_totoro  ;;
        5) write_bt_robot   ;; 6) write_bt_alien   ;;
        7) write_bt_skull   ;; 8) write_bt_cat     ;;
    esac
}

Apply_BT() {
    local b bt_name
    b=$(cat "$BT_CHOICE_FILE")
    bt_name="${ICON_NAMES[$b]}"
    _apply_bt "$b"
    (smooth_progress "\nApplying Bluetooth: $bt_name..." 0.03 0 100) \
        | dialog --backtitle "$BACKTITLE" --title " Apply " \
            --gauge "\nWriting Bluetooth icons..." 8 55 0 > "$CURR_TTY"
    dialog --backtitle "$BACKTITLE" --title " Apply " \
        --msgbox "\nBluetooth icon applied!\n\n  Bluetooth : $bt_name\n  Colors used from current settings.\n\nRestarting EmulationStation..." \
        11 58 > "$CURR_TTY"
    touch /tmp/es-restart; killall emulationstation; Exit_Script
}

# Application des icônes Wifi & Bluetooth
Apply_Both() {
    local w b wifi_name bt_name
    w=$(cat "$WIFI_CHOICE_FILE"); b=$(cat "$BT_CHOICE_FILE")
    wifi_name="${ICON_NAMES[$w]}"; bt_name="${ICON_NAMES[$b]}"
    _apply_wifi "$w"; _apply_bt "$b"
    (smooth_progress "Applying $wifi_name + $bt_name..." 0.03 0 100) \
        | dialog --backtitle "$BACKTITLE" --title " Apply " \
            --gauge "\nWriting SVG icons..." 8 55 0 > "$CURR_TTY"
    dialog --backtitle "$BACKTITLE" --title " Apply " \
        --msgbox "\nIcons applied!\n\n  WiFi      : $wifi_name\n  Bluetooth : $bt_name\n  Colors from current settings.\n\nRestarting EmulationStation..." \
        12 58 > "$CURR_TTY"
    touch /tmp/es-restart; killall emulationstation; Exit_Script
}

# Menu pour les icônes Wifi
Menu_WiFi() {
    local default_item=1
    while true; do
        selection=$(dialog --colors --backtitle "$BACKTITLE" --title " WiFi Icon " \
            --extra-button --extra-label "Preview" \
            --cancel-label "Back" \
            --default-item "$default_item" \
            --menu "\nChoose a WiFi icon style:" 16 50 7 \
            1 "Kirby" \
            2 "Space Invader" \
            3 "Ghost" \
            4 "Totoro" \
            5 "Robot" \
            6 "Alien" \
            7 "Skull" \
            8 "Cat" \
            2>&1 > "$CURR_TTY")
        ret=$?
        case $ret in
            1) return 1 ;;
            3)
                default_item=$selection
                case $selection in
                    1) show_preview "write_wifi_kirby"   ;; 2) show_preview "write_wifi_invader" ;;
                    3) show_preview "write_wifi_ghost"   ;; 4) show_preview "write_wifi_totoro"  ;;
                    5) show_preview "write_wifi_robot"   ;; 6) show_preview "write_wifi_alien"   ;;
                    7) show_preview "write_wifi_skull"   ;; 8) show_preview "write_wifi_cat"     ;;
                esac ;;
            0) echo "$selection" > "$WIFI_CHOICE_FILE"; return 0 ;;
        esac
    done
}

# Menu pour les icônes Bluetooth
Menu_Bluetooth() {
    local default_item=1
    while true; do
        selection=$(dialog --colors --backtitle "$BACKTITLE" --title " Bluetooth Icon " \
            --extra-button --extra-label "Preview" \
            --cancel-label "Back" \
            --default-item "$default_item" \
            --menu "\nChoose a Bluetooth icon style:" 16 50 7 \
            1 "Kirby" \
            2 "Space Invader" \
            3 "Ghost" \
            4 "Totoro" \
            5 "Robot" \
            6 "Alien" \
            7 "Skull" \
            8 "Cat" \
            2>&1 > "$CURR_TTY")
        ret=$?
        case $ret in
            1) return 1 ;;
            3)
                default_item=$selection
                case $selection in
                    1) show_preview "write_bt_kirby"   ;; 2) show_preview "write_bt_invader" ;;
                    3) show_preview "write_bt_ghost"   ;; 4) show_preview "write_bt_totoro"  ;;
                    5) show_preview "write_bt_robot"   ;; 6) show_preview "write_bt_alien"   ;;
                    7) show_preview "write_bt_skull"   ;; 8) show_preview "write_bt_cat"     ;;
                esac ;;
            0) echo "$selection" > "$BT_CHOICE_FILE"; return 0 ;;
        esac
    done
}

# Exit
Exit_Script() {
    printf "\033c" > "$CURR_TTY"
    printf "\e[?25h" > "$CURR_TTY"
    pkill -f "gptokeyb" || true
    exit 0
}

# Menu Principal
Main_Menu() {
    while true; do
        if [ -f "$BACKUP_FLAG" ]; then BACKUP_STATUS="\Z2Backup found\Zn"
        else BACKUP_STATUS="\Z1No backup\Zn"; fi
        if [ "$PREVIEW_AVAILABLE" -eq 1 ]; then PREVIEW_STATUS="\Z2Available\Zn"
        else PREVIEW_STATUS="\Z1Not installed\Zn"; fi

        selection=$(dialog --colors --backtitle "$BACKTITLE" --title " MAIN MENU " \
            --cancel-label "Exit" \
            --menu "\nBackup: $BACKUP_STATUS  |  Preview: $PREVIEW_STATUS\n\nCustomize your EmulationStation icons:" 16 50 7 \
            1 "Configure Colors" \
            2 "Change WiFi icon only" \
            3 "Change Bluetooth icon only" \
            4 "Change both icons" \
            5 "Restore original icons" \
            6 "Install Preview Dependencies" \
            2>&1 > "$CURR_TTY")

        [ $? -ne 0 ] && Exit_Script

        case $selection in
            1) Color_Menu ;;        
            2) Menu_WiFi      || continue; Apply_WiFi ;;
            3) Menu_Bluetooth || continue; Apply_BT   ;;
            4) Menu_WiFi      || continue; Menu_Bluetooth || continue; Apply_Both ;;
            5) Restore_Icons ;;
            6) install_deps; check_preview_deps ;;
        esac
    done
}

export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"

/opt/inttools/gptokeyb -1 "dialog" -c "/opt/inttools/keys.gptk" > /dev/null 2>&1 &

trap Exit_Script EXIT

backup_svgs_if_needed
check_preview_deps

Main_Menu
