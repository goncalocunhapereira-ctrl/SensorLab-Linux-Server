-- Extra opcional: conta apenas de leitura para as consultas do Grafana.
\set ON_ERROR_STOP on
SELECT 'CREATE ROLE grafana_reader LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'grafana_reader') \gexec
GRANT CONNECT ON DATABASE sensorlab TO grafana_reader;
GRANT USAGE ON SCHEMA api TO grafana_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO grafana_reader;
-- A palavra-passe NÃO é incluída: atribuir com \password grafana_reader no psql.
