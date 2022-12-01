################################################################################
# Version v1.2
#
# Script for build, installation and configuration of
# Slurm for Rocky Linux 8.6
################################################################################

# prepare to build and install SLURM
sudo yum install python3 gcc openssl openssl-devel pam-devel numactl numactl-devel hwloc lua readline-devel ncurses-devel man2html libibmad libibumad rpm-build  perl-ExtUtils-MakeMaker.noarch -y

sudo yum install rpm-build make wget -y
sudo dnf --enablerepo=powertools install rrdtool-devel lua-devel hwloc-devel rpm-build -y
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
yum --nogpgcheck localinstall slurm-22.05.6-1.el8.x86_64.rpm slurm-perlapi-22.05.6-1.el8.x86_64.rpm slurm-slurmd-22.05.6-1.el8.x86_64.rpm

mkdir /etc/slurm
#Copy the config file from master node
scp root@192.168.6.10:/etc/slurm/slurm.conf /etc/slurm/
scp root@192.168.6.10:/etc/slurm/cgroup.conf /etc/slurm/

#Make sure all the nodes have the configuration files
mkdir /var/spool/slurm
chown slurm: /var/spool/slurm
chmod 755 /var/spool/slurm
mkdir /var/log/slurm
touch /var/log/slurm/slurmd.log
chown slurm: /var/log/slurm/slurmd.log

# on compute nodes
cat  <<EOF  | sudo tee /etc/systemd/system/slurmd.service
[Unit]
Description=Slurm node daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmd
ExecStart=/usr/sbin/slurmd -d /usr/sbin/slurmstepd $SLURMD_OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/slurmd.pid
KillMode=process
LimitNOFILE=51200
LimitMEMLOCK=infinity
LimitSTACK=infinity

[Install]
WantedBy=multi-user.target
EOF


#Test to see if the configuration is ok
slurmd -C

#Disable firewall on compute nodes
systemctl stop firewalld
systemctl disable firewalld

#Enable slurm on start + start the service
systemctl enable slurmd.service
systemctl start slurmd.service
systemctl status slurmd.service
