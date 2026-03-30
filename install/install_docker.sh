#!/bin/bash
set -e

info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

if [[ $EUID -ne 0 ]]; then
   error "Run this script as root using sudo."
   exit 1
fi

CURRENT_USER=$(logname)

info "Removing Podman..."
apt-get remove --purge -y podman podman-docker
apt-get autoremove -y
rm -rf /etc/containers /var/lib/containers /var/lib/cni /var/lib/overlay

info "Updating system..."
apt-get update
apt-get upgrade -y

info "Installing prerequisites for Docker..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

info "Adding Docker GPG key..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

info "Adding Docker repository..."
ARCH=$(dpkg --print-architecture)
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

info "Installing Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

info "Creating docker group if it doesn't exist..."
if ! getent group docker > /dev/null 2>&1; then
    groupadd docker
    info "Group 'docker' created."
else
    info "Group 'docker' already exists."
fi

info "Adding user '$CURRENT_USER' to docker group..."
usermod -aG docker "$CURRENT_USER"

info "Enabling Docker service..."
systemctl enable docker
systemctl start docker

info "Installing latest standalone Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

info "Verifying installation..."
docker --version
docker compose version

info "Done! Log out and back in (or run 'newgrp docker') to use Docker without sudo."
