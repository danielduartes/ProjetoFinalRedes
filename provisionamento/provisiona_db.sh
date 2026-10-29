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


#!/bin/bash
set -eu
REPO=https://github.com/danielduartes/ProjetoFinalRedes.git
DIR=/opt/projeto

printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
apt-get update
apt-get install -y git nftables dnsmasq unbound
rm -f /usr/sbin/policy-rc.d

if [ -d $DIR/.git ]; then git -C $DIR pull; else git clone $REPO $DIR; fi

cp $DIR/firewall/interfaces_fw /etc/network/interfaces
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-forward.conf
cp $DIR/firewall/nftables.conf /etc/nftables.conf
cp $DIR/firewall/dnsmasq.conf /etc/dnsmasq.conf
cp $DIR/firewall/unbound_empresa.conf /etc/unbound/unbound.conf.d/empresa.conf

nft -c -f /etc/nftables.conf
dnsmasq --test
unbound-checkconf

systemctl enable nftables dnsmasq unbound
sysctl --system
systemctl restart networking
systemctl restart nftables dnsmasq unbound

cat > /etc/ssh/sshd_config.d/10-so-chave.conf << 'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sshd -t
systemctl reload ssh
