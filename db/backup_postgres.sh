#!/bin/bash
# Backup diario do PostgreSQL: pg_dump + compactacao em .tar.gz + rotacao de 7 dias
set -euo pipefail
cd /tmp
BACKUP_DIR=/var/backups/postgres
DB_NAME=app_db
DATA=$(date +%F_%H-%M-%S)
ARQUIVO_SQL=$BACKUP_DIR/${DB_NAME}_${DATA}.sql
ARQUIVO_TAR=$BACKUP_DIR/${DB_NAME}_${DATA}.tar.gz
mkdir -p $BACKUP_DIR
# Gera o dump como usuario postgres
/usr/sbin/runuser -u postgres -- pg_dump $DB_NAME > $ARQUIVO_SQL
# Compacta e remove o .sql solto
tar -czf $ARQUIVO_TAR -C $BACKUP_DIR ${DB_NAME}_${DATA}.sql
rm $ARQUIVO_SQL
# Rotacao: apaga backups com mais de 7 dias
find $BACKUP_DIR -name ${DB_NAME}_*.tar.gz -mtime +7 -delete
echo Backup concluido: $ARQUIVO_TAR
