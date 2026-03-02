#!/bin/bash
set -euo pipefail
umask 022

if [ "$#" -lt 2 ]; then
  echo "Uso: $0 <arquivo-backup> <database>"
  exit 1
fi

OUT_FILE="/java/bkps/$(basename "$1")"
DB_NAME="$2"

/usr/bin/pg_dump --host postgres --port 5432 --username "alo" --no-password -Fc -Z9 --blobs --verbose --file "$OUT_FILE" "$DB_NAME" 2>&1

if [ -s "$OUT_FILE" ]; then
	echo "###################################################################"
	echo "BACKUP GERADO COM SUCESSO EM $(date)"
	echo "###################################################################"
	chmod 644 "$OUT_FILE"
	exit 0
else
	echo "###################################################################"
	echo "FALHA AO GERAR O BACKUP - $(date)"
	echo "###################################################################"
	exit 1
fi
