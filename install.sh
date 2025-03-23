#!/bin/bash
set -euo pipefail

REPO="soufan-hub/install-sgv"
TMP_DIR="./install-sgv"
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
ZIP_URL=$(curl -s https://api.github.com/repos/${REPO}/releases/latest | grep "zipball_url" | cut -d '"' -f 4)
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
# -o forces overwriting files without prompting
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"

# Find the extracted directory (its name contains "install-sgv")
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "*install-sgv*" | head -n 1)
[ -z "$EXTRACTED_DIR" ] && error "Failed to find the extracted directory."

info "📂 Listing content of the extracted directory ($EXTRACTED_DIR):"
ls -la "$EXTRACTED_DIR"

info "🔍 Recursive file listing:"
find "$EXTRACTED_DIR" -type f

cd "$EXTRACTED_DIR"

# Function to find a script by pattern
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

DOCKER_SCRIPT=$(find_script "installDocker.sh" )
[ -z "$DOCKER_SCRIPT" ] && { info "Available files:"; find . -type f; error "Docker installation script not found."; }

SGV_SCRIPT=$(find_script "installsgv.sh")
[ -z "$SGV_SCRIPT" ] && { info "Available files:"; find . -type f; error "SGV installation script not found."; }

# Copy sub-scripts to a separate directory so they run independently
cp "$DOCKER_SCRIPT" "$TMP_DIR/"
cp "$SGV_SCRIPT" "$TMP_DIR/"
chmod +x "$TMP_DIR/"*.sh

info "🐳 Running Docker installation script..."
"$TMP_DIR/$(basename "$DOCKER_SCRIPT")" || error "Docker installation script failed."

info "🚀 Running SGV installation script..."
"$TMP_DIR/$(basename "$SGV_SCRIPT")" || error "SGV installation script failed."

info "✅ Installation completed successfully!"