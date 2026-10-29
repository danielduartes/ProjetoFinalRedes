#!/bin/bash
set -eu
: "${DB_PASSWORD:?defina DB_PASSWORD}"
: "${SMB_PASSWORD:?defina SMB_PASSWORD}"
REPO=https://github.com/danielduartes/ProjetoFinalRedes.git
DIR=/opt/projeto

apt-get update
apt-get install -y git postgresql smbclient cron
if [ -d $DIR/.git ]; then git -C $DIR pull; else git clone $REPO $DIR; fi

cp $DIR/db/listen.conf /etc/postgresql/15/main/conf.d/listen.conf
grep -q app_db /etc/postgresql/15/main/pg_hba.conf || cat $DIR/db/pg_hba_regra_app.txt >> /etc/postgresql/15/main/pg_hba.conf
systemctl restart postgresql
sleep 3

runuser -u postgres -- psql -c "ALTER USER app_user WITH PASSWORD '$DB_PASSWORD'" || runuser -u postgres -- psql -c "CREATE USER app_user WITH PASSWORD '$DB_PASSWORD'"
runuser -u postgres -- psql -tc "SELECT 1 FROM pg_database WHERE datname='app_db'" | grep -q 1 || runuser -u postgres -- createdb -O app_user app_db
runuser -u postgres -- psql -c "REVOKE ALL ON DATABASE app_db FROM PUBLIC"

printf 'username=backupsvc\npassword=%s\n' "$SMB_PASSWORD" > /root/.smbcred
chmod 600 /root/.smbcred
cp $DIR/db/backup_postgres.sh /usr/local/bin/backup_postgres.sh
chmod +x /usr/local/bin/backup_postgres.sh
cp $DIR/db/cron_backup_postgres /etc/cron.d/backup_postgres
systemctl enable --now cron

cp $DIR/db/interfaces_db /etc/network/interfaces
systemctl restart networking
