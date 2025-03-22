#!/bin/bash

/usr/bin/pg_restore --host postgres --port 5432 --username "alo" --dbname $1 --no-password  --verbose --clean $(ls -1r /java/bkps/*.gz | head -1) 2>&1

if [ $? -eq 0 ]; then
	echo "###################################################################"
	echo "RESTORE COM SUCESSO EM $(date)
	echo "###################################################################"
	exit 0;	
else
	echo "###################################################################"
	echo "FALHA NO RESTORE - $(date)
	echo "###################################################################"
	exit 1; 
fi
