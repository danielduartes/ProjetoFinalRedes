#!/bin/bash
set -eu
: "${DB_PASSWORD:?defina DB_PASSWORD}"
REPO=https://github.com/danielduartes/ProjetoFinalRedes.git
DIR=/opt/projeto

apt-get update
apt-get install -y git nginx openssl python3-venv python3-pip
if [ -d $DIR/.git ]; then git -C $DIR pull; else git clone $REPO $DIR; fi

[ -d /opt/app ] || python3 -m venv /opt/app
/opt/app/bin/pip install fastapi uvicorn psycopg2-binary
cp $DIR/web/main.py /opt/app/main.py
printf 'DB_PASSWORD=%s\n' "$DB_PASSWORD" > /etc/app.env
chmod 600 /etc/app.env
cp $DIR/web/app.service /etc/systemd/system/app.service

mkdir -p /etc/nginx/ssl /var/www/errors
[ -f /etc/nginx/ssl/web.crt ] || openssl req -x509 -nodes -newkey rsa:2048 -days 365 -keyout /etc/nginx/ssl/web.key -out /etc/nginx/ssl/web.crt -subj "/CN=web.empresa.local"
echo '<h1>404 - Pagina nao encontrada</h1>' > /var/www/errors/404.html
echo '<h1>500 - Erro no servidor</h1>' > /var/www/errors/50x.html
cp $DIR/web/ratelimit.conf /etc/nginx/conf.d/ratelimit.conf
cp $DIR/web/nginx_app.conf /etc/nginx/sites-available/app
ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
rm -f /etc/nginx/sites-enabled/default
nginx -t

systemctl daemon-reload
systemctl enable --now app nginx
systemctl restart app nginx

cp $DIR/web/interfaces_web /etc/network/interfaces
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
