#!/bin/bash
set -euo pipefail

# If SKIP_DOWNLOAD is not set, you could run the full procedure.
if [ "${SKIP_DOWNLOAD:-0}" != "1" ]; then
  echo "Running full installDocker.sh procedure (download/extraction steps)..."
  # (Insert full procedure if needed)
  # For our use case, we assume SKIP_DOWNLOAD will always be set from install.sh.
else
  echo "SKIP_DOWNLOAD detected: Skipping download/extraction steps in installDocker.sh."
fi

echo "Proceeding with Docker installation steps..."

REQUIRED_DOCKER_VERSION="28.0.2"
DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
UBUNTU_CODENAME=$(lsb_release -cs)

echo "Updating package lists..."
sudo apt-get update -qq

echo "Installing required packages: ca-certificates, curl, gnupg, and lsb-release..."
sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release

echo "Configuring Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings

if [ -f /etc/apt/keyrings/docker.gpg ]; then
    echo "Removing existing /etc/apt/keyrings/docker.gpg..."
    sudo rm -f /etc/apt/keyrings/docker.gpg
fi

echo "Downloading and configuring the Docker GPG key..."
curl -fsSL "${DOCKER_REPO_URL}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "Adding Docker repository to APT sources..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] ${DOCKER_REPO_URL} ${UBUNTU_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package lists again..."
sudo apt-get update -qq

if command -v docker &>/dev/null; then
    current_version=$(docker --version | grep -oP '\d+\.\d+\.\d+')
    echo "Current Docker version: $current_version"
else
    current_version="none"
    echo "Docker is not installed."
fi

if [ "$current_version" != "$REQUIRED_DOCKER_VERSION" ]; then
    echo "Installing Docker version $REQUIRED_DOCKER_VERSION..."
    if [ "$current_version" != "none" ]; then
        echo "Removing current version ($current_version)..."
        sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || echo "Warning: failed to remove existing Docker; continuing..."
    fi

    TARGET_VERSION=$(apt-cache madison docker-ce | grep "$REQUIRED_DOCKER_VERSION" | head -n1 | awk '{print $3}' || true)
    if [ -z "$TARGET_VERSION" ]; then
        echo -e "\033[93mWARNING: Required Docker version $REQUIRED_DOCKER_VERSION not found in repository.\033[0m"
        echo "Available versions:"
        apt-cache madison docker-ce
        echo "Installing latest available version."
        TARGET_VERSION=$(apt-cache madison docker-ce | head -n1 | awk '{print $3}')
    fi
    echo "Installing Docker version: $TARGET_VERSION"
    sudo apt-get install -y docker-ce="$TARGET_VERSION" docker-ce-cli="$TARGET_VERSION" containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin || { echo "Failed to install Docker version $TARGET_VERSION."; exit 1; }
else
    echo "Docker is already at the required version ($REQUIRED_DOCKER_VERSION)."
fi

if ! systemctl is-active --quiet docker; then
    echo "Docker daemon is not active. Starting Docker..."
    sudo systemctl start docker || { echo "Failed to start the Docker daemon."; exit 1; }
    sleep 5
    if ! systemctl is-active --quiet docker; then
        echo -e "\033[91mERROR: Docker daemon failed to start. Check status with 'systemctl status docker'.\033[0m"
        exit 1
    fi
fi

echo "Docker installation/update completed successfully. Final version:"
docker --version