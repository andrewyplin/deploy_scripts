#!/usr/bin/env bash
set -e

CRI_DOCKERD_VERSION="0.3.20"
# Install cri-dockerd
wget https://github.com/Mirantis/cri-dockerd/releases/download/v$CRI_DOCKERD_VERSION/cri-dockerd_${CRI_DOCKERD_VERSION}.3-0.ubuntu-jammy_amd64.deb
sudo dpkg -i cri-dockerd_${CRI_DOCKERD_VERSION}.3-0.ubuntu-jammy_amd64.deb
sudo systemctl start cri-docker.socket
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
rm cri-dockerd_${CRI_DOCKERD_VERSION}.3-0.ubuntu-jammy_amd64.deb

# Establish K8s repository
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

KUIBERNETES_VERSION="1.30.14-1.1"
sudo apt-get update
sudo apt-mark unhold kubelet kubeadm kubectl
sudo apt-get install --allow-downgrades -y kubelet=${KUIBERNETES_VERSION} kubeadm=${KUIBERNETES_VERSION} kubectl=${KUIBERNETES_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl
sudo iptables -F
sudo iptables -P FORWARD ACCEPT

sudo sed -i.bak '/\bswap\b/ s/^/#/' /etc/fstab
sudo swapoff -a
sudo kubeadm reset -f --v=1 --cri-socket /var/run/cri-dockerd.sock
sudo systemctl stop kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet docker

sudo kubeadm init \
  --ignore-preflight-errors Swap \
  --skip-phases preflight \
  --pod-network-cidr=172.31.0.0/16 \
  --cri-socket /var/run/cri-dockerd.sock

mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo chmod 600 $HOME/.kube/config
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
echo "Home: $HOME"
echo "PWD: $PWD"

##CNI plugin using calico https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/calico.yaml
kubectl apply -f ${PWD}/k8s_yaml/calico.yaml
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

## install kubectl top server https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml
kubectl apply -f ${PWD}/k8s_yaml/metrics-server.yaml

## Add node label
