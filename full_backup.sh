#!/bin/bash

# Definir la dirección IP o nombre de host de la máquina de destino
remote_host="161.116.80.25"

date_f=$(date '+%Y-%m-%d' | sed 's/-0\([0-9]\)-/-\1-/')

# Definir el directorio de destino del backup en la m  quina de destino
remote_dir="/volume2/backups2/superfe/fullsystem/"

# Montar la maquina de destino a traves de NFS
mount -t nfs "$remote_host:$remote_dir" /mnt/backups/full_system/

# Realizar el backup completo del sistema
if [ $? -eq 0 ]; then
	rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/home/*"} / /mnt/backups/full_system/$date_f
fi
# Paro de ejecucion 2 segundos
sleep 2

#link as the latest available backup
ln -nsf /mnt/backups/full_system/$date_f /mnt/backups/full_system/latest

# Desmontar la maquina de destino
umount /mnt/backups
