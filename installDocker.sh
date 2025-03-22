#!/bin/bash
set -euo pipefail

REQUIRED_DOCKER_VERSION="24.0.2"
DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
UBUNTU_CODENAME=$(lsb_release -cs)  # ex: focal, bionic, etc.

echo "Atualizando listas de pacotes..."
sudo apt-get update -qq

echo "Instalando pacotes necessários: ca-certificates, curl, gnupg e lsb-release..."
sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release

echo "Configurando repositório do Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL "${DOCKER_REPO_URL}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] ${DOCKER_REPO_URL} ${UBUNTU_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Atualizando listas de pacotes novamente..."
sudo apt-get update -qq

# Verifica se o Docker já está instalado e qual a versão
if command -v docker &>/dev/null; then
    current_version=$(docker --version | grep -oP '\d+\.\d+\.\d+')
    echo "Versão atual do Docker: $current_version"
else
    current_version="none"
    echo "Docker não está instalado."
fi

if [ "$current_version" != "$REQUIRED_DOCKER_VERSION" ]; then
    echo "Instalando o Docker na versão $REQUIRED_DOCKER_VERSION..."
    if [ "$current_version" != "none" ]; then
      echo "Removendo versão atual ($current_version)..."
      sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || true
    fi

    # Obtém a string completa da versão a ser instalada a partir do repositório
    TARGET_VERSION=$(apt-cache madison docker-ce | grep "$REQUIRED_DOCKER_VERSION" | head -n1 | awk '{print $3}')
    if [ -z "$TARGET_VERSION" ]; then
        echo "Versão requerida $REQUIRED_DOCKER_VERSION não encontrada no repositório."
        exit 1
    fi
    echo "Versão alvo encontrada: $TARGET_VERSION"
    sudo apt-get install -y docker-ce="$TARGET_VERSION" docker-ce-cli="$TARGET_VERSION" containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin
else
    echo "Docker já está na versão requerida ($REQUIRED_DOCKER_VERSION)."
fi

# Garante que o daemon do Docker esteja ativo
if ! systemctl is-active --quiet docker; then
    echo "Daemon do Docker não está ativo. Iniciando o Docker..."
    sudo systemctl start docker
    sleep 5
    if ! systemctl is-active --quiet docker; then
        echo "Falha ao iniciar o daemon do Docker. Verifique o status do serviço."
        exit 1
    fi
fi

echo "Instalação/atualização do Docker concluída. Versão final:"
docker --version