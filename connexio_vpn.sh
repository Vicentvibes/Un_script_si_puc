#!/bin/bash

# Variables
VPN_URL="http://www.vpnbook.com/free-openvpn-account/VPNBook.com-OpenVPN-US1.zip"
VPN_CONFIG_DIR="$HOME/vpn_config"
VPN_FILE_ZIP="$VPN_CONFIG_DIR/vpnbook.zip"
VPN_USERNAME="vpnbook"
LOG_FILE="$HOME/vpn_ip_log.txt" # Fitxer per desar les IPs utilitzades
MAX_LOG_ENTRIES=10

# Neteja arxius de configuració anteriors
clean_old_files() {
    echo "Netejant arxius anteriors..."
    rm -rf $VPN_CONFIG_DIR
    mkdir -p $VPN_CONFIG_DIR
}

# Descarrega i descomprimeix el fitxer de configuració VPN
download_vpn_config() {
    echo "Descarregant la configuració VPN..."
    wget -O $VPN_FILE_ZIP $VPN_URL
    echo "Descomprimint la configuració VPN..."
    unzip -o $VPN_FILE_ZIP -d $VPN_CONFIG_DIR
}

# Obté la contrasenya dinàmica de VPNBook
get_vpn_password() {
    echo "Obtenint contrasenya de VPNBook..."
    VPN_PASSWORD=$(curl -s http://www.vpnbook.com/freevpn | grep -oP '(?<=Password: <strong>)[^<]+')
    echo "Usuari: $VPN_USERNAME"
    echo "Contrasenya: $VPN_PASSWORD"
}

# Comprova si la IP està entre les últimes 10 usades
check_ip_history() {
    local new_ip=$1
    if grep -q "$new_ip" <(tail -n $MAX_LOG_ENTRIES $LOG_FILE); then
        echo "La IP $new_ip ja es troba entre les últimes $MAX_LOG_ENTRIES IPs utilitzades. Connexió cancel·lada."
        exit 1
    fi
}

# Inicia la connexió VPN amb OpenVPN i guarda l'IP de la VPN
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

# Executa les funcions
clean_old_files
download_vpn_config
get_vpn_password
start_vpn

echo "Connexió VPN establerta i registrada amb una IP nova."
