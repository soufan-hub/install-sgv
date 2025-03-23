#!/bin/bash
set -euo pipefail

BASE_URL="https://hom.opentickets.app/"
AUTH="Authorization: Basic ZGVwbG95OmNhdG90YUAyMDE3"

function downloadJenkins() {
  local name="$1"
  local url="$2"
  echo "⬇️  Baixando $name..."
  curl -sSL -H "$AUTH" "$url" -o "./.webapps/$name.war"
  echo "✅ $name baixado!"
}

mkdir -p backup .webapps

if [ ! -f backup/alo.dump ]; then
  echo "⬇️  Baixando backup..."
  curl -sSL https://sga-file.s3.sa-east-1.amazonaws.com/sgv/new/alop_sgv_20230805.backup -o backup/alo.dump
fi

downloadJenkins "sgv" "${BASE_URL}jenkins/view/SGV/job/alo-sgv-web/ws/target/sgv.war"
downloadJenkins "static" "${BASE_URL}jenkins/view/SGV/job/static/ws/target/static.war"
downloadJenkins "validation-ws" "${BASE_URL}jenkins/view/SGV/job/alo-validation-sgv-ws/ws/target/ProducerWS.war"

echo "📦 Iniciando containers..."
docker compose up -d

echo "🔁 Reiniciando tomcat..."
docker compose stop tomcat
sleep 10
docker compose start tomcat

echo "✅ SGV instalado e containers em execução em http://localhost/sgv"
