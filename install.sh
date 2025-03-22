#!/bin/bash

set -euo pipefail

REPO="soufan-hub/install-sgv"
TMP_DIR="/tmp/install-sgv"
ZIP_FILE="$TMP_DIR/latest.zip"

function error {
  echo -e "\033[91mERROR: $1\033[0m"
  exit 1
}

function info {
  echo -e "\033[96m$1\033[0m"
}

# Limpar diretório temporário na saída
trap "rm -rf $TMP_DIR" EXIT

info "🌀 Criando diretório temporário em $TMP_DIR..."
mkdir -p "$TMP_DIR"

info "📥 Baixando última release de $REPO..."
ZIP_URL=$(curl -s https://api.github.com/repos/${REPO}/releases/latest \
  | grep "zipball_url" \
  | cut -d '"' -f 4)

[ -z "$ZIP_URL" ] && error "Não foi possível encontrar a última release."

curl -L "$ZIP_URL" -o "$ZIP_FILE" || error "Falha ao baixar o zip da release."

# Verificar se o unzip está instalado, caso contrário, instalá-lo
if ! command -v unzip &>/dev/null; then
  info "📦 unzip não encontrado. Instalando..."
  sudo apt update && sudo apt install unzip -y || error "Falha ao instalar unzip."
fi

info "📦 Extraindo arquivos..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

# Encontrar o diretório extraído (nome com hash)
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "*install-sgv*" | head -n 1)
[ -z "$EXTRACTED_DIR" ] && error "Falha ao encontrar o diretório extraído."

info "📂 Listando conteúdo do diretório extraído:"
ls -la "$EXTRACTED_DIR"

cd "$EXTRACTED_DIR"

# Procurar recursivamente pelos scripts
DOCKER_SCRIPT=$(find . -type f -name "installDocker.sh" | head -n 1)
SGV_SCRIPT=$(find . -type f -name "installSgv.sh" | head -n 1)

[ -z "$DOCKER_SCRIPT" ] && error "Arquivo installDocker.sh não encontrado na release."
[ -z "$SGV_SCRIPT" ] && error "Arquivo installSgv.sh não encontrado na release."

info "🐳 Instalando Docker..."
chmod +x "$DOCKER_SCRIPT"
"$DOCKER_SCRIPT" || error "Falha ao executar installDocker.sh"

info "🚀 Instalando SGV..."
chmod +x "$SGV_SCRIPT"
"$SGV_SCRIPT" || error "Falha ao executar installSgv.sh"

info "✅ Instalação finalizada com sucesso!"