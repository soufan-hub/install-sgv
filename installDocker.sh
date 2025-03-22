#!/bin/bash
set -euo pipefail

REQUIRED_DOCKER_VERSION="24.0.2"

function error {
  echo -e "\\e[91m$1\\e[39m"
  exit 1
}

function check_internet {
  printf "Checking if you are online... "
  if wget -q --spider http://github.com; then
    echo "Online. Continuing."
  else
    error "Offline. Go connect to the internet then run the script again."
  fi
}

function install_dependencies {
  echo "Updating package lists..."
  sudo apt update || error "Failed to update package lists."

  echo "Installing required packages: curl and docker-compose..."
  sudo apt install -y curl docker-compose || error "Failed to install dependencies."
}

function is_docker_installed {
  if command -v docker &>/dev/null; then
    return 0
  else
    return 1
  fi
}

function check_docker_version {
  local current_version
  current_version=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  if [[ "$current_version" == "$REQUIRED_DOCKER_VERSION" ]]; then
    return 0
  else
    return 1
  fi
}

function install_docker {
  echo "Installing Docker..."
  curl -sSL https://get.docker.com | sh || error "Failed to install Docker."
  sudo usermod -aG docker "$USER" || error "Failed to add user to docker group."
  # Reinitialize group membership for the current session
  newgrp docker || true
}

function main {
  install_dependencies
  check_internet

  if is_docker_installed; then
    echo "Docker is already installed."
    if check_docker_version; then
      echo "Docker version is up-to-date ($REQUIRED_DOCKER_VERSION)."
    else
      echo "Docker version is not $REQUIRED_DOCKER_VERSION. Upgrading..."
      install_docker
    fi
  else
    install_docker
  fi

  echo "Final Docker version:"
  docker --version
}

main