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

if ! command -v vim &>/dev/null; then
  info "📦 vim não encontrado. Instalando..."
  sudo apt update && sudo apt install vim -y || error "Falha ao instalar vim."
fi

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

cd "$EXTRACTED_DIR"

info "📂 Conteúdo do diretório extraído:"
ls -la

# Verificar existência dos scripts necessários
if [ ! -f installDocker.sh ]; then
  error "Arquivo installDocker.sh não encontrado no diretório extraído."
fi

if [ ! -f installSgv.sh ]; then
  error "Arquivo installSgv.sh não encontrado no diretório extraído."
fi

info "🐳 Instalando Docker..."
chmod +x installDocker.sh
./installDocker.sh || error "Falha ao executar installDocker.sh"

info "🚀 Instalando SGV..."
chmod +x installSgv.sh
./installSgv.sh || error "Falha ao executar installSgv.sh"

info "✅ Instalação finalizada com sucesso!"