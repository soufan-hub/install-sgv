#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Uso: $0 <database> [arquivo-backup]"
  exit 1
fi

DB_NAME="$1"
BACKUP_FILE="${2:-}"

if [ -z "$BACKUP_FILE" ]; then
  BACKUP_FILE="$(ls -1t /java/bkps/* 2>/dev/null | head -n1 || true)"
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "###################################################################"
  echo "FALHA NO RESTORE - backup não encontrado em /java/bkps - $(date)"
  echo "###################################################################"
  exit 1
fi

if /usr/bin/pg_restore --host postgres --port 5432 --username "alo" --dbname "$DB_NAME" --no-password --verbose --clean "$BACKUP_FILE" 2>&1; then
	echo "###################################################################"
	echo "RESTORE COM SUCESSO EM $(date)"
	echo "###################################################################"
	exit 0
else
	echo "###################################################################"
	echo "FALHA NO RESTORE - $(date)"
	echo "###################################################################"
	exit 1
fi
