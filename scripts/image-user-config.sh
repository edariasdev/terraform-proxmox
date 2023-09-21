#!/bin/bash

# This script configures a user.
# Script used by the get-image.sh script to inject for --run-command and --upload subcommands for virt-builder
# replace 'ed' with your desired username

USR=$1

# Set the default user to 'ed'
# sed -i 's/USER=/USER=ed/' /etc/default/useradd
useradd -m  -p "" -s /bin/bash ${USR}

# Create a password for 'ed'
echo "${USR}:password123" | passwd

# Add 'ed' to the sudoers file
echo "${USR} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

useradd -m  -p "" -s /usr/sbin/nologin docker
useradd -m  -p "" -s /usr/sbin/nologin k8s

usermod -aG docker ${USR}
usermod -aG k8s ${USR}

# Fix resolver to lab.net 
echo -e "[Resolve]\nDNS=192.168.14.1" > /etc/systemd/resolved.conf
systemctl restart systemd-resolved

# Add Neofetch for bashrc
[[ -f /home/${USR}/.bashrc ]] && grep -q '/usr/bin/neofetch' /home/${USR}/.bashrc || echo '/usr/bin/neofetch' >> /home/${USR}/.bashrc



