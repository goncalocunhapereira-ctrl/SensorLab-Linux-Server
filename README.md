
# SensorLab — Servidor Linux | Grupo 1

## 1. Identificação do Projeto

- **Projeto:** SensorLab
- **Curso:** Redes e Sistemas Informáticos
- **Instituição:** ISTEC Porto
- **Unidade Curricular:** CSSL
- **Autores:** Rui Cunha, Gonçalo Pereira e Guilherme Meirinhos

## 2. Objetivo do Projeto

O objetivo deste projeto é configurar e administrar um servidor Linux, implementando vários serviços de rede, nomeadamente:

- Acesso remoto através de SSH.
- Serviço DHCP utilizando Kea.
- Serviço DNS utilizando BIND9.
- Servidor Web utilizando Nginx.
- Configuração de HTTPS e certificados digitais.

## 3. Ambiente Técnico

| Componente | Configuração |
|---|---|
| Virtualização | Oracle VirtualBox |
| Sistema Operativo | Ubuntu Linux |
| Nome da VM | srv-g1-projeto |
| Utilizador principal | rui |
| Interface de rede | enp0s8 |
| Endereço IP | 192.168.50.1/24 |
| Domínio | grupo1.lab |
| Servidor Web | srv.grupo1.lab |

## 4. Estado dos Requisitos

| Requisito | Estado |
|---|---|
| R1–R4 | Executados na VM |
| R5 | Em curso |
| R6–R8 | Por realizar |
| R9 | Em curso |

## 5. Serviços Implementados

### 5.1 OpenSSH
Serviço responsável por permitir o acesso remoto ao servidor Linux.

### 5.2 Kea DHCP
Serviço responsável pela atribuição automática de endereços IP aos dispositivos da rede.

### 5.3 BIND9
Serviço responsável pela resolução de nomes de domínio na rede local.

### 5.4 Nginx
Servidor Web responsável por disponibilizar a página do projeto SensorLab através de HTTP e HTTPS.

## 6. Testes e Validações

Comandos utilizados para verificar os serviços:

```bash
dig @192.168.50.1 srv.grupo1.lab +short
resolvectl query srv.grupo1.lab
sudo nginx -t
curl -I http://srv.grupo1.lab
curl -kI https://srv.grupo1.lab
```

## 7. Estrutura do Repositório

```text
CSSL-SensorLab-Grupo1/
│
├── README.md
├── config/
│   ├── ssh/
│   ├── kea/
│   ├── bind9/
│   ├── nginx/
│   └── netplan/
│
├── web/
├── scripts/
└── docs/
    ├── testes.md
    └── problemas-resolvidos.md
```

## 8. Responsabilidades

- **Rui Cunha:** Configuração da máquina virtual e testes dos serviços.
- **Gonçalo Pereira:** Gestão do GitHub, README e organização do repositório.
- **Guilherme Meirinhos:** Revisão da documentação e apoio na verificação dos testes.

## 9. Segurança

Não devem ser publicados ficheiros que contenham palavras-passe, chaves privadas SSH, tokens ou outros dados sensíveis.

## 10. Estado do Projeto

A documentação será atualizada ao longo do desenvolvimento, acompanhando a implementação e validação dos diferentes requisitos.
