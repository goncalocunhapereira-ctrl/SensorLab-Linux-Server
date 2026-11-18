## 1. Criar as máquinas virtuais, utilizadores e permissões (R1)

1. No **VirtualBox**, criar uma VM com **Ubuntu Server 26.04 LTS**, identificada como `srv-g1-projeto`. Configurar o **Adaptador 1** como **NAT** e o **Adaptador 2** como **Rede Interna**, com o nome `labnet`. Durante a instalação, criar um utilizador com privilégios administrativos.
2. Criar uma segunda VM Linux, `cli-g1`, com um adaptador na mesma rede interna `labnet`. Será usada nos testes de DHCP, DNS e HTTPS.
3. No terminal do servidor, criar as restantes contas. **Os nomes usados nos comandos são exemplos: substituí-los pelos nomes pretendidos e adaptar os restantes comandos.** Não voltar a criar o utilizador já criado durante a instalação.

```bash
sudo hostnamectl set-hostname srv-g1-projeto
sudo adduser goncalo
sudo adduser guilherme
sudo adduser docente
sudo usermod -aG sudo rui
getent group sudo                        # apenas o administrador deve ter sudo
id rui; id goncalo; id guilherme; id docente
```

4. Criar um grupo para os três utilizadores do projeto e uma pasta partilhada. A conta `docente` não pertence a esse grupo.

```bash
sudo apt update
sudo apt install -y acl
sudo groupadd -f sensorlab
sudo gpasswd -M rui,goncalo,guilherme sensorlab
sudo chmod 750 /home/rui /home/goncalo /home/guilherme /home/docente
sudo install -d -o root -g sensorlab -m 2770 /srv/sensorlab
sudo setfacl -m g:sensorlab:rwx,m::rwx /srv/sensorlab
sudo setfacl -d -m g:sensorlab:rwx,m::rwx /srv/sensorlab
getent group sensorlab
ls -ld /srv/sensorlab
getfacl /srv/sensorlab
```

5. Testar as permissões. A primeira operação deve funcionar e a segunda deve devolver `Permission denied`.

```bash
sudo -u goncalo touch /srv/sensorlab/teste-goncalo.txt
sudo -u docente touch /srv/sensorlab/teste-docente.txt
```

## 2. Instalar OpenSSH e configurar a firewall UFW (R2)

1. No servidor, instalar e ativar o SSH:

```bash
sudo apt install -y openssh-server ufw
sudo systemctl enable --now ssh.socket
sudo ss -lntp | grep ':22'
```

2. No **VirtualBox → Definições do servidor → Rede → Adaptador NAT → Reencaminhamento de portas**, criar uma regra TCP com **porta anfitrião `2222` → porta convidado `22`**, usando `127.0.0.1` como IP anfitrião.
3. No **PowerShell do Windows**, criar uma chave SSH:

```powershell
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\sensorlab_rui_ed25519"
Get-Content "$env:USERPROFILE\.ssh\sensorlab_rui_ed25519.pub"
```

4. Copiar a **chave pública** mostrada pelo PowerShell e colá-la numa linha do ficheiro `authorized_keys` do utilizador do servidor:

```bash
sudo install -d -o rui -g rui -m 700 /home/rui/.ssh
sudo nano /home/rui/.ssh/authorized_keys
sudo chown rui:rui /home/rui/.ssh/authorized_keys
sudo chmod 600 /home/rui/.ssh/authorized_keys
```

5. **Antes de desativar palavras-passe**, testar no Windows:

```powershell
ssh -i "$env:USERPROFILE\.ssh\sensorlab_rui_ed25519" -p 2222 rui@127.0.0.1
```

6. Depois de confirmar o acesso por chave, criar o ficheiro de configuração SSH:

```bash
sudo nano /etc/ssh/sshd_config.d/99-sensorlab.conf
```

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
```

7. Validar o SSH e configurar a firewall. **Manter a consola do VirtualBox acessível e não encerrar a ligação SSH que já funciona até testar uma nova ligação.**

```bash
sudo sshd -t
sudo systemctl reload ssh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw --force enable
sudo ufw status verbose
sudo sshd -T | grep -E 'pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|permitrootlogin'
```

No Windows, repetir a ligação SSH por chave. O acesso por palavra-passe deve ser recusado. Se `ssh.service` aparecer inativo, confirmar `ssh.socket` e a porta 22: o Ubuntu pode usar ativação por socket.

## 3. Configurar o servidor DHCP Kea (R3)

1. No servidor, verificar o nome da ligação à rede interna e atribuir-lhe o IP fixo `192.168.50.1/24` (exemplo com NetworkManager):

```bash
nmcli connection show
sudo nmcli connection modify netplan-enp0s8 ipv4.method manual \
  ipv4.addresses 192.168.50.1/24 ipv4.never-default yes
sudo nmcli connection up netplan-enp0s8
ip -br -4 address
```

Substituir `netplan-enp0s8` se o nome apresentado por `nmcli` for diferente. Não alterar a ligação NAT. Se a instalação utilizar Netplan sem NetworkManager, configurar o mesmo endereço estático na interface interna com Netplan em vez de `nmcli`.

2. Instalar o Kea e editar a configuração:

```bash
sudo apt install -y kea-dhcp4-server
sudo nano /etc/kea/kea-dhcp4.conf
```

```json
{
  "Dhcp4": {
    "interfaces-config": { "interfaces": ["enp0s8"] },
    "valid-lifetime": 3600,
    "renew-timer": 900,
    "rebind-timer": 1800,
    "lease-database": {
      "type": "memfile", "persist": true,
      "name": "/var/lib/kea/kea-leases4.csv"
    },
    "subnet4": [{
      "subnet": "192.168.50.0/24",
      "pools": [{ "pool": "192.168.50.100 - 192.168.50.200" }],
      "option-data": [
        { "name": "domain-name-servers", "data": "192.168.50.1" },
        { "name": "domain-name", "data": "grupo1.lab" }
      ]
    }]
  }
}
```

3. Verificar a configuração, iniciar o serviço e permitir o DHCP pela interface interna:

```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl enable --now kea-dhcp4-server
sudo ufw allow in on enp0s8 to any port 67 proto udp
systemctl is-active kea-dhcp4-server
```

4. Na VM `cli-g1`, selecionar **obtenção automática de IP (DHCP)** na interface da `labnet`. Renovar a ligação e verificar:

```bash
ip -br -4 address
nmcli -f IP4.ADDRESS,IP4.DNS,IP4.DOMAIN device show enp0s8
```

O cliente deverá receber um IP entre `192.168.50.100` e `192.168.50.200`, DNS `192.168.50.1` e domínio `grupo1.lab`. No servidor, confirmar a concessão com `sudo tail -n 5 /var/lib/kea/kea-leases4.csv`.

## 4. Instalar BIND9 e configurar o DNS (R4)

1. No servidor, instalar o BIND9:

```bash
sudo apt install -y bind9 bind9-utils dnsutils
sudo nano /etc/bind/named.conf.local
```

Adicionar:

```text
zone "grupo1.lab" {
    type primary;
    file "/etc/bind/db.grupo1.lab";
};
```

2. Criar a zona DNS com `sudo nano /etc/bind/db.grupo1.lab`:

```dns
$TTL 3600
@ IN SOA ns.grupo1.lab. admin.grupo1.lab. (
    2026110301 3600 1800 604800 3600 )
@   IN NS ns.grupo1.lab.
ns  IN A  192.168.50.1
srv IN A  192.168.50.1
```

3. Validar, iniciar e autorizar DNS na rede interna:

```bash
sudo named-checkconf
sudo named-checkzone grupo1.lab /etc/bind/db.grupo1.lab
sudo systemctl enable --now named
sudo ufw allow in on enp0s8 to any port 53 proto udp
sudo ufw allow in on enp0s8 to any port 53 proto tcp
dig @192.168.50.1 srv.grupo1.lab +short
```

O resultado deve ser `192.168.50.1`. Na VM cliente, executar `resolvectl query srv.grupo1.lab` e `ping -c 4 srv.grupo1.lab`. Sempre que os registos da zona forem alterados, aumentar o número de série e recarregar o serviço.

## 5. Instalar Nginx e disponibilizar a página por HTTPS (R5)

1. Instalar o Nginx e criar uma página HTML simples:

```bash
sudo apt install -y nginx openssl curl
sudo mkdir -p /var/www/sensorlab
sudo nano /var/www/sensorlab/index.html
```

```html
<!doctype html>
<html lang="pt"><head><meta charset="UTF-8"><title>SensorLab</title></head>
<body><h1>SensorLab</h1><p>Servidor em funcionamento.</p></body></html>
```

2. Gerar um certificado TLS local:

```bash
sudo openssl req -x509 -nodes -newkey rsa:3072 -days 365 \
  -keyout /etc/ssl/private/sensorlab.key \
  -out /etc/ssl/certs/sensorlab.crt \
  -subj '/CN=srv.grupo1.lab' \
  -addext 'subjectAltName=DNS:srv.grupo1.lab,DNS:localhost,IP:127.0.0.1'
sudo chmod 600 /etc/ssl/private/sensorlab.key
```

3. Criar o site com `sudo nano /etc/nginx/sites-available/sensorlab`:

```nginx
server {
    listen 80;
    server_name srv.grupo1.lab;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    server_name srv.grupo1.lab localhost;
    ssl_certificate /etc/ssl/certs/sensorlab.crt;
    ssl_certificate_key /etc/ssl/private/sensorlab.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    root /var/www/sensorlab;
    index index.html;
    location / { try_files $uri $uri/ =404; }
    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

A secção `/api/` será utilizada no R7. Ativar o site e abrir as portas:

```bash
sudo ln -sfn /etc/nginx/sites-available/sensorlab /etc/nginx/sites-enabled/sensorlab
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
curl -I http://192.168.50.1
curl -kI https://192.168.50.1
```

O HTTP deve redirecionar (`301`) e o HTTPS responder (`200`). No VirtualBox, adicionar uma segunda regra de reencaminhamento TCP, **anfitrião `127.0.0.1:8443` → convidado `443`**. Testar `https://localhost:8443` no Windows e `https://srv.grupo1.lab` na VM cliente. O aviso de certificado não confiável é esperado num certificado autossinado de laboratório.

## 6. Instalar PostgreSQL e importar os dados WISDM (R6)

1. Obter a pasta do kit `2_entregar_aos_grupos`, que inclui `sql/01_esquema.sql`, `sql/02_importar.sql`, `sql/03_permissoes.sql`, `sql/04_verificar.sql` e os ficheiros `data/atividades.csv` e `data/wisdm_accel_phone.csv`. Colocá-la em `/home/rui/2_entregar_aos_grupos` (ajustar a pasta se o nome do utilizador for outro). Estes ficheiros são necessários para importar o dataset original, em vez de inventar dados.
2. Instalar PostgreSQL **no Ubuntu**:

```bash
sudo apt install -y postgresql postgresql-client
sudo systemctl enable --now postgresql
pg_lsclusters
sudo -u postgres createuser --superuser rui
createdb sensorlab
```

Se o utilizador PostgreSQL ou a base já existirem, não repetir a criação.

3. A partir da pasta do kit, executar os scripts pela ordem indicada:

```bash
cd ~/2_entregar_aos_grupos
sha256sum data/atividades.csv data/wisdm_accel_phone.csv
psql -d sensorlab -f sql/01_esquema.sql
(cd data && psql -d sensorlab -f ../sql/02_importar.sql)
psql -d sensorlab -v senha_api="$(openssl rand -hex 24)" -f sql/03_permissoes.sql
psql -d sensorlab -f sql/04_verificar.sql
```

4. Confirmar **18 atividades**, **756 964 leituras** e **10 participantes**; o papel `web_anon` deve conseguir consultar, mas não escrever. Manter a porta PostgreSQL `5432` acessível apenas localmente, sem a abrir na UFW. Se necessário, verificar com `sudo ss -lntp | grep ':5432'`.

## 7. Instalar Docker, PostgREST e Grafana (R7)

1. Instalar **Docker Engine** e o plugin **Docker Compose** no Ubuntu e confirmar o serviço:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
docker --version
docker compose version
```

Se o pacote `docker-compose-v2` não estiver disponível na distribuição, instalar o plugin `docker-compose-plugin` a partir do repositório oficial do Docker. Usar `sudo docker compose` nos passos seguintes.

2. Utilizar o `compose/docker-compose.yml`, `compose/initdb/00_init.sh` e os scripts SQL **do kit**. O Compose inclui `db` (PostgreSQL 17) e `api` (PostgREST). A base em Docker é **separada da instalada no R6**. Confirmar que a API publica apenas `127.0.0.1:3000:3000` e que o serviço `db` não publica a porta `5432`.
3. Criar as credenciais sem guardar palavras-passe no README ou no Git:

```bash
cd ~/2_entregar_aos_grupos/compose
cp .env.example .env
openssl rand -hex 24  # gerar uma senha para POSTGRES_PASSWORD
openssl rand -hex 24  # gerar outra para PGRST_SENHA
nano .env              # substituir as palavras-passe de exemplo
chmod 600 .env
sudo docker compose config -q
sudo docker compose up -d
sudo docker compose ps
```

4. Confirmar a importação automática realizada no primeiro arranque do volume:

```bash
sudo docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT COUNT(*) FROM api.atividades;"'
sudo docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT COUNT(*) FROM api.leituras;"'
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/atividades
curl -ks -o /dev/null -w '%{http_code}\n' https://srv.grupo1.lab/api/atividades
```

Resultados esperados: `18`, `756964`, `200` e `200`. O Nginx criado no R5 encaminha `/api/` para o PostgREST. Na VM cliente testar `curl -kI https://srv.grupo1.lab/api/atividades` e confirmar que não existe acesso direto à porta `3000` do servidor.

5. Para acrescentar o **Grafana**, adicionar ao ficheiro `compose/docker-compose.yml`, dentro de `services:` e ao mesmo nível de `db:` e `api:`:

```yaml
  grafana:
    image: grafana/grafana:13.3.1
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
    ports:
      - "127.0.0.1:3001:3000"
    volumes:
      - grafanadados:/var/lib/grafana
```

Na secção final `volumes:`, acrescentar `grafanadados:`; no `.env`, acrescentar `GRAFANA_ADMIN_USER=admin` e `GRAFANA_ADMIN_PASSWORD=` com uma senha segura. Depois executar `sudo docker compose up -d` e abrir `http://127.0.0.1:3001` no navegador da VM servidor.

6. No PostgreSQL do contentor, criar uma conta de leitura para o Grafana:

```bash
sudo docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

Dentro do `psql`:

```sql
CREATE ROLE grafana_reader LOGIN;
GRANT CONNECT ON DATABASE sensorlab TO grafana_reader;
GRANT USAGE ON SCHEMA api TO grafana_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO grafana_reader;
\password grafana_reader
\q
```

No Grafana, em **Connections → Data sources → PostgreSQL**, colocar `Host: db:5432`, `Database: sensorlab`, `User: grafana_reader` e a palavra-passe escolhida; selecionar a versão 17 e testar com **Save & test**. Criar o dashboard `Sensorlab - Monitorização WISDM` com dois painéis **Stat**:

```sql
SELECT COUNT(*) AS total_leituras FROM api.leituras;
SELECT COUNT(*) AS total_atividades FROM api.atividades;
```

Cada consulta corresponde a um painel. Os resultados devem ser `756964` e `18`.

7. Verificar a persistência dos dados:

```bash
sudo docker compose down
sudo docker compose up -d
sudo docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT COUNT(*) FROM api.leituras;"'
```

As `756964` leituras devem permanecer. **Não utilizar `docker compose down -v`**, porque essa opção elimina os volumes de dados.

## 8. Instalar Fail2ban e configurar backups automáticos (R8)

1. Instalar o Fail2ban, mantendo o acesso pela consola do VirtualBox e pelo SSH autorizado:

```bash
sudo apt install -y fail2ban
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 10.0.2.2
bantime = 600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 22
filter = sshd
backend = systemd
```

`10.0.2.2` corresponde ao anfitrião visto pela rede NAT desta instalação; confirmar esse IP antes de o utilizar noutra VM. Não provocar falhas de autenticação a partir do único acesso administrativo.

```bash
sudo fail2ban-client -t
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd banip 192.0.2.123
sudo fail2ban-client status sshd     # deverá indicar 1 IP bloqueado
sudo fail2ban-client set sshd unbanip 192.0.2.123
```

2. Criar a pasta e o script de backup da **base PostgreSQL em Docker**. Se o utilizador ou o caminho do projeto forem diferentes, alterar `COMPOSE_DIR`, `DESTINO` e `chown`:

```bash
sudo install -d -m 700 -o rui -g rui /home/rui/backups/sensorlab
sudo nano /usr/local/sbin/sensorlab-backup.sh
```

```bash
#!/usr/bin/env bash
set -euo pipefail
umask 077
COMPOSE_DIR=/home/rui/2_entregar_aos_grupos/compose
DESTINO=/home/rui/backups/sensorlab
DATA=$(date +%Y-%m-%d_%H-%M-%S)
ARQ="$DESTINO/sensorlab-$DATA.dump"
mkdir -p "$DESTINO"
cd "$COMPOSE_DIR"
CID=$(docker compose ps -q db)
test -n "$CID" || { echo 'Contentor db indisponível'; exit 1; }
trap 'rm -f "$ARQ.part"' EXIT
docker compose exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc -f /tmp/sensorlab.dump'
docker cp "$CID:/tmp/sensorlab.dump" "$ARQ.part"
docker compose exec -T db rm -f /tmp/sensorlab.dump
test -s "$ARQ.part"
mv "$ARQ.part" "$ARQ"
chown rui:rui "$ARQ"
find "$DESTINO" -maxdepth 1 -type f -name 'sensorlab-*.dump' -mtime +6 -delete
echo "Backup concluído: $ARQ"
ls -lh "$ARQ"
```

3. Validar o script, executar uma cópia manual e verificar o ficheiro:

```bash
sudo chmod 750 /usr/local/sbin/sensorlab-backup.sh
sudo bash -n /usr/local/sbin/sensorlab-backup.sh
sudo /usr/local/sbin/sensorlab-backup.sh
ls -lh /home/rui/backups/sensorlab/
```

O backup deve criar um ficheiro `sensorlab-AAAA-MM-DD_HH-MM-SS.dump`. Para confirmar o seu formato, copiar o ficheiro para o contentor e usar `pg_restore --list` (sem restaurar por cima da base ativa).

4. Criar o serviço com `sudo nano /etc/systemd/system/sensorlab-backup.service`:

```ini
[Unit]
Description=Backup automatico PostgreSQL SensorLab
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/sbin/sensorlab-backup.sh
TimeoutStartSec=30min
```

5. Criar o agendamento com `sudo nano /etc/systemd/system/sensorlab-backup.timer`:

```ini
[Unit]
Description=Backup diario PostgreSQL SensorLab

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
Unit=sensorlab-backup.service

[Install]
WantedBy=timers.target
```

6. Ativar o timer e testar a execução do serviço:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sensorlab-backup.timer
sudo systemctl status sensorlab-backup.timer --no-pager
sudo systemctl start sensorlab-backup.service
sudo systemctl status sensorlab-backup.service --no-pager
systemctl list-timers --all --no-pager | grep sensorlab-backup
ls -lht /home/rui/backups/sensorlab/
sudo systemctl is-active fail2ban
```

O timer deve apresentar **`active (waiting)`** e a próxima execução às **03:00**. No serviço `Type=oneshot`, é normal aparecer **`inactive (dead)`** depois de terminar, desde que o resultado seja **`status=0/SUCCESS`**. A regra `-mtime +6` elimina backups automáticos com mais de seis dias completos de idade (aproximadamente uma semana de retenção). Para proteger os dados em caso de perda da VM, guardar também uma cópia dos backups fora do disco virtual.
