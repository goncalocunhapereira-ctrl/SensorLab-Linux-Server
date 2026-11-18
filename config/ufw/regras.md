# Regras UFW — SensorLab (R2/R3/R4/R5)

Reproduzir no servidor **pela consola VirtualBox ou após confirmar acesso SSH por chave**. Abrir a porta 22 antes de ativar a firewall:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow in on enp0s8 to any port 67 proto udp
sudo ufw allow in on enp0s8 to any port 53 proto udp
sudo ufw allow in on enp0s8 to any port 53 proto tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status verbose
```

O Docker Compose do R7 **não publica** a porta 5432. Publica 3000 e 3001 **apenas em 127.0.0.1**. Não abrir estas portas na UFW. Para acesso à API a partir da `labnet`, usar o Nginx em 443/TCP (`/api/`).

> Caso a interface da rede interna não seja `enp0s8`, adaptar as regras. A lista acima é uma política de reconstrução fiel à arquitetura, não um export literal de `ufw status numbered` da VM.
