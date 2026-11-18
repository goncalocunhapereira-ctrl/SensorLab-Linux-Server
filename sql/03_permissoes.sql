-- =====================================================================
-- SensorLab · 03 · Utilizadores da API (só leitura)
-- Executar como administrador, indicando a palavra-passe do utilizador
-- que o PostgREST vai usar (só letras e algarismos):
--     psql -d sensorlab -v senha_api='Troca3staSenha' -f 03_permissoes.sql
--
--   authenticator  -> faz login (é o que o PostgREST usa para se ligar)
--   web_anon       -> não faz login; tem só SELECT no esquema api
--   O PostgREST liga-se como authenticator e muda para web_anon em cada pedido.
-- =====================================================================
\set ON_ERROR_STOP on

\if :{?senha_api}
\else
  \echo 'ERRO: falta indicar a palavra-passe: -v senha_api=...'
  \quit
\endif

-- Criar os papéis apenas se ainda não existirem (o script pode ser repetido)
SELECT 'CREATE ROLE web_anon NOLOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'web_anon') \gexec

SELECT 'CREATE ROLE authenticator LOGIN NOINHERIT NOCREATEDB NOCREATEROLE NOSUPERUSER'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') \gexec

ALTER ROLE authenticator WITH PASSWORD :'senha_api';
GRANT web_anon TO authenticator;

-- Menor privilégio: o web_anon só pode LER o esquema api
GRANT CONNECT ON DATABASE :"DBNAME" TO authenticator;
GRANT USAGE ON SCHEMA api TO web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO web_anon;   -- inclui a vista resumo
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA api FROM web_anon;
