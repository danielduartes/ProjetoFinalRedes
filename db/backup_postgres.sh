#!/bin/bash
# Backup diario do PostgreSQL: pg_dump + .tar.gz + rotacao de 7 dias + envio ao servidor de arquivos
set -eu
cd /tmp
exec >> /var/log/backup_postgres.log 2>&1

BACKUP_DIR=/var/backups/postgres
DATA=$(date +%F_%H-%M-%S)
NOME=app_db_$DATA

mkdir -p $BACKUP_DIR
/usr/sbin/runuser -u postgres -- pg_dump app_db > $BACKUP_DIR/$NOME.sql
tar -czf $BACKUP_DIR/$NOME.tar.gz -C $BACKUP_DIR $NOME.sql
rm $BACKUP_DIR/$NOME.sql
find $BACKUP_DIR -name "app_db_*.tar.gz" -mtime +7 -delete

/usr/bin/smbclient //10.0.2.10/backups -A /root/.smbcred -c "put $BACKUP_DIR/$NOME.tar.gz $NOME.tar.gz"

echo Backup concluido e enviado: $NOME.tar.gz
