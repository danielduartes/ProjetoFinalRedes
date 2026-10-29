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
