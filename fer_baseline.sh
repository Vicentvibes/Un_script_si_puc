#!/bin/bash

# TODO: cal guardar encara els arxius de configuració.
# TODO: cal fer test en Kali

# Variables globals
BACKUP_DIR="$HOME/backups/baseline" #CUIDAO!!! Els baseline NO es guarden en una carpeta dins de /var/backups, si no en una carpeta dintre de cada usuari. Per tant, pot ser d'interés modificar aquest directori segons l'interés. 
BASELINE_PREFIX="baseline_sistema"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
NEW_BASELINE="${BACKUP_DIR}/${BASELINE_PREFIX}_${TIMESTAMP}.txt"
TMP_BASELINE="/tmp/${BASELINE_PREFIX}_temp.txt"

# Funció: Mostra el manual d'ajuda
show_help() {
    cat << EOF
Ús: sudo ./fer_baseline.sh [OPCIÓ]

Aquest script crea i compara còpies de seguretat ("baselines") de la configuració del sistema i els paquets instal·lats.

Opcions:
  --help, -h         Mostra aquest missatge d'ajuda i surt.

  [sense opció]      Crea una nova baseline permanent a "$BACKUP_DIR". Aquesta baseline inclou la configuració
                     dels fitxers dins de /etc i la llista de paquets instal·lats.

  compara            Genera una baseline temporal i la compara amb l'última baseline permanent disponible
                     a "$BACKUP_DIR" sense guardar-la permanentment.

  compara_amb        Genera una baseline temporal i ofereix un llistat de baselines disponibles perquè
                     l'usuari seleccioni una. Es fa una comparació amb la baseline seleccionada.


Nota: Aquest script requereix privilegis de sudo per accedir a la configuració del sistema.
EOF
}

# Funció: Verifica si l'script s'executa com a root (només sudoers)
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        printf "Aquest script ha de ser executat amb privilegis de root o sudo.\n" >&2
        return 1
    fi
}

# Funció: Crea el directori de còpies de seguretat si no existeix
create_backup_dir() {
    mkdir -p "$BACKUP_DIR" || { printf "No s'ha pogut crear el directori de còpies de seguretat.\n" >&2; return 1; }
}

# Funció: Genera el fitxer baseline amb la configuració del sistema i els paquets instal·lats
generate_baseline() {
    local baseline_file=$1
    {
        printf "## Baseline del sistema: %s ##\n" "$TIMESTAMP"
        printf "\n### Paquets Instal·lats:\n"
        dpkg-query -l | awk '{print $2, $3}' | grep -E '^[a-zA-Z0-9]'
        printf "\n### Fitxers de Configuració:\n"
        find /etc -type f -exec sha256sum {} + 2>/dev/null
    } > "$baseline_file" || { printf "Error: No s'ha pogut generar el fitxer baseline.\n" >&2; return 1; }
}

# Funció: Troba l'últim fitxer baseline per a la comparació
get_latest_baseline() {
    local latest_baseline
    latest_baseline=$(ls -t "$BACKUP_DIR"/${BASELINE_PREFIX}_*.txt 2>/dev/null | head -n 1)
    if [[ -z $latest_baseline ]]; then
        printf "No s'ha trobat cap baseline anterior.\n" >&2
        return 1
    fi
    printf "%s" "$latest_baseline"
}

# Funció: Mostra un llistat numerat de baselines per a la selecció de l'usuari
list_baselines() {
    local baselines=($(ls -t "$BACKUP_DIR"/${BASELINE_PREFIX}_*.txt 2>/dev/null))
    if [[ ${#baselines[@]} -eq 0 ]]; then
        printf "No hi ha baselines disponibles.\n" >&2
        return 1
    fi
    printf "Llista de baselines disponibles:\n"
    for i in "${!baselines[@]}"; do
        printf "%d) %s\n" $((i+1)) "${baselines[i]}"
    done
    read -p "Selecciona el nombre corresponent al baseline: " selection
    if [[ $selection -lt 1 || $selection -gt ${#baselines[@]} ]]; then
        printf "Selecció invàlida.\n" >&2
        return 1
    fi
    printf "%s" "${baselines[$((selection-1))]}"
}

# Funció: Compara el baseline actual (temporal) amb un baseline especificat
compare_baselines() {
    local temp_baseline=$1
    local old_baseline=$2
    printf "\n## Comparació amb el baseline seleccionat:\n"
    diff -u "$old_baseline" "$temp_baseline" || printf "No s'han trobat diferències.\n"
}

# Execució principal segons l'argument proporcionat
main() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        exit 0
    fi

    check_sudo || exit 1
    create_backup_dir || exit 1

    case "$1" in
        "")  # Genera una nova baseline si no hi ha cap argument i la guarda permanentment
            printf "Generant una nova baseline...\n"
            generate_baseline "$NEW_BASELINE" || exit 1
            printf "Baseline creada a %s\n" "$NEW_BASELINE"
            ;;
        "compara")  # Compara la baseline temporal amb la més recent sense guardar-la permanentment
            printf "Generant una baseline temporal per a la comparació...\n"
            generate_baseline "$TMP_BASELINE" || exit 1
            local latest_baseline
            latest_baseline=$(get_latest_baseline) || exit 1
            compare_baselines "$TMP_BASELINE" "$latest_baseline"
            rm -f "$TMP_BASELINE"
            ;;
        "compara_amb")  # Permet a l'usuari seleccionar un baseline específic per a la comparació amb la temporal
            printf "Generant una baseline temporal per a la comparació...\n"
            generate_baseline "$TMP_BASELINE" || exit 1
            local selected_baseline
            selected_baseline=$(list_baselines) || exit 1
            compare_baselines "$TMP_BASELINE" "$selected_baseline"
            rm -f "$TMP_BASELINE"
            ;;
        *)
            printf "Opció no reconeguda: %s\n" "$1" >&2
            printf "Prova '%s --help' per obtenir més informació.\n" "$(basename "$0")" >&2
            exit 1
            ;;
    esac
}

main "$@"


