#!/bin/bash
# Descripción: Script automatizado para [b]vagos[/b] y principiantes que crear una imagen de la tarjeta microSD de la Raspberry
# en una unidad externa USB o carpeta compartida en red montada en el directorio "/media" o "/mnt", otras rutas son rechazadas por "image-backup"
# Modo de uso: Crea un archivo de texto, en este ejemplos es archivo es PiBackupSD.sh y en su interior pega el contenido de este script.
# Edita las variables IMGFILE y EXCLUDELIST, guarda el archivo y ejecuta "chmod +x PiBackupSD.sh" para permitir ejecutarlo

# NOTA: Este script detecta y descarga los binarios y dependencias de forma automatica de ser necesario, en el caso de que no este GIT instalado
# solicitara permiso aadministrativo para istalarlo mediante APT

# Con los pasos anteriores puedes ejecutarlo manualmente con el comando sudo ./PiBackupSD.sh o sudo /ruta/PiBackupSh.sh y agregarlo a cron para programar
# copias automaticas diarias, semanales o mensuales. Tienes una guia muy bien detallada en este enlace:
# https://www.hostgator.mx/blog/cron-job-guia-automatizar-tareas/ 




IMGFILE="/media/lanDisk/backups/backup-pi4b-$(date +%Y-%m-%d).img"

EXCLUDELIST="/media/*
/mnt/*
*/tmp/*
*/temp/*
/home/$USER/Descargas/*
/home/$USER/Downloads/*
/home/$USER/Videos/*
/home/$USER/AOSP13/
/home/$USER/gentoo/
*/wor-flasher/
*/wor-flasher-files/
/usr/share/hassio/media/*
/usr/share/hassio/mounts/*"


cd ~/
cat <<EOF > exclude.txt
${EXCLUDELIST}
EOF

if test -f "~/image-utils/image-backup"; then
    echo "Archivo binario localizado!"
    echo "iniciando copia de sefguridad..."
    sleep 3
else
    echo "Faltan los archivos binarios!"
    echo "precediendo con la descarga"
    sleep 1
    echo "Comprobando dependencias: git"
    if test -f "/bin/git"; then
        echo "GIT esta disponible!"
    else
        echo "No se a encontrado GIT en el sistema!"
        echo "instalando GIT utilizando APT"
        sleep 3
        sudo apt update && sudo apt install git
        echo "Dependencias instaladas!"
    fi

    sleep 3
    echo "clonando el repositorio image-utils..."   
    git clone https://github.com/seamusdemora/RonR-RPi-image-utils.git ~/image-utils
    chmod +x ~/image-utils/image-*
    echo "Los binarios se han descargado y instalados..."
fi

sleep 3
echo "creando copia de seguridad: ${IMGFILE}"
sudo ~/image-utils/image-backup --options -l,--progress,--exclude-from=./exclude.txt -i "${IMGFILE}"
echo "Copia de seguridad completada!"
ls -ls ${IMGFILE}

echo "Iniciando el proceso de compresion de la imagen de disco creada..." && sleep 3
xz -v "${IMGFILE}" && echo "Tarea finalizada, backup:${IMGFILE}.xz"
ls -ls ${IMGFILE}
