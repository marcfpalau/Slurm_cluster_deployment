################################################################################
# Version v1.2
#
# Script for build, installation and configuration of
# SLURM 20.11.9 for Rocky Linux 8.6
################################################################################

# prepare to build and install SLURM
sudo yum install python3 gcc openssl openssl-devel pam-devel numactl numactl-devel hwloc lua readline-devel ncurses-devel man2html libibmad libibumad rpm-build  perl-ExtUtils-MakeMaker.noarch -y

sudo yum install rpm-build make wget -y
sudo dnf --enablerepo=powertools install rrdtool-devel lua-devel hwloc-devel rpm-build -y
#sudo yum install cpanm*
sudo dnf install mariadb-server mariadb-devel -y
mkdir /usr/local/slurm-tmp
cd /usr/local/slurm-tmp
# https://download.schedmd.com/slurm/slurm-22.05.6.tar.bz2
wget https://download.schedmd.com/slurm/slurm-22.05.6.tar.bz2

#Compile slurm with rpmbuild (This can take a few minutes)
echo "Compiling SLURM, this can take a few minutes..."
sleep 2
rpmbuild -ta slurm-22.05.6.tar.bz2

cd /root/rpmbuild/RPMS/x86_64
ls
sleep 10
yum --nogpgcheck localinstall slurm-22.05.6-1.el8.x86_64.rpm slurm-perlapi-22.05.6-1.el8.x86_64.rpm slurm-slurmctld-22.05.6-1.el8.x86_64.rpm 


# create the SLURM default configuration with
# compute nodes called "NodeName=linux[1-32]"
# in a cluster called "cluster"
# and a partition name called "test"
# Feel free to adapt to your needs

cat << EOF | sudo tee /etc/slurm/slurm.conf
# slurm.conf file generated by configurator easy.html.
# Put this file on all nodes of your cluster.
# See the slurm.conf man page for more information.
#
ClusterName=superfe
SlurmctldHost=superfe
#
#MailProg=/bin/mail
MpiDefault=none
#MpiParams=ports=#-#
ProctrackType=proctrack/cgroup
ReturnToService=1
SlurmctldPidFile=/var/run/slurmctld.pid
#SlurmctldPort=6817
SlurmdPidFile=/var/run/slurmd.pid
#SlurmdPort=6818
SlurmdSpoolDir=/var/spool/slurm
SlurmUser=slurm
#SlurmdUser=root
StateSaveLocation=/var/spool/slurm
SwitchType=switch/none
TaskPlugin=task/affinity
#
#
# TIMERS
#KillWait=30
#MinJobAge=300
#SlurmctldTimeout=120
#SlurmdTimeout=300
#
#
# SCHEDULING
SchedulerType=sched/backfill
SelectType=select/cons_tres
#
#
# LOGGING AND ACCOUNTING
AccountingStorageType=accounting_storage/none
#JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/none
#SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurmctld.log
#SlurmdDebug=info
SlurmdLogFile=/var/log/slurmd.log
#
#
# COMPUTE NODES
NodeName=slurm[01-32] CPUs=1 State=UNKNOWN
PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP
EOF

cat  << EOF | sudo tee /etc/slurm/cgroup.conf
###
#
# Slurm cgroup support configuration file
#
# See man slurm.conf and man cgroup.conf for further
# information on cgroup configuration parameters
#--
CgroupAutomount=yes

ConstrainCores=no
ConstrainRAMSpace=no

EOF


# on master/controller node
cat <<EOF  | sudo tee /etc/systemd/system/slurmctld.service
[Unit]
Description=Slurm controller daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmctld
ExecStart=/usr/sbin/slurmctld $SLURMCTLD_OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/slurmctld.pid

[Install]
WantedBy=multi-user.target
EOF

#Make sure all the master node have the configuration files
mkdir /var/spool/slurm
chown slurm: /var/spool/slurm/
chmod 755 /var/spool/slurm/
touch /var/log/slurmctld.log
chown slurm: /var/log/slurmctld.log
mkdir /var/log/slurm
chown slurm: /var/log/slurm
touch /var/log/slurm_jobacct.log /var/log/slurm/slurm_jobcomp.log
chown slurm: /var/log/slurm_jobacct.log /var/log/slurm/slurm_jobcomp.log

#Open the ports that slurm uses
firewall-cmd --permanent --zone=internal --add-port=6817/udp
firewall-cmd --permanent --zone=internal --add-port=6817/tcp
firewall-cmd --permanent --zone=internal --add-port=6818/udp
firewall-cmd --permanent --zone=internal --add-port=6818/tcp
firewall-cmd --permanent --zone=internal --add-port=6819/udp
firewall-cmd --permanent --zone=internal --add-port=6819/tcp
firewall-cmd --reload


#####Missing things

#Enable slurm on start + start the service
#systemctl enable slurmctld.service
#systemctl start slurmctld.service
#systemctl status slurmctld.service
