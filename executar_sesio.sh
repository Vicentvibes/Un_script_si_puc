#!/bin/bash

# Manual
mostra_ajuda() {
  cat << EOF
Ús: sudo ./executar_sesio.sh <path_script> <principi|final> [esborrar]

Descripció:
  Aquest script permet gestionar l'execució d'altres scripts al principi de la sessió (inici del sistema) o al final de la sessió (apagada o reinici del sistema) en un sistema Linux. Proporciona funcionalitats per afegir, esborrar i llistar els scripts configurats. A més, registra totes les accions en un fitxer de logs amb informació sobre l'usuari i el moment en què s'ha realitzat cada acció.

Arguments:
  <path_script>    El camí COMPLET de l'script que es vol afegir o esborrar.
  <principi|final> Indica si l'script ha de ser afegit a l'inici de sessió ("principi") o a l'apagada ("final").
  [esborrar]       Opcional. Si es proporciona, l'script especificat serà esborrat de la configuració d'inici o final.

Opcions especials:
  -h, --help       Mostra aquest manual.
  llista           Mostra una llista de tots els scripts configurats per executar-se tant a l'inici com al final de la sessió.

Requisits:
  Ha d'executar-se amb permisos d'administrador (root/sudo).
  Els scripts que es volen afegir han de tenir permisos d'execució.

EOF
}

# Comprovar si l'usuari ha demanat ajuda
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  mostra_ajuda
  exit 0
fi

# Comprovar si l'script s'està executant com a root (usuari amb uid 0)
if [ "$(id -u)" -ne 0 ]; then
  echo "Aquest script necessita ser executat amb permisos d'administrador (root)."
  echo "Utilitza 'sudo' o inicia sessió com a root."
  exit 1
fi

# Funció per llistar els scripts afegits a l'inici i final amb systemd
llista_scripts() {
  echo "Scripts programats per a l'inici de sessió (systemd):"
  ls /etc/systemd/system/*_inici.service 2>/dev/null | sed 's/^.*\/\(.*\)_inici.service/\1/'
  echo
  echo "Scripts programats per a l'apagada del sistema (systemd):"
  ls /etc/systemd/system/*_apagada.service 2>/dev/null | sed 's/^.*\/\(.*\)_apagada.service/\1/'
}

# Funció per registrar accions a un log amb timestamp i usuari
log_action() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local user=$(whoami)
  echo "$timestamp - Usuari: $user - $1" >> /var/log/executar_sesio.log
}

# Si l'argument és "llista", mostrar els scripts
if [ "$1" == "llista" ]; then
  llista_scripts
  exit 0
fi

# Comprovar que hi ha almenys dos arguments
if [ "$#" -lt 2 ]; then
  echo "Aquest script s'utilitza de la següent forma: $0 <path_script_complet> <principi|final> [esborrar]"
  exit 1
fi

# Arguments
SCRIPT_PATH=$1
SESIO=$2
OPERACIO=${3:-}

# Comprovar si el path existeix, només si no estem esborrant
if [ "$OPERACIO" != "esborrar" ] && [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: L'script $SCRIPT_PATH no existeix."
  exit 1
fi

# Comprovar que l'script és executable, només si no estem esborrant
if [ "$OPERACIO" != "esborrar" ] && [ ! -x "$SCRIPT_PATH" ]; then
  echo "Error: L'script $SCRIPT_PATH no té permisos d'execució. Estableix-los amb 'chmod +x'."
  exit 1
fi

# Si l'operació és "esborrar"
if [ "$OPERACIO" == "esborrar" ]; then
  if [ "$SESIO" == "principi" ]; then
    echo "Esborrant l'script $SCRIPT_PATH de l'inici de sessió..."
    SERVICE_NAME=$(basename "$SCRIPT_PATH" .sh)_inici.service
    if sudo systemctl disable "$SERVICE_NAME" --now; then
      sudo rm "/etc/systemd/system/$SERVICE_NAME"
      log_action "Esborrat l'script $SCRIPT_PATH de l'inici de sessió."
      echo "Script esborrat de l'inici de sessió."
    else
      echo "Hi ha hagut un problema en desactivar el servei."
      exit 1
    fi

  elif [ "$SESIO" == "final" ]; then
    echo "Esborrant l'script $SCRIPT_PATH de l'apagada del sistema..."
    SERVICE_NAME=$(basename "$SCRIPT_PATH" .sh)_apagada.service
    if sudo systemctl disable "$SERVICE_NAME" --now; then
      sudo rm "/etc/systemd/system/$SERVICE_NAME"
      log_action "Esborrat l'script $SCRIPT_PATH de l'apagada del sistema."
      echo "Script esborrat de l'apagada del sistema."
    else
      echo "Hi ha hagut un problema en desactivar el servei."
      exit 1
    fi
  else
    echo "Error: El segon argument ha de ser 'principi' o 'final'."
    exit 1
  fi
  exit 0
fi

# Afegir l'script a l'inici o a l'apagada del sistema utilitzant systemd

if [ "$SESIO" == "principi" ]; then
  echo "Afegint l'script $SCRIPT_PATH a l'inici de l'arrencada del sistema..."

  SERVICE_NAME=$(basename "$SCRIPT_PATH" .sh)_inici.service
  SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

  # Crear el fitxer del servei si no existeix
  if [ ! -f "$SERVICE_PATH" ]; then
    sudo bash -c "cat > $SERVICE_PATH" <<EOL
[Unit]
Description=Executar $SCRIPT_PATH a l'inici del sistema
DefaultDependencies=no
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
User=root
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOL

    # Activar el servei amb comprovació d'errors
    if sudo systemctl enable "$SERVICE_NAME"; then
      log_action "Afegit l'script $SCRIPT_PATH a l'inici del sistema."
      echo "L'script s'executarà a l'inici del sistema com a root."
    else
      echo "Hi ha hagut un problema en activar el servei."
      log_action "Error en activar l'script $SCRIPT_PATH a l'inici del sistema."
      exit 1
    fi
  else
    echo "L'script ja està configurat per executar-se a l'inici."
  fi

elif [ "$SESIO" == "final" ]; then
  echo "Afegint l'script $SCRIPT_PATH a l'apagada del sistema..."

  SERVICE_NAME=$(basename "$SCRIPT_PATH" .sh)_apagada.service
  SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

  # Crear el fitxer del servei si no existeix
  if [ ! -f "$SERVICE_PATH" ]; then
    sudo bash -c "cat > $SERVICE_PATH" <<EOL
[Unit]
Description=Executar $SCRIPT_PATH a l'apagada del sistema
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStop=$SCRIPT_PATH
User=root
RemainAfterExit=true

[Install]
WantedBy=halt.target shutdown.target reboot.target
EOL

    # Activar el servei amb comprovació d'errors
    if sudo systemctl enable "$SERVICE_NAME"; then
      log_action "Afegit l'script $SCRIPT_PATH a l'apagada del sistema."
      echo "L'script s'executarà a l'apagada del sistema com a root."
    else
      echo "Hi ha hagut un problema en activar el servei."
      log_action "Error en activar l'script $SCRIPT_PATH a l'apagada del sistema."
      exit 1
    fi
  else
    echo "L'script ja està configurat per executar-se a l'apagada."
  fi

else
  echo "Error: El segon argument ha de ser 'principi' o 'final'."
  exit 1
fi



