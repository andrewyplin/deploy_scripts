#!/bin/bash

set -e

DOCKER_VERSION="26.1.2"
CONTAINERD_VERSION="1.6.32"

echo "Updating package index..."
sudo apt-get update -y

echo "Installing dependencies..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

echo "Updating package index again..."
sudo apt-get update -y

DOCKER_DEB_VERSION=$(apt-cache madison docker-ce | grep "$DOCKER_VERSION" | head -n1 | awk '{print $3}')

if [ -z "$DOCKER_DEB_VERSION" ]; then
  echo "Error: Docker version ${DOCKER_VERSION} not found in apt-cache."
  exit 1
fi

CONTAINERD_DEB_VERSION=$(apt-cache madison containerd.io | grep "$CONTAINERD_VERSION" | head -n1 | awk '{print $3}')

if [ -z "$CONTAINERD_DEB_VERSION" ]; then
  echo "Error: containerd.io version ${CONTAINERD_VERSION} not found in apt-cache."
  exit 1
fi

echo "Installing Docker version ${DOCKER_DEB_VERSION}, containerd.io version ${CONTAINERD_DEB_VERSION}..."
sudo apt-get install -y docker-ce=${DOCKER_DEB_VERSION} docker-ce-cli=${DOCKER_DEB_VERSION} containerd.io=${CONTAINERD_DEB_VERSION}

echo "Verifying Docker installation..."
docker --version

# Remove package key and source to avoid conflicts in future installations(kubespray)
#sudo rm /usr/share/keyrings/docker-archive-keyring.gpg
#sudo rm /etc/apt/sources.list.d/docker.list
echo "Docker ${DOCKER_VERSION} installed successfully!"
