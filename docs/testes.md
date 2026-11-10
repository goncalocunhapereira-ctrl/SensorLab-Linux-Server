
# Testes do Projeto SensorLab

## 1. Objetivo

Registar os testes realizados aos serviços implementados no servidor Linux.

## 2. Testes DNS

Comando:

```bash
dig @192.168.50.1 srv.grupo1.lab +short
```

Objetivo: Verificar a resolução do domínio do servidor.

Resultado esperado: 192.168.50.1

## 3. Testes Nginx

Comando:

```bash
sudo nginx -t
```

Objetivo: Verificar a configuração do Nginx.

## 4. Testes HTTP

Comando:

```bash
curl -I http://srv.grupo1.lab
```

Resultado validado: Código HTTP 301, com redirecionamento para HTTPS.

## 5. Testes HTTPS

Comando:

```bash
curl -kI https://srv.grupo1.lab
```

Resultado validado: Código HTTP 200.

## 6. Verificação da página Web

Comando:

```bash
curl -ks https://srv.grupo1.lab | grep SensorLab
```

Resultado validado: A página apresenta o conteúdo SensorLab — Grupo 1.

## 7. Testes Pendentes

- Testar DHCP a partir de uma VM cliente.
- Testar resolução DNS a partir de uma VM cliente.
- Testar acesso HTTPS a partir de uma VM cliente.
- Registar os resultados reais dos testes.
