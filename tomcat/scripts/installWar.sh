#!/bin/bash
echo "Atualizando $1";
export WAR_NAME="/java/install/$1.war"
export WAR_NAME_NEW="/java/install/$1##$(date +%s).war"
export URL=$2

echo "Baixando $URL";
wget --timeout 3600 --progress=bar:force:noscroll --header="Authorization: Basic ZGVwbG95OmNhdG90YUAyMDE3" $URL -O ${WAR_NAME};

if [ $? -eq 0 ]; then
	cp -v ${WAR_NAME} ${WAR_NAME_NEW};
	mv -v ${WAR_NAME_NEW} /java/tomcat/webapps;
	echo "$1 atualizado com sucesso";
else
	banner "ERRO ${WAR_NAME}";
fi 

