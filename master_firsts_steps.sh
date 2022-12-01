################################################################################
# Version v1.2
#
# Script for build, installation and configuration of
# Munge for Rocky Linux 8.6
################################################################################

# prepare system
sudo yum update -y
sleep 2
# sudo apt upgrade -y

#sync clocks across the cluster
yum install ntp -y
chkconfig ntpd on
ntpdate pool.ntp.org
systemctl start ntpd

#get the lattest EPEL repo
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y

#Create the users/groups for slurm and munge
export MUNGEUSER=1005
sudo groupadd -g $MUNGEUSER munge
sudo useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge
export SLURMUSER=1001
sudo groupadd -g $SLURMUSER slurm
sudo useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm

# munge install for autentication
sudo yum install munge munge-libs  -y  
sudo dnf --enablerepo=powertools install munge-devel -y
sudo yum install rng-tools -y
sudo rngd -r /dev/urandom
#test if munge is installed successfully
echo "Test munge installed succesfully:"
munge -n | unmunge | grep STATUS
sleep 2
sudo /usr/sbin/create-munge-key -r -f

#create a munge key (overwrited at some point for consistency)
sudo sh -c  "dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key"
sudo chown munge: /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key

sudo systemctl enable munge
sudo systemctl start munge

#Test if munge is working fine 
#munge -n
#munge -n | munge
#munge -n | ssh 192.168.6.11 unmunge
#remunge

