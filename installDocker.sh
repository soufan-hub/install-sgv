#!/bin/bash
set -euo pipefail
trap 'echo -e "\033[91mERROR: Command \"$BASH_COMMAND\" failed at line $LINENO with exit code $?." >&2; exit 1' ERR

REQUIRED_DOCKER_VERSION="28.0.2"
DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
UBUNTU_CODENAME=$(lsb_release -cs)

echo "Atualizando listas de pacotes..."
sudo apt-get update -qq || { echo "Falha ao atualizar as listas de pacotes."; exit 1; }

echo "Instalando pacotes necessários: ca-certificates, curl, gnupg e lsb-release..."
sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release || { echo "Falha ao instalar os pacotes necessários."; exit 1; }

echo "Configurando repositório do Docker..."
sudo install -m 0755 -d /etc/apt/keyrings || { echo "Falha ao criar o diretório /etc/apt/keyrings."; exit 1; }

# Remove a chave antiga, se existir, para evitar prompt interativo
if [ -f /etc/apt/keyrings/docker.gpg ]; then
    echo "Removendo /etc/apt/keyrings/docker.gpg existente..."
    sudo rm -f /etc/apt/keyrings/docker.gpg || { echo "Falha ao remover /etc/apt/keyrings/docker.gpg."; exit 1; }
fi

echo "Baixando e configurando a chave GPG do Docker..."
curl -fsSL "${DOCKER_REPO_URL}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || { echo "Falha ao baixar ou converter a chave GPG do Docker."; exit 1; }

echo "Adicionando o repositório do Docker às fontes APT..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] ${DOCKER_REPO_URL} ${UBUNTU_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Falha ao adicionar o repositório do Docker."; exit 1; }

echo "Atualizando listas de pacotes novamente..."
sudo apt-get update -qq || { echo "Falha ao atualizar as listas de pacotes após adicionar o repositório do Docker."; exit 1; }

# Verifica se o Docker já está instalado e captura a versão atual
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
        echo "Removendo a versão atual ($current_version)..."
        sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || echo "Aviso: Falha ao remover a versão atual; continuando..."
    fi

    # Procura a versão completa do pacote no repositório
    TARGET_VERSION=$(apt-cache madison docker-ce | grep "$REQUIRED_DOCKER_VERSION" | head -n1 | awk '{print $3}') || true
    if [ -z "$TARGET_VERSION" ]; then
        echo "ERROR: Versão requerida $REQUIRED_DOCKER_VERSION não encontrada no repositório."
        echo "Versões disponíveis:"
        apt-cache madison docker-ce
        exit 1
    fi
    echo "Versão alvo encontrada: $TARGET_VERSION"
    sudo apt-get install -y docker-ce="$TARGET_VERSION" docker-ce-cli="$TARGET_VERSION" containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin || { echo "Falha ao instalar o Docker na versão $TARGET_VERSION."; exit 1; }
else
    echo "Docker já está na versão requerida ($REQUIRED_DOCKER_VERSION)."
fi

# Garante que o daemon do Docker esteja ativo
if ! systemctl is-active --quiet docker; then
    echo "Daemon do Docker não está ativo. Iniciando o Docker..."
    sudo systemctl start docker || { echo "Falha ao iniciar o daemon do Docker."; exit 1; }
    sleep 5
    if ! systemctl is-active --quiet docker; then
        echo "ERROR: Docker daemon não conseguiu iniciar. Verifique o status com 'systemctl status docker'."
        exit 1
    fi
fi

echo "Instalação/atualização do Docker concluída com sucesso. Versão final:"
docker --version