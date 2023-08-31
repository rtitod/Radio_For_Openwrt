#!/bin/sh
# Rudy Tito Durand
# requiere los siguientes paquetes curl, ffmpeg,  kmod-usb-audio , kmod-sound-core , alsa-utils 
# leer https://openwrt.org/docs/guide-user/hardware/audio/usb.audio para configurar la tarjeta de sonido

# Definicion de la lista de URLs de las estaciones de radio
radio_urls="
http://23103.live.streamtheworld.com/CRP_RIT_SC?pop
http://us-b5-p-e-wo1-audio.cdn.mdstrm.com/live-audio-aw/5fab0687bcd6c2389ee9480c?rock
https://cpliv3.onliv3.com/stream/radiozeta
http://stream-159.zeno.fm/8u6kahy9b9quv?zs=-C-s-KAnQe2c5uf3ijiC-Q
"
radio_names="
Ritmo Romantica
Oxigeno
Z-Rock And Pop
AERO STEREO
"
# Función para obtener la URL y el nombre en función del índice seleccionado
get_selected_station() {
    local index="$1"
    local url_name=$(echo "$radio_names" | awk -v IDX="$index" 'BEGIN{ RS = "" ; FS = "\n" }{print $(IDX + 1)}')
    local url=$(echo "$radio_urls" | awk -v IDX="$index" 'BEGIN{ RS = "" ; FS = "\n" }{print $(IDX + 1)}')
    echo "$url_name|$url"
}

#Funcion para reproducir una estacion de radio
play_radio(){
    url="$1"
    while true; do
        if curl -k "$url" 2>/dev/null | ffmpeg -i - -f mp2 - 2>/dev/null | madplay - ; then
	     echo "Reconectando..."
	else
             echo "Error al reproducir. Reconectando..."
        fi
    done
}
                                                                                                                                                      
# Funcion para comprobar la cabecera y luego reproducir                                                                                                     
check_header_and_play() {                                   
    url="$1"
    if curl -k --head "$url" 2>/dev/null | grep -i "Content-Type: audio" >/dev/null; then
        play_radio "$url"
    elif curl -k --head "$url" 2>/dev/null | grep -i "405 Method Not Allowed" >/dev/null; then
        echo "El servidor devuelve '405 Method Not Allowed'."
        echo "Reproducir a pesar del error '405 Method Not Allowed'? (y/n)"
        read choice
        if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
            play_radio "$url"
	else
            echo "Opción seleccionada: No reproducir."
        fi
    else
        echo "La URL no es válida o no se puede acceder a ella."
    fi
}                                                    
                                                     
# Menu interactivo
while true; do     
    echo "Selecciona una estacion de radio para reproducir:"
    i=0                                                      
    for url in $radio_urls; do
        url_name=$(get_selected_station $i | cut -d '|' -f 1)                             
        echo "$i) $url_name"
        i=$((i + 1))           
    done                       
    echo "q) Salir" 
                   
    printf "Opción: "
    read option       
                      
    case $option in
        q)         
            echo "Saliendo..."
            break             
            ;;                
        [0-9]*)  
            if [ $option -ge 0 ] && [ $option -lt $i ]; then
                selected=$(get_selected_station $option)
                selected_url_name=$(echo "$selected" | cut -d '|' -f 1)
                selected_url=$(echo "$selected" | cut -d '|' -f 2)
                echo "Reproduciendo la Estación $selected_url_name $selected_url. Presione (Ctrl C) para salir."
                check_header_and_play "$selected_url"                            
            else                                                       
                echo "Opción inválida."                              
            fi                                                         
            ;;                                                         
        *)                                                             
            echo "Opción inválida."                                  
            ;;                                                         
    esac                                                               
done  

