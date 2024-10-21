#!/bin/bash

# Comprovar que hi ha dos arguments
if [ "$#" -ne 2 ]; then
  echo " Cal utilitzar aquest script de a següent manera: $0 <path_script> <principi|final>"
  exit 1
fi

# Arguments
SCRIPT_PATH=$1
SESIO=$2

# Comprovar si el path existeix
if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: L'script $SCRIPT_PATH no existeix o el path és incorrecte."
  exit 1
fi

# Opció "principi" - Afegir a l'inici de l'arrencada del sistema
if [ "$SESIO" == "principi" ]; then
  echo "Afegint l'script $SCRIPT_PATH a l'inici de l'arrencada del sistema..."

  # Comprovar si l'script ja està afegit
  if ! grep -q "$SCRIPT_PATH" /etc/rc.local; then
    # Afegeix l'script al final de /etc/rc.local abans de l'exit 0
    sudo sed -i "/^exit 0/i $SCRIPT_PATH" /etc/rc.local
    echo "L'script s'executarà a al arrancar el sistema."
  else
    echo "L'script ja està configurat per executar-se a l'inici."
  fi

# Opció "final" - Afegir a l'apagat del sistema
elif [ "$SESIO" == "final" ]; then
  echo "Afegint l'script $SCRIPT_PATH a l'apagada del sistema..."

  # Crear un fitxer de servei systemd per a l'apagada del sistema
  SERVICE_PATH="/etc/systemd/system/executar_script_apagada.service"

  # Crear el fitxer del servei si no existeix
  if [ ! -f "$SERVICE_PATH" ]; then
    sudo bash -c "cat > $SERVICE_PATH" <<EOL
[Unit]
Description=Executar script a l'apagada del sistema
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStop=$SCRIPT_PATH
RemainAfterExit=true

[Install]
WantedBy=halt.target shutdown.target reboot.target
EOL

    # Activar el servei
    sudo systemctl enable executar_script_apagada.service
    echo "L'script s'executarà a l'apagada del sistema."
  else
    echo "L'script ja està configurat per executar-se a l'apagada."
  fi

else
  echo "Error: El segon argument ha de ser 'principi' o 'final'."
  exit 1
fi

