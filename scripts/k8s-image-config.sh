#!/bin/bash

# This script configures k8s via 'virt-customize' command.
# Script used by the get-image.sh script to inject for --run-command and --upload subcommands for virt-builder
# replace 'ed' with your desired username

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
apt-mark hold kubelet kubeadm kubectl docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable qemu-guest-agent
echo "overlay" >> /etc/modules-load.d/containerd.conf
echo "br_netfilter" >> /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter
echo -e "[Resolve]\nDNS=192.168.14.1" > /etc/systemd/resolved.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sysctl --system
systemctl restart systemd-resolved
systemctl restart systemd-networkd