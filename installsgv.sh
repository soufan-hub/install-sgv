#!/bin/bash

function downloadJenkins() {
  echo "Atualizando $1\nBaixando $2";
  curl -H "Authorization: Basic ZGVwbG95OmNhdG90YUAyMDE3" $2 -o "./.webapps/$1.war" -X GET 

  if [ $? -eq 0 ]; then
    echo "$1 atualizado com sucesso";
  else
    echo "ERRO ${WAR_NAME}";
  fi 
}

[ -f ./backup/alo.dump ] || curl https://sga-file.s3.sa-east-1.amazonaws.com/sgv/new/alop_sgv_20230805.backup -X GET -o ./backup/alo.dump

mkdir -p .webapps
downloadJenkins sgv https://hom.opentickets.app/jenkins/view/SGV/job/alo-sgv-web/ws/target/sgv.war
downloadJenkins static https://hom.opentickets.app/jenkins/view/SGV/job/static/ws/target/static.war
downloadJenkins validation-ws https://hom.opentickets.app/jenkins/view/SGV/job/alo-validation-sgv-ws/ws/target/ProducerWS.war

docker compose up -d
docker compose stop tomcat
sleep 15
docker compose start tomcat

