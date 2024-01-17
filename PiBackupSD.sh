#!/bin/bash
# Descripción: Script automatizado para [b]vagos[/b] y principiantes que creara una imagen de la tarjeta microSD de la Raspberry
# en una unidad externa USB o carpeta compartida en red montada en el directorio "/media" o "/mnt", rutas fuera de estas carpetas son rechazadas por "image-backup"

# Modo de uso: Crea un archivo de texto, en este ejemplos es archivo es PiBackupSD.sh y en su interior pega el contenido de este script.
# Edita las variables OUTPUT_PATH y EXCLUDE_LIST, guarda el archivo y ejecuta "chmod +x PiBackupSD.sh" para permitir ejecutarlo

# NOTA: Este script detecta y descarga los binarios y dependencias de forma automatica de ser necesario, en el caso de que no este GIT instalado
# solicitara permiso aadministrativo para istalarlo mediante APT

# Con los pasos anteriores puedes ejecutarlo manualmente con el comando sudo ./PiBackupSD.sh o sudo /ruta/PiBackupSh.sh y agregarlo a cron para programar
# copias automaticas diarias, semanales o mensuales. Tienes una guia muy bien detallada en este enlace:
# https://www.hostgator.mx/blog/cron-job-guia-automatizar-tareas/ 



CURRENT_USER=$USER								# Por defecto, el usuario logueado
OUTPUT_PATH="/media/lanDisk/backups/"						# La ruta debe estar dentro de la carpeta /media o /mnt
OUTPUT_FILE="backup-${HOSTNAME}-${CURRENT_USER}-$(date +%Y-%m-%d).img"		# Ejemplo filename: backup-pi4b-tripunto-2024-14-01.img
OUTPUT_XZ="-1"									# Debes configurar 0 o 1 para las copias automaticas

EXCLUDE_LIST="/media/*
/mnt/*
*/tmp/*
*/temp/*
/home/*/.cache/*
/srv/remotemount/*
/srv/dev-disk-by-uuid-7dc4ab69-5be7-4d49-af2b-5c5ade1d935a/*
/usr/share/hassio/media/*
/usr/share/hassio/mounts/*"


if [ "${CURRENT_USER}"=="root" && "${OUTPUT_XZ}" -lt "0" ]
then
    clear -x
    echo ""
    echo "Se recomienda NO ejecutar en modo administrador, cambia de usuario y vuelve a intentarlo!"
    echo ""
    echo "Para ejecutar en modo adminisstrador, al menos, \"OUTPUT_XZ\" debe estar configurado en 0 o 1"
    echo ""
    echo "¿Quieres que se compriman en formato XZ tus copias de seguridad?"
    echo ""
    select yn in "Yes" "No" "Cancel"; do
        case $yn in
            Yes ) OUTPUT_XZ=1; sudo sed -i 's/OUTPUT_XZ=-1/OUTPUT_XZ=1/g' sd-copy; break;;
	    No ) OUTPUT_XZ=0; sudo sed -i 's/OUTPUT_XZ=-1/OUTPUT_XZ=0/g' sd-copy; break;;
	    Cancel ) exit;;
        esac
    echo ""
    done
else
    if [ "$OUTPUT_XZ" -lt "0" ]; then
        clear -x
	echo "¿Quieres comprimir el backup al finalizar?"
	echo ""
	select yn in "Yes" "No" "Cancel"; do
	    case $yn in
                Yes ) OUTPUT_XZ=1; break;;
		No ) OUTPUT_XZ=0; break;;
            Cancel ) exit;;
            esac
        echo ""
        done
    fi
fi

if test -f "${OUTPUT_PATH}${OUTPUT_FILE}"; then
    if [ "${CUSTOM_USER}" == "root" ]; then
	rm ${OUTPUT_PATH}${OUTPUT_FILE}
    fi
    clear -x
    echo ""
    echo "¿Que debo hacer antes de continuar?"
    echo ""
    echo "Delete: Elimina la copia de seguridad anterior y comienza a crear el nuevo backup."
    echo "Rename: Renombra la copia de seguridad añadiendo la extension \".old\"."
    echo "Cancel: Cancela la creación de la copia de seguridad y sal del programa."
    echo ""
    select yn in "Delete" "Rename" "Cancel"; do
        case $yn in
            Delete ) sudo rm ${OUTPUT_PATH}${OUTPUT_FILE}; break;;
	    Rename ) sudo mv ${OUTPUT_PATH}${OUTPUT_FILE} ${OUTPUT_PATH}${OUTPUT_FILE}.old; break;;
	    Cancel ) exit;;
        esac
    echo ""
    done
fi

cd ${HOME}


if test -f "${HOME}/image-utils/image-backup"; then
    echo ""
    echo "Iniciando el proceso de la copia de seguridad!"
    echo ""
    sleep 1
else
    echo ""
    echo "No se encontraron los archivos binarios de image-utils."
    echo ""
    echo "¿Quieres descargarlos ahora?"
    echo ""
    select yn in "Yes" "No" "Cancel"; do
        case $yn in
            Yes ) break;;
	    No ) echo "Sin los binarios no puedo continuar... Saliendo en 3, 2, 1" && sleep 2 && exit;;
        esac
    done
    echo ""
    echo "Comprobando dependencias: git"
    if test -f "/bin/git"; then
        echo "GIT esta disponible!"
    else
        echo ""
        echo "GIT no esta instalado en tu sistema!"
	echo ""
        echo "Voy a instalar GIT lanzando APT"
	echo ""
        sleep 1
        sudo apt update && sudo apt install git
        echo ""
	echo "Instalación de GIT completada!"
	echo ""
    fi

    sleep 1
    echo ""
    echo "clonando el repositorio image-utils..."   
    git clone https://github.com/seamusdemora/RonR-RPi-image-utils.git /home/${CURRENT_USER}/image-utils
    echo "Creando ejecutables..."
    chmod +x ${HOME}/image-utils/image-*
    echo ""
    echo "Los binarios se han descargado y instalado!"
    echo ""
    sleep 1
fi

touch ${HOME}/image-utils/exclude.txt
cat <<EOF > ${HOME}/image-utils/exclude.txt
${EXCLUDE_LIST}
EOF

echo "Comenzando la copia de seguridad de la microSD en: ${OUTPUT_PATH}${OUTPUT_FILE}"
sleep 1
sudo ${HOME}/image-utils/image-backup --options -l,--progress,--exclude-from=${HOME}/image-utils/exclude.txt -i "${OUTPUT_PATH}${OUTPUT_FILE}"
echo "Copia de seguridad completada!"
ls -ls ${OUTPUT_PATH}${OUTPUT_FILE}
sleep 1
if "${OUTPUT_XZ}" == "1"; then
    echo "Iniciando el proceso de compresion de la imagen de disco creada..." && sleep 3
    time 'xz -v "${OUTPUT_PATH}${OUTPUT_FILE}" && echo "Tarea finalizada, backup:${OUTPUT_PATH}${OUTPUT_FILE}.xz"' -o "${OUTPUT_PATH}${OUTPUT_FILE}"_time.txt
    ls -ls ${OUTPUT_PATH}${OUTPUT_FILE}.xz
fi
