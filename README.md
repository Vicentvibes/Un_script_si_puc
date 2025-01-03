# Un_script_si_puc

## Descripció:

Donat el esforç formatiu que suposa la ciberseguretat, encete aquest repositori com un repte personal on progressar com a analista de ciberseguretat. Un compromís que en un futur em pot permetre comptar amb scripts escrits personalment que em poden facilitar la feina. Per altra banda, vull realitzar aquest repositori en el dialecte valencià per tal de no perdre el costum d'escriure en la llengua amb la qual pense, senc i m'identifique. Una llengua d'una minoria i que encara s'està minimitzant més. 

Els scripts estan organitzats en carpetes segons la seua funcionalitat.

Aquestos scripts es proven en un entorn de Kali Linux 2024.3.


## Historial:

21 d'octubre del 2024   "executar_sesio-sh".

Aquest script permet gestionar l'execució d'altres scripts al principi de la sessió (inici del sistema) o al final de la sessió (apagada o reinici del sistema) en un sistema Linux. Proporciona funcionalitats per afegir, esborrar i llistar els scripts configurats. A més, registra totes les accions en un fitxer de logs amb informació sobre l'usuari i el moment en què s'ha realitzat cada acció. També procura que els scripts a executar s'executen amb permisos d'administrador per tal d'evitar problemes.


25 d'octubre del 2024    "fer_baseline.sh"

Aquest script crea una còpia de seguretat ("baseline") de la configuració del sistema i dels paquets instal·lats, guardant-la en un fitxer al directori $HOME/backups/baseline. Permet també generar baselines temporals per comparar-les amb versions anteriors, identificant així qualsevol canvi al sistema. Inclou opcions per comparar automàticament amb l'última baseline o seleccionar-ne una d'específica. Requereix privilegis de sudo per accedir a fitxers del sistema.


2 de novembre del 2024    "connexio_vpn.sh",  4 dies després del "tsunami" que va arrasar l'Horta Sud.

En aquest cas creem un script que estableix una connexió VPN mitjançant VPNBook. L'script neteja arxius de connexions VPN anteriors, descarrega la configuració actualitzada de VPNBook i obté una IP nova, assegurant que no
coincidisca amb les últimes 10 IPs utilitzades. Cada connexió es registra en un fitxer de logs per fer seguiment de les IP utilitzades.


7 de decembre del 2024     "cuinar_contrasenya.py", visitant London.

L'objectiu es crear un programa amb interficie que, a partir de contrasenyes constants i simples, oferisca els usuaris contrasenyes complexes. El proces consisteix en introduir uns inputs (mida de la cntr final, paraula per decidir caracters especials i paraula per saltejar la cntr final), els quals condicionaran la nostra contrasenya final. La contrasenya base (la simple, la facil, la que els usuaris recorden i pot ser tan simple com "vicent email" o "vicent facebook"), s'introdueix, se li aplica una funcio hash, al hash resultant se li codifica en base64 i aquesta protocontrasenya en base64 se li aplica les condicions dels inputs. El resultat final es una cntrasenya aparentment sense sentit, amb caracters especials i saltejada que els usuaris poden copiar i pegar en els seus logins. Cada 3 mesos se li oferira als usuaris canviar la contrasenya renovant els inputs, quan es renoven els inputs el hash utilitzat rota (sha1, sha256 o sha512). 
