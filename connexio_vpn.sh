#!/bin/bash

# Variables
VPN_URL="http://www.vpnbook.com/free-openvpn-account/VPNBook.com-OpenVPN-US1.zip"
VPN_CONFIG_DIR="$HOME/vpn_config"
VPN_FILE_ZIP="$VPN_CONFIG_DIR/vpnbook.zip"
VPN_USERNAME="vpnbook"
LOG_FILE="/var/log/connexio_vpn.txt" # Fitxer per desar les IPs utilitzades
MAX_LOG_ENTRIES=10

# Comprova si s'està executant amb permisos d'administrador
if [[ $EUID -ne 0 ]]; then
   echo "Aquest script ha de ser executat com a superusuari (utilitza sudo)." 
   exit 1
fi

# Manual d’ús
mostra_ajuda() {
  cat << EOF
Ús: sudo ./script_vpn.sh [arguments]

Descripció:
  Aquest script estableix una connexió VPN segura mitjançant VPNBook, realitzant diverses accions:
     - L'script neteja arxius de connexions VPN anteriors.
     - Descarrega la configuració actualitzada de VPNBook.
     - Obté una IP nova, assegurant que no coincidisca amb les últimes 10 IPs utilitzades. 
     - Cada connexió es registra en un fitxer de logs per fer seguiment.

Arguments:
  -h, --help       Mostra aquest manual.


Requisits:
   - Paquets necessaris: openvpn, curl, wget, unzip


Funcionalitats:
  - Neteja qualsevol configuració VPN prèvia de la carpeta de configuració.
  - Descarrega i descomprimeix els fitxers de configuració de VPNBook.
  - Obté la contrasenya actualitzada de VPNBook.
  - Estableix una connexió VPN i comprova que la IP assignada no estiga entre les últimes 10 IPs usades.
  - Desa la IP nova en un fitxer de logs ($LOG_FILE) amb la data i hora de connexió.

EOF
}

# Mostra el manual si s'utilitza l'opció -h o --help
if [[ $1 == "-h" || $1 == "--help" ]]; then
    mostra_ajuda
    exit 0
fi

# Funció per netejar arxius de configuració anteriors
clean_old_files() {
    echo "Netejant arxius anteriors..."
    rm -rf $VPN_CONFIG_DIR
    mkdir -p $VPN_CONFIG_DIR
}

# Funció per descarregar i descomprimir el fitxer de configuració VPN
download_vpn_config() {
    echo "Descarregant la configuració VPN..."
    wget -O $VPN_FILE_ZIP $VPN_URL
    echo "Descomprimint la configuració VPN..."
    unzip -o $VPN_FILE_ZIP -d $VPN_CONFIG_DIR
}

# Funció per obtenir la contrasenya dinàmica de VPNBook
get_vpn_password() {
    echo "Obtenint contrasenya de VPNBook..."
    VPN_PASSWORD=$(curl -s http://www.vpnbook.com/freevpn | grep -oP '(?<=Password: <strong>)[^<]+')
    echo "Usuari: $VPN_USERNAME"
    echo "Contrasenya: $VPN_PASSWORD"
}

# Funció per comprovar si la IP està entre les últimes 10 usades
check_ip_history() {
    local new_ip=$1
    if grep -q "$new_ip" <(tail -n $MAX_LOG_ENTRIES $LOG_FILE); then
        echo "La IP $new_ip ja es troba entre les últimes $MAX_LOG_ENTRIES IPs utilitzades. Connexió cancel·lada."
        exit 1
    fi
}

# Funció per iniciar la connexió VPN i guardar la IP
start_vpn() {
    echo "Iniciant connexió VPN..."
    openvpn --config "$VPN_CONFIG_DIR/vpnbook-us1-tcp80.ovpn" --auth-user-pass <(echo -e "$VPN_USERNAME\n$VPN_PASSWORD") &
    sleep 10  # Espera perquè la connexió es complete

    # Obté la nova IP pública assignada per la VPN
    NEW_IP=$(curl -s ifconfig.me)
    echo "IP assignada per la VPN: $NEW_IP"

    # Comprova que la nova IP no estiga entre les últimes 10
    check_ip_history "$NEW_IP"

    # Si la IP és nova, guarda-la en el log
    echo "$(date): [VPN] IP assignada - $NEW_IP" | tee -a $LOG_FILE
    echo "La nova IP s'ha desat al log."
}

# Execució de les funcions principals
clean_old_files
download_vpn_config
get_vpn_password
start_vpn

echo "Connexió VPN establerta i registrada amb una IP nova."
