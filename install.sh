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

# Cleanup on exit
trap "rm -rf $TMP_DIR" EXIT

info "🌀 Criando diretório temporário em $TMP_DIR..."
mkdir -p "$TMP_DIR"

info "📥 Baixando última release de $REPO..."
ZIP_URL=$(curl -s https://api.github.com/repos/${REPO}/releases/latest \
  | grep "zipball_url" \
  | cut -d '"' -f 4)

[ -z "$ZIP_URL" ] && error "Não foi possível encontrar a última release."

curl -L "$ZIP_URL" -o "$ZIP_FILE" || error "Falha ao baixar o zip da release."

info "📦 Extraindo arquivos..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

# Encontrar o diretório extraído (ele tem nome com hash)
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "*install-sgv*" | head -n 1)

[ -z "$EXTRACTED_DIR" ] && error "Falha ao encontrar o diretório extraído."

cd "$EXTRACTED_DIR"

# Executar os scripts
info "🐳 Instalando Docker..."
chmod +x installDocker.sh
./installDocker.sh || error "Falha ao executar installDocker.sh"

info "🚀 Instalando SGV..."
chmod +x installSgv.sh
./installSgv.sh || error "Falha ao executar installSgv.sh"

info "✅ Instalação finalizada com sucesso!"