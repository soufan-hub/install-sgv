#!/bin/bash
set -euo pipefail

REPO="soufan-hub/install-sgv"
WORKDIR="install-sgv"
ZIPFILE="latest.zip"

# Verifica se o curl está instalado
if ! command -v curl &>/dev/null; then
  echo "⚠️  curl não encontrado. Instalando..."
  sudo apt update && sudo apt install -y curl || {
    echo "❌ Falha ao instalar curl"
    exit 1
  }
fi

echo "🌀 Criando diretório $WORKDIR..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "📥 Baixando última release de $REPO..."
ZIP_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep zipball_url | cut -d '"' -f 4)
curl -L "$ZIP_URL" -o "$ZIPFILE"

echo "📦 Extraindo arquivos..."
unzip -o "$ZIPFILE" >/dev/null

EXTRACTED_DIR=$(find . -type d -name "*install-sgv*" | head -n 1)
cd "$EXTRACTED_DIR"

echo "🐳 Instalando Docker..."
chmod +x installDocker.sh
sudo ./installDocker.sh

echo "🚀 Instalando SGV..."
chmod +x installsgv.sh
sudo ./installsgv.sh

echo "✅ Instalação finalizada com sucesso!"