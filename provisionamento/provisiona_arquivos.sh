#!/bin/bash
set -eu
: "${SMB_PASSWORD:?defina SMB_PASSWORD}"
REPO=https://github.com/danielduartes/ProjetoFinalRedes.git
DIR=/opt/projeto

apt-get update
apt-get install -y git samba quota cron
if [ -d $DIR/.git ]; then git -C $DIR pull; else git clone $REPO $DIR; fi

for g in devs mkt diretoria backup_mgr; do getent group $g > /dev/null || groupadd $g; done
id ana > /dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -G devs ana
id bruno > /dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -G mkt bruno
id carla > /dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -G diretoria carla
id backupsvc > /dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -G backup_mgr backupsvc
for u in ana bruno carla backupsvc; do printf '%s\n%s\n' "$SMB_PASSWORD" "$SMB_PASSWORD" | smbpasswd -s -a $u; done

mkdir -p /compartilhado/publico /compartilhado/projetos /compartilhado/backups
chmod 1777 /compartilhado/publico
chown root:devs /compartilhado/projetos
chmod 2770 /compartilhado/projetos
chown root:backup_mgr /compartilhado/backups
chmod 2770 /compartilhado/backups

cp $DIR/arquivos/smb.conf /etc/samba/smb.conf
testparm -s > /dev/null
systemctl enable --now smbd
systemctl restart smbd

grep -q usrquota /etc/fstab || sed -i 's/errors=remount-ro/errors=remount-ro,usrquota,grpquota/' /etc/fstab
systemctl daemon-reload
mount -o remount /
[ -f /aquota.user ] || quotacheck -cugm /
quotaon -v / || true
setquota -u ana 5000 6000 0 0 /

cp $DIR/arquivos/rotacao_backups /etc/cron.d/rotacao_backups
systemctl enable --now cron

cp $DIR/arquivos/interfaces_arquivos /etc/network/interfaces
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
