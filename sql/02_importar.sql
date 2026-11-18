-- =====================================================================
-- SensorLab · 02 · Importar o dataset
-- Executar NA PASTA ONDE ESTÃO OS CSV (os caminhos são relativos):
--     cd data
--     psql -d sensorlab -f ../sql/02_importar.sql
-- O \copy lê os ficheiros do lado do cliente (psql), por isso não é
-- preciso dar permissões ao utilizador postgres sobre a pasta.
-- =====================================================================
\set ON_ERROR_STOP on

-- Recomeçar do zero se o script for corrido mais do que uma vez
TRUNCATE api.leituras, api.atividades;

\copy api.atividades (codigo, nome) FROM 'atividades.csv' WITH (FORMAT csv, HEADER true)
\copy api.leituras (participante, atividade, instante, x, y, z) FROM 'wisdm_accel_phone.csv' WITH (FORMAT csv, HEADER true)

-- Atualizar as estatísticas usadas pelo planeador de consultas
ANALYZE api.atividades;
ANALYZE api.leituras;

SELECT count(*) AS leituras_importadas FROM api.leituras;
