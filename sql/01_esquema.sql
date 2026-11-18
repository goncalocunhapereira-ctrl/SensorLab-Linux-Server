-- =====================================================================
-- SensorLab · 01 · Esquema da base de dados
-- Cria o esquema "api" com as tabelas do dataset WISDM e uma vista de resumo.
-- Executar como administrador da base de dados:
--     psql -d sensorlab -f 01_esquema.sql
-- =====================================================================
\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS api;

-- Lista das atividades (A = walking, B = jogging, ...)
CREATE TABLE IF NOT EXISTS api.atividades (
    codigo  char(1) PRIMARY KEY,
    nome    text    NOT NULL
);

-- Uma linha por leitura do sensor (20 por segundo)
CREATE TABLE IF NOT EXISTS api.leituras (
    id            bigint   GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    participante  smallint NOT NULL,
    atividade     char(1)  NOT NULL REFERENCES api.atividades (codigo),
    instante      bigint   NOT NULL,   -- contador de tempo do sensor (não é uma data)
    x             real     NOT NULL,
    y             real     NOT NULL,
    z             real     NOT NULL
);

-- Acelera as consultas mais comuns da API (?participante=eq.1600&atividade=eq.A)
CREATE INDEX IF NOT EXISTS leituras_part_ativ_idx
    ON api.leituras (participante, atividade);

-- Resumo por atividade: quantas leituras, quantos participantes e a
-- intensidade média do movimento (magnitude do vetor x, y, z)
CREATE OR REPLACE VIEW api.resumo AS
SELECT a.codigo,
       a.nome,
       count(l.id)                                          AS leituras,
       count(DISTINCT l.participante)                       AS participantes,
       round(avg(sqrt(l.x^2 + l.y^2 + l.z^2))::numeric, 2)  AS magnitude_media
FROM api.atividades a
LEFT JOIN api.leituras l ON l.atividade = a.codigo
GROUP BY a.codigo, a.nome
ORDER BY a.codigo;

COMMENT ON TABLE api.leituras IS
  'WISDM (G. Weiss, UCI ML Repository, 2019, CC BY 4.0) - doi:10.24432/C5HK59';
