# Projeto Integrador - Infraestrutura de Redes e Servidores Linux

Disciplina: Redes de Computadores e Administração de SO
Equipe: Maria Clara Lacerda, Maria Júlia Braga, Amanda Cristina, Lívia Santos e Daniel Duarte

Infraestrutura de 4 servidores Debian 12 (sem interface gráfica) em 3 zonas de rede isoladas, rodando em VirtualBox. O firewall bloqueia tudo por padrão e libera só o tráfego da matriz de conectividade do enunciado.

## Arquitetura

| Host | Zona | IP | Função |
| --- | --- | --- | --- |
| fw | DMZ, LAN e DB Zone | 10.0.1.1, 10.0.2.1 e 10.0.3.1 | Firewall e NAT (nftables), DHCP (dnsmasq) e DNS (Unbound) |
| web | DMZ (10.0.1.0/24) | 10.0.1.10 | Nginx com HTTPS e API FastAPI |
| arquivos | LAN (10.0.2.0/24) | 10.0.2.10 | Samba com permissões por grupo e cotas de disco |
| db | DB Zone (10.0.3.0/24) | 10.0.3.10 | PostgreSQL 15 com backup automático |

Domínio interno: `empresa.local`.

## Estrutura do repositório

- `firewall/`: nftables, rede, DHCP e DNS do fw
- `web/`: Nginx, limite de requisições, aplicação e serviço systemd
- `db/`: escuta do PostgreSQL, regra do `pg_hba.conf` e backup com cron
- `arquivos/`: Samba, rotação dos backups e rede
- `provisionamento/`: um script por servidor
- `docs/`: relatório técnico, tabela de endereçamento e `evidencias/` (prints dos testes)

## Como provisionar

Em cada máquina Debian limpa, como root, com o repositório clonado em `/opt/projeto`:

```
apt-get install -y git
git clone https://github.com/danielduartes/ProjetoFinalRedes.git /opt/projeto
bash /opt/projeto/provisionamento/provisiona_fw.sh
DB_PASSWORD=... SMB_PASSWORD=... bash /opt/projeto/provisionamento/provisiona_db.sh
DB_PASSWORD=... bash /opt/projeto/provisionamento/provisiona_web.sh
SMB_PASSWORD=... bash /opt/projeto/provisionamento/provisiona_arquivos.sh
```

Cada comando roda na máquina do seu nome. As senhas vão por variável de ambiente e não ficam no repositório. Os scripts desativam o login por senha no SSH, então a chave pública deve ser copiada para a máquina antes (`ssh-copy-id`).

## Segurança

- O banco só aceita conexão da web (firewall, `listen_addresses` e `pg_hba.conf` com scram-sha-256).
- HTTPS com TLS 1.2 ou superior, limite de requisições e logs com rotação.
- SSH só pela LAN, só com chave e sem login de root.
- O arquivo de credenciais do backup não está no repositório.

As senhas de teste são simples, por se tratar de um ambiente de laboratório isolado.

## Documentação

O relatório técnico, com topologia, tabelas, procedimentos operacionais e evidências, está em `docs/`.
