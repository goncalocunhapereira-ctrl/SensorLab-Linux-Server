#!/bin/bash
# =====================================================================
# Corre automaticamente UMA vez: no primeiro arranque do contentor db,
# quando o volume de dados ainda está vazio. Para repetir:
#     docker compose down -v      (ATENÇÃO: apaga a base de dados)
#     docker compose up -d
# =====================================================================
set -euo pipefail

echo ">> SensorLab: a criar o esquema, importar o dataset e criar os utilizadores da API"
(
  cd /data
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /sql/01_esquema.sql
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /sql/02_importar.sql
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v senha_api="$PGRST_SENHA" -f /sql/03_permissoes.sql
)
echo ">> SensorLab: concluído"
