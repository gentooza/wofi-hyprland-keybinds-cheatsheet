#!/bin/bash

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"



function htmlEscape () {
    local s
    s=${1//&/&amp;}
    s=${s//</&lt;}
    s=${s//>/&gt;}
    s=${s//'"'/&quot;}
    printf -- %s "$s"
}
export -f htmlEscape
# extract the keybinding from hyprland.conf
#mapfile -t BINDINGS < <(grep '^bind[[:space:]]*=' "$HYPR_CONF" | \
#    sed -e 's/  */ /g' -e 's/bind=//g' -e 's/, /,/g' -e 's/# /,/' | \
#    awk -F, -v q="'" '{cmd=""; for(i=3;i<NF;i++) cmd=cmd $(i) " "; system('bash -c '\''htmlescape '"<b>"$1 " + " $2 "</b>  <i>" $NF ",</i><span color=" q "gray" q ">" cmd "</span>"'')}')

WIDTH=$(echo -e "$(hyprctl -j monitors)" | jq -r '.[] | select (.focused==true) | .width')
HEIGHT=$(echo -e "$(hyprctl -j monitors)" | jq -r '.[] | select (.focused==true) | .height')
SCALE=$(echo -e "$(hyprctl -j monitors)" | jq -r '.[] | select (.focused==true) | .scale')
MARGIN=100
# Procesar los bindings desde el archivo de configuración
# Procesar líneas bind desde el archivo
mapfile -t BINDINGS < <(grep '^bind[[:space:]]*=' "$HYPR_CONF" | while read -r LINE; do
    # Separar comentario (si existe)
    CMD_PART="${LINE%%#*}"
    COMMENT_PART="${LINE#*#}"

    # Extraer el contenido después de "bind = "
    BIND_CONTENT="${CMD_PART#*=}"
    BIND_CONTENT=$(echo "$BIND_CONTENT" | xargs)  # eliminar espacios extremos

    # Dividir en partes (modificador, tecla, comando, argumentos...)
    IFS=',' read -r MOD KEY CMD_ARG <<< "$BIND_CONTENT"
    REST=$(echo "$BIND_CONTENT" | cut -d',' -f4-)

    # Escapar el contenido del comando completo
    ESCAPED_CMD=$(htmlEscape "$CMD_ARG${REST:+,}${REST}")

    # Salida en formato HTML
    printf "<b>bind = %s + %s</b>  " "$MOD" "$KEY"
    printf "<i>%s</i>\n" "$(echo "$COMMENT_PART" | xargs)"
#    printf "<span color='gray'> %s</span>\n" "$ESCAPED_CMD"
done)
printf	'%s\n' "${BINDINGS[@]}"
#MARGIN=$(echo "scale=0; $MARGIN*$SCALE" | bc)
WOFI_W=$(echo "scale=0; $WIDTH/$SCALE" | bc)
WOFI_W=$(echo "scale=0; $WOFI_W-$MARGIN" | bc)
WOFI_H=$(echo "scale=0; $HEIGHT/$SCALE" | bc)
WOFI_H=$(echo "scale=0; $WOFI_H-$MARGIN" | bc)
echo ${WOFI_W}
set -x;
CHOICE=$(printf '%s\n' "${BINDINGS[@]}" | wofi --width "${WOFI_W}" --height "${WOFI_H}" --dmenu --allow-markup -p "Hyprland Keybinds:")
set +x;
# extract cmd from span <span color='gray'>cmd</span>
CMD=$(echo "$CHOICE" | sed -n 's/.*<span color='\''gray'\''>\(.*\)<\/span>.*/\1/p')

hyprctl dispatch "$CMD"

echo $CMD

# execute it if first word is exec else use hyprctl dispatch
if [[ $CMD == exec* ]]; then
    eval "$CMD"
else
    hyprctl dispatch "$CMD"
fi

