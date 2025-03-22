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

# Clean up temporary directory on exit
trap "rm -rf $TMP_DIR" EXIT

info "🌀 Creating temporary directory at $TMP_DIR..."
mkdir -p "$TMP_DIR"

info "📥 Downloading latest release from $REPO..."
ZIP_URL=$(curl -s https://api.github.com/repos/${REPO}/releases/latest \
  | grep "zipball_url" \
  | cut -d '"' -f 4)

[ -z "$ZIP_URL" ] && error "Could not find the latest release."

curl -L "$ZIP_URL" -o "$ZIP_FILE" || error "Failed to download the release zip."

# Ensure unzip is installed
if ! command -v unzip &>/dev/null; then
  info "📦 'unzip' not found. Installing..."
  sudo apt update && sudo apt install unzip -y || error "Failed to install unzip."
fi

# Ensure vim is installed
if ! command -v vim &>/dev/null; then
  info "📝 'vim' not found. Installing..."
  sudo apt update && sudo apt install vim -y || error "Failed to install vim."
fi

info "📦 Extracting files..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

# Find the extracted directory (with a name that includes "install-sgv")
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "*install-sgv*" | head -n 1)
[ -z "$EXTRACTED_DIR" ] && error "Failed to find the extracted directory."

info "📂 Listing content of the extracted directory ($EXTRACTED_DIR):"
ls -la "$EXTRACTED_DIR"

# Print a recursive file listing to help debug file names
info "🔍 Full recursive file listing:"
find "$EXTRACTED_DIR" -type f

cd "$EXTRACTED_DIR"

# Function to find a script file by matching one of several patterns
function find_script {
  local found=""
  for pattern in "$@"; do
    found=$(find . -type f -iname "$pattern" | head -n 1)
    if [ -n "$found" ]; then
      echo "$found"
      return 0
    fi
  done
  return 1
}

# Try different patterns for Docker install script
DOCKER_SCRIPT=$(find_script "installDocker.sh" "install-docker.sh" "docker.sh")
if [ -z "$DOCKER_SCRIPT" ]; then
  info "Available files in the current directory tree:"
  find . -type f
  error "Docker installation script not found. Please verify the filename inside the zip."
fi

# Try different patterns for SGV install script, including "installsgv.sh"
SGV_SCRIPT=$(find_script "installSgv.sh" "install-sgv.sh" "sgv.sh" "installsgv.sh")
if [ -z "$SGV_SCRIPT" ]; then
  info "Available files in the current directory tree:"
  find . -type f
  error "SGV installation script not found. Please verify the filename inside the zip."
fi

info "🐳 Installing Docker using script: $DOCKER_SCRIPT"
chmod +x "$DOCKER_SCRIPT"
"$DOCKER_SCRIPT" || error "Failed to execute Docker installation script: $DOCKER_SCRIPT"

info "🚀 Installing SGV using script: $SGV_SCRIPT"
chmod +x "$SGV_SCRIPT"
"$SGV_SCRIPT" || error "Failed to execute SGV installation script: $SGV_SCRIPT"

info "✅ Installation completed successfully!"