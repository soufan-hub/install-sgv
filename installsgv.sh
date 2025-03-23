#!/bin/bash
set -euo pipefail

# Base URL for the application
BASE_URL="https://hom.opentickets.app/"

# Function to display error messages in red and exit
function error {
  echo -e "\\e[91mERROR: $1\\e[39m"
  exit 1
}

# Function to download Jenkins WAR files with proper error handling and verbose output
function downloadJenkins() {
  local app_name="$1"
  local url="$2"
  
  echo -e "Atualizando ${app_name}\nBaixando ${url}"
  
  # Attempt to download the file, capturing any curl errors
  if ! curl -H "Authorization: Basic ZGVwbG95OmNhdG90YUAyMDE3" "${url}" -o "./.webapps/${app_name}.war" -X GET; then
    error "Failed to download ${app_name} from ${url}"
  fi
  
  echo "${app_name} atualizado com sucesso"
}

# Ensure backup directory exists before downloading the backup file
mkdir -p backup

# Ensure backup file is present; if not, download it.
if [ ! -f "backup/alo.dump" ]; then
  echo "Backup file not found. Downloading..."
  if ! curl -sSL "https://sga-file.s3.sa-east-1.amazonaws.com/sgv/new/alop_sgv_20230805.backup" -X GET -o "backup/alo.dump"; then
    error "Failed to download backup file"
  fi
fi

# Create the .webapps directory if it doesn't exist
mkdir -p .webapps

# Download Jenkins WAR files using the BASE_URL
downloadJenkins "sgv" "${BASE_URL}jenkins/view/SGV/job/alo-sgv-web/ws/target/sgv.war"
downloadJenkins "static" "${BASE_URL}jenkins/view/SGV/job/static/ws/target/static.war"
downloadJenkins "validation-ws" "${BASE_URL}jenkins/view/SGV/job/alo-validation-sgv-ws/ws/target/ProducerWS.war"

# Start Docker Compose services in detached mode
echo "Starting Docker Compose services..."
if ! docker compose up -d; then
  error "Failed to start Docker Compose services."
fi

# Stop the tomcat service
echo "Stopping tomcat service..."
if ! docker compose stop tomcat; then
  error "Failed to stop tomcat service."
fi

# Wait for 15 seconds
sleep 15

# Start the tomcat service again
echo "Starting tomcat service..."
if ! docker compose start tomcat; then
  error "Failed to start tomcat service."
fi

echo "Script executed successfully."