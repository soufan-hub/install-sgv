#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

REPO="soufan-hub/install-sgv"
WORKDIR="install-sgv"
ZIPFILE="latest.zip"
ZIP_URL="https://codeload.github.com/$REPO/zip/refs/heads/main"
INSTALLER_VERSION="v0.0.21"

echo "🚀 Iniciando instalador SGV (${INSTALLER_VERSION})"

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
  $SUDO apt-get update && $SUDO apt-get install -y --no-install-recommends curl unzip || {
    echo "❌ Falha ao instalar dependências (curl/unzip)"
    exit 1
  }
fi

if [ -d "$WORKDIR" ]; then
  echo "🧹 Limpando diretório existente: $WORKDIR"
  rm -rf "${WORKDIR:?}/"*
fi

echo "🌀 Criando diretório $WORKDIR..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "📥 Baixando versão mais recente da branch main de $REPO..."
curl -fsSL "$ZIP_URL" -o "$ZIPFILE"

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