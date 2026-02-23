#!/usr/bin/env bash

sudo sed -i.bak '/\bswap\b/ s/^/#/' /etc/fstab
sudo swapoff -a
sudo kubeadm reset -f --v=1 --cri-socket /var/run/cri-dockerd.sock
sudo systemctl stop kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet docker