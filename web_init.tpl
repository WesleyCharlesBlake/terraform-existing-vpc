#!/bin/bash -v

NODENAME=${hostname}

sudo hostname $NODENAME
sudo echo $NODENAME > /etc/hostname 

#remove salt-minion keys and minion_id
sudo service salt-minion stop
sudo rm /etc/salt/pki/minion/minion.pem
sudo rm /etc/salt/pki/minion/minion.pub
sudo cat /dev/null > /etc/salt/minion_id
sudo rm -r /var/cache/salt/*
sudo rm -r /srv/salt

# create fs if needed
sudo echo "creating fs"
sudo mkfs -t ext4 ${device_name}

# mount it
sudo mkdir ${mount_point}
sudo mkdir ${mount_point}/www
sudo mkdir ${mount_point}/envs
sudo echo "${device_name}       ${mount_point}   ext4    defaults,nofail  0 2" >> /etc/fstab
sudo echo "mounting"
sudo mount -a

sudo /etc/init.d/salt-minion start