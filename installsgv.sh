#!/bin/bash
set -euo pipefail

function getFileMd5() {
  local file="$1"
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$file" | awk '{print $1}'
  else
    md5 -q "$file"
  fi
}

function downloadWarIfNeeded() {
  local name="$1"
  local warUrl="$2"
  local md5Url="$3"
  local warFile="./.webapps/${name}.war"

  local remoteMd5=""
  if remoteMd5=$(curl -fsSL "$md5Url" | awk '{print $1}'); then
    if [[ ! "$remoteMd5" =~ ^[A-Fa-f0-9]{32}$ ]]; then
      echo "⚠️  MD5 remoto inválido para ${name}.war, seguindo com download."
      remoteMd5=""
    fi
  else
    echo "⚠️  Não foi possível obter ${name}.war.md5, seguindo com download."
  fi

  if [ -n "$remoteMd5" ]; then
    if [ -f "$warFile" ]; then
      local localMd5
      localMd5=$(getFileMd5 "$warFile")
      if [ "$localMd5" = "$remoteMd5" ]; then
        echo "✅ ${name}.war já está atualizado (MD5 ok), pulando download."
        return
      fi
      echo "♻️  ${name}.war desatualizado (MD5 diferente), baixando novamente..."
    fi
  fi

  echo "⬇️  Baixando ${name}..."
  curl -fsSL "$warUrl" -o "$warFile"
  if [ -n "$remoteMd5" ]; then
    local downloadedMd5
    downloadedMd5=$(getFileMd5 "$warFile")
    if [ "$downloadedMd5" != "$remoteMd5" ]; then
      echo "❌ Falha de integridade: MD5 inválido para ${name}.war após download."
      exit 1
    fi
  fi
  echo "✅ ${name} baixado!"
}

mkdir -p backup .webapps

if [ ! -f backup/alo.dump ]; then
  echo "⬇️  Baixando backup..."
  curl -fsSL https://s3.fanticekts.com/sgv/alop.dump -o backup/alo.dump
fi

downloadWarIfNeeded "sgv" "https://s3.fanticekts.com/sgv/sgv.war" "https://s3.fanticekts.com/sgv/sgv.war.md5"
downloadWarIfNeeded "static" "https://s3.fanticekts.com/sgv/static.war" "https://s3.fanticekts.com/sgv/static.war.md5"
downloadWarIfNeeded "validation-ws" "https://s3.fanticekts.com/sgv/validation-ws.war" "https://s3.fanticekts.com/sgv/validation-ws.war.md5"

echo "📦 Iniciando containers..."
docker compose up -d

echo "🔁 Reiniciando tomcat..."
docker compose stop tomcat
sleep 10
docker compose start tomcat

echo "✅ SGV instalado e containers em execução em http://localhost/sgv"
