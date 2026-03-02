#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

REPO="soufan-hub/install-sgv"
WORKDIR="install-sgv"
ZIPFILE="latest.zip"
GITHUB_API_URL="https://api.github.com/repos/$REPO/releases/latest"

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
  if ! command -v sudo &>/dev/null; then
    echo "❌ sudo não encontrado. Execute como root ou instale sudo."
    exit 1
  fi
fi

# Verifica dependências mínimas para download e extração da release.
if ! command -v curl &>/dev/null || ! command -v unzip &>/dev/null; then
  echo "⚠️  Dependências ausentes. Instalando curl e unzip..."
  $SUDO apt update && $SUDO apt install -y curl unzip || {
    echo "❌ Falha ao instalar dependências (curl/unzip)"
    exit 1
  }
fi

echo "🌀 Criando diretório $WORKDIR..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "📥 Baixando última release de $REPO..."
ZIP_URL=$(curl -fsSL "$GITHUB_API_URL" | sed -n 's/.*"zipball_url":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
if [ -z "$ZIP_URL" ]; then
  echo "❌ Não foi possível obter zipball_url da release mais recente."
  echo "💡 Verifique se o repositório existe e se há release publicada: $REPO"
  exit 1
fi
curl -fL "$ZIP_URL" -o "$ZIPFILE"

echo "📦 Extraindo arquivos..."
unzip -o "$ZIPFILE" >/dev/null
EXTRACTED_DIR=$(unzip -Z1 "$ZIPFILE" | cut -d/ -f1 | sed -n '1p')
if [ -z "$EXTRACTED_DIR" ] || [ ! -d "$EXTRACTED_DIR" ]; then
  echo "❌ Não foi possível identificar o diretório extraído da release."
  exit 1
fi
cd "$EXTRACTED_DIR"

echo "🐳 Instalando Docker..."
chmod +x installDocker.sh
$SUDO ./installDocker.sh

echo "🚀 Instalando SGV..."
chmod +x installsgv.sh
$SUDO ./installsgv.sh

echo "✅ Instalação finalizada com sucesso!"