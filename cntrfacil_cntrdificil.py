import hashlib
import base64
from datetime import datetime, timedelta
import os
import json

# TODO: cal testejar
# TODO: cal crear interficie
# TODO: cal comprovar funcionament rotacio del hash
# RECOMANACIO: guardar en paper i boli el historial histori dels inputs ja que si es perd aquest arxiu o es modifica, no es recuperaran les contrasenyes.
# MILLORA: quan es modifiquen els inputs, enviar-los per correu a alguna direccio mail per conservar-los fora de l'equip local
# TODO: cal fer el manual


# Fitxers per guardar l'estat
ESTAT_HASH_FILE = "estat_hash.json"
INPUTS_FILE = "inputs_contrasenya.json"
HISTORIC_FILE = "inputs_historic.json"

def carregar_estat_hash():
    if not os.path.exists(ESTAT_HASH_FILE):
        with open(ESTAT_HASH_FILE, "w") as f:
            json.dump({"estat_hash": 0}, f)
        return 0
    else:
        with open(ESTAT_HASH_FILE, "r") as f:
            data = json.load(f)
        return data.get("estat_hash", 0)

def guardar_estat_hash(estat_hash):
    with open(ESTAT_HASH_FILE, "w") as f:
        json.dump({"estat_hash": estat_hash}, f)

def carregar_inputs():
    if not os.path.exists(INPUTS_FILE):
        return None
    with open(INPUTS_FILE, "r") as f:
        return json.load(f)

def guardar_inputs(n, paraulaEspecial, paraulaSalt):
    inputs = {
        "n": n,
        "paraulaEspecial": paraulaEspecial,
        "paraulaSalt": paraulaSalt,
        "datetime": datetime.now().isoformat()
    }
    # Guardar inputs actuals
    with open(INPUTS_FILE, "w") as f:
        json.dump(inputs, f)
    # Actualitzar l'històric
    guardar_historic(inputs)

def guardar_historic(inputs):
    if not os.path.exists(HISTORIC_FILE):
        historic = []
    else:
        with open(HISTORIC_FILE, "r") as f:
            historic = json.load(f)
    historic.append(inputs)
    with open(HISTORIC_FILE, "w") as f:
        json.dump(historic, f, indent=4)

def carregar_historic():
    if not os.path.exists(HISTORIC_FILE):
        return []
    with open(HISTORIC_FILE, "r") as f:
        return json.load(f)

def demanar_nous_inputs():
    print("Cal crear nous inputs per a la contrasenya.")
    n = int(input("Introdueix la longitud de la contrasenya (nombre enter): "))
    paraulaEspecial = input("Introdueix la paraula especial (sols minuscules): ").strip()
    paraulaSalt = input("Introdueix la paraula salt: ").strip()
    return n, paraulaEspecial, paraulaSalt

def actualitzar_inputs():
    inputs_anteriors = carregar_inputs()
    
    if not inputs_anteriors:
        # No hi ha inputs previs: obliguem a crear-ne de nous
        n, paraulaEspecial, paraulaSalt = demanar_nous_inputs()
        estat_hash = carregar_estat_hash()
        estat_hash = (estat_hash + 1) % 3  # Rotem el hash
        guardar_estat_hash(estat_hash)
        guardar_inputs(n, paraulaEspecial, paraulaSalt)
        return estat_hash, n, paraulaEspecial, paraulaSalt

    # Inputs existents: comprovem si han passat més de 3 mesos
    data_ultima_modificacio = datetime.fromisoformat(inputs_anteriors["datetime"])
    if datetime.now() - data_ultima_modificacio > timedelta(days=90):
        resposta = input("Han passat més de 3 mesos des de l'últim canvi. Vols actualitzar els inputs? (si/no): ").strip().lower()
        if resposta == "si":
            n, paraulaEspecial, paraulaSalt = demanar_nous_inputs()
            estat_hash = carregar_estat_hash()
            estat_hash = (estat_hash + 1) % 3  # Rotem el hash
            guardar_estat_hash(estat_hash)
            guardar_inputs(n, paraulaEspecial, paraulaSalt)
            return estat_hash, n, paraulaEspecial, paraulaSalt

    # Si no cal actualitzar, retornem els inputs existents
    return carregar_estat_hash(), inputs_anteriors["n"], inputs_anteriors["paraulaEspecial"], inputs_anteriors["paraulaSalt"]

def generar_protocontrasenya(contrasenya_base, estat_hash):
    hash_funcs = [
        hashlib.sha1,    # 1r pas: sha1
        hashlib.sha256,  # 2n pas: sha256
        hashlib.sha512   # 3r pas: sha512
    ]
    hash_func = hash_funcs[estat_hash % 3]
    h = hash_func(contrasenya_base.encode()).digest()
    return base64.b64encode(h).decode()

def generar_contrasenya(n, paraulaEspecial, paraulaSalt, protocontrasenya):
    mapping_caracters = {
       'a': '@', 'b': '#', 'c': '!', 'd': '$', 'e': '%', 'f': '^',
       'g': '&', 'h': '*', 'i': '+', 'j': '=', 'k': '?', 'l': '/',
       'm': '|', 'n': '~', 'o': ':', 'p': '-', 'q': '<', 'r': '>',
       's': '_', 't': '{', 'u': '}', 'v': '[', 'w': ']', 'x': '(',
       'y': ')', 'z': '.'
    }
    main_part = protocontrasenya[:n-5]
    primera_lletra = paraulaEspecial[0].lower() if paraulaEspecial else 'a'
    special_char = mapping_caracters.get(primera_lletra, '*')
    salt_3 = paraulaSalt[:3][::-1]
    half = (n - 5) // 2
    final_sequence = main_part[:half] + salt_3 + main_part[half:]
    final_password = [None] * n
    final_password[1] = special_char
    final_password[n-2] = special_char
    seq_index = 0
    for i in range(n):
        if i == 1 or i == (n-2):
            continue
        final_password[i] = final_sequence[seq_index]
        seq_index += 1
    return "".join(final_password)

# Exemple d'ús
if __name__ == "__main__":
    contrasenya_base = "contrasenyaBaseExemple"

    # Actualitzem estat i inputs
    estat_hash, n, paraulaEspecial, paraulaSalt = actualitzar_inputs()

    # Generem protocontrasenya i contrasenya
    protocontrasenya = generar_protocontrasenya(contrasenya_base, estat_hash)
    contrasenya_final = generar_contrasenya(n, paraulaEspecial, paraulaSalt, protocontrasenya)

    print("Contrasenya final:", contrasenya_final)

    # Mostrem l'històric
    historic = carregar_historic()
    print("Històric d'inputs utilitzats:")
    for entrada in historic:
        print(entrada)






  
