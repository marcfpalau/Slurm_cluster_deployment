#!/bin/bash

# Definir la direcci  n IP o nombre de host de la m  quina de destino
remote_host="161.116.80.25"

# Definir el directorio de destino del backup en la m  quina de destino
remote_dir="/volume2/backups2/superfe/homes_inc/"
 
#Todays date in ISO-8601 format:
DAY0=`date -I`
#DAY0=$(date '+%Y-%m-%d' | sed 's/-0\([0-9]\)-/-\1-/')

 
#Yesterdays date in ISO-8601 format:
DAY1=`date -I -d "1 day ago"`
 
#The source directory:
SRC="/home"
 
#The target directory:
TRG="/mnt/backups/home_inc/$DAY0"
 
#The link destination directory:
#LNK="/root/backups/users_obelix/$DAY1"
LNK="/mnt/backups/homes/latest"
 
#The rsync options:
OPT="-avh --delete --link-dest=$LNK"
 
mount -t nfs "$remote_host:$remote_dir" /mnt/backups/home_inc
#Execute the backup
wget -qO- HTTP/1.0 161.116.80.25 &> /dev/null
if [ $? -eq 0 ]; then
	rsync $OPT $SRC $TRG
else
	exit 1
fi

#8 days ago in ISO-8601 format
DAY8=`date -I -d "8 days ago"`
 
#Delete the backup from 8 days ago, if it exists
if [ -d /mnt/backups/homes_inc/$DAY8 ]
then
	rm -rf /mnt/backups/homes_inc/$DAY8 
fi

