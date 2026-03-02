#!/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Uso: $0 <war-name> <war-url> [md5-url]"
  exit 1
fi

WAR_BASENAME="$1"
WAR_FILE="/java/install/${WAR_BASENAME}.war"
WAR_VERSIONED="/java/install/${WAR_BASENAME}##$(date +%s).war"
WAR_URL="$2"
MD5_URL="${3:-}"

echo "Atualizando ${WAR_BASENAME}"
echo "Baixando ${WAR_URL}"
curl -fsSL "$WAR_URL" -o "$WAR_FILE"

if [ -n "$MD5_URL" ]; then
  REMOTE_MD5="$(curl -fsSL "$MD5_URL" | awk '{print $1}')"
  if [[ "$REMOTE_MD5" =~ ^[A-Fa-f0-9]{32}$ ]]; then
    LOCAL_MD5="$(md5sum "$WAR_FILE" | awk '{print $1}')"
    if [ "$LOCAL_MD5" != "$REMOTE_MD5" ]; then
      echo "ERRO: MD5 inválido para ${WAR_BASENAME}.war"
      exit 1
    fi
  else
    echo "ERRO: MD5 remoto inválido em ${MD5_URL}"
    exit 1
  fi
fi 

cp -vf "$WAR_FILE" "$WAR_VERSIONED"
mv -vf "$WAR_VERSIONED" /java/tomcat/webapps
echo "${WAR_BASENAME} atualizado com sucesso"
