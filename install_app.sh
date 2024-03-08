#!/bin/bash

# Create a partition in disk /dev/sdb with 5G
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 5G

# Create a LVM physical volume
sudo pvcreate /dev/sdb1

# Create a LVM volume group called app
sudo vgcreate app /dev/sdb1

# Create a LVM logical volume with a 5G size
sudo lvcreate -L 5G -n app app

# Format the logical volume with ext4 filesystem
sudo mkfs.ext4 /dev/app/app

# Mount the logical volume to /app
sudo mkdir /app
sudo mount /dev/app/app /app

# Add the entry to /etc/fstab for automatic mounting on boot
echo "/dev/app/app /app ext4 defaults 0 0" | sudo tee -a /etc/fstab

# Download the file to /app
wget -P /app http://192.168.239.254/zabbix_agent-6.0.3-linux-4.12-ppc64le-static.tar.gz

# Decompress all tar.gz files in /app
sudo find /app -name "*.tar.gz" -exec tar -xzvf {} -C /app \;

