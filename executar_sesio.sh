#!/bin/bash

# Comprovar si l'script s'està executant com a root (usuari amb uid 0)
if [ "$(id -u)" -ne 0 ]; then
  echo "Aquest script necessita ser executat amb permisos d'administrador (root)."
  echo "Utilitza 'sudo' o inicia sessió com a root."
  exit 1
fi

# Comprovar que hi ha dos arguments
if [ "$#" -ne 2 ]; then
  echo "Ús: $0 <path_script> <principi|final>"
  exit 1
fi

# Arguments
SCRIPT_PATH=$1
SESIO=$2

# Comprovar si el path existeix
if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: L'script $SCRIPT_PATH no existeix."
  exit 1
fi

# Comprovar que l'script és executable
if [ ! -x "$SCRIPT_PATH" ]; then
  echo "Error: L'script $SCRIPT_PATH no té permisos d'execució. Estableix-los amb 'chmod +x'."
  exit 1
fi

# Opció "principi" - Afegir a l'inici de l'arrencada del sistema
if [ "$SESIO" == "principi" ]; then
  echo "Afegint l'script $SCRIPT_PATH a l'inici de l'arrencada del sistema..."

  # Afegeix l'script a /etc/rc.local, que s'executa com a root per defecte
  if ! grep -q "$SCRIPT_PATH" /etc/rc.local; then
    sudo sed -i "/^exit 0/i $SCRIPT_PATH" /etc/rc.local
    echo "L'script s'executarà a l'inici de l'arrencada del sistema com a root."
  else
    echo "L'script ja està configurat per executar-se a l'inici."
  fi

# Opció "final" - Afegir a l'apagada del sistema amb un servei separat per a cada script
elif [ "$SESIO" == "final" ]; then
  echo "Afegint l'script $SCRIPT_PATH a l'apagada del sistema..."

  # Creem un nom únic per al servei, utilitzant el nom de l'script
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
User=root  #CUIDAO!!! SI EL TEU root NO ÉS "root"!!!!!!!
RemainAfterExit=true

[Install]
WantedBy=halt.target shutdown.target reboot.target
EOL

    # Activar el servei
    sudo systemctl enable "$SERVICE_NAME"
    echo "L'script s'executarà a l'apagada del sistema com a root."
  else
    echo "L'script ja està configurat per executar-se a l'apagada."
  fi

else
  echo "Error: El segon argument ha de ser 'principi' o 'final'."
  exit 1
fi

