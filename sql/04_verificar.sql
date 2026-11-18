-- =====================================================================
-- SensorLab · 04 · Verificação (evidência do requisito R6)
--     psql -d sensorlab -f 04_verificar.sql
-- =====================================================================
\echo '--- Registos importados'
SELECT (SELECT count(*) FROM api.atividades) AS atividades,
       (SELECT count(*) FROM api.leituras)   AS leituras,
       (SELECT count(DISTINCT participante) FROM api.leituras) AS participantes;

\echo '--- Resumo por atividade'
SELECT * FROM api.resumo;

\echo '--- Teste de permissões como web_anon (o papel da API)'
SET ROLE web_anon;
SELECT count(*) AS web_anon_consegue_ler FROM api.atividades;
DO $$
BEGIN
    INSERT INTO api.atividades VALUES ('Z', 'teste');
    RAISE EXCEPTION 'FALHA: o web_anon conseguiu escrever!';
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK: escrita recusada ao web_anon (%)', SQLERRM;
END $$;
RESET ROLE;
