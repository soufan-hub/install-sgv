#!/bin/bash
umask 022
/usr/bin/pg_dump --host postgres --port 5432 --username "alo" --no-password  -Fc -Z9 --blobs --verbose --file "/java/bkps/$(basename $1)" "$2" 2>&1

if [ -e "$1" ]; then
	mv -vf "$1" /java/bkps
	echo "###################################################################"
	echo "BACKUP GERADO COM SUCESSO EM $(date)
	echo "###################################################################"
	chmod -Rf 644 /java/bkps
	exit 0;	
else
	echo "###################################################################"
	echo "FALHA AO GERAR O BACKUP - $(date)
	echo "###################################################################"
	exit 1; 
fi

