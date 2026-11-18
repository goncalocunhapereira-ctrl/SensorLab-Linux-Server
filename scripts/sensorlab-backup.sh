#!/usr/bin/env bash
# Cópia de segurança da base de dados PostgreSQL do Compose (R8).
# Esta é uma versão RECONSTRUÍDA a partir do procedimento; verificar na VM real antes de substituir o script já instalado.
set -Eeuo pipefail
umask 077

COMPOSE_DIR="/home/rui/2_entregar_aos_grupos/compose"
DESTINO="/home/rui/backups/sensorlab"
DATA="$(date +%Y-%m-%d_%H-%M-%S)"
ARQUIVO="$DESTINO/sensorlab-$DATA.dump"
PARCIAL="$ARQUIVO.part"
DUMP_INTERNO="/tmp/sensorlab-backup.dump"

mkdir -p "$DESTINO"
chmod 700 "$DESTINO"
cd "$COMPOSE_DIR"

# Nunca apagar o dump anterior se esta execução falhar.
cleanup() {
    rm -f "$PARCIAL"
}
trap cleanup EXIT

CONTAINER_ID="$(/usr/bin/docker compose ps -q db)"
if [[ -z "$CONTAINER_ID" ]]; then
    echo "ERRO: contentor db não está em execução" >&2
    exit 1
fi

/usr/bin/docker compose exec -T db sh -c \
  'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc -f /tmp/sensorlab-backup.dump'
/usr/bin/docker cp "$CONTAINER_ID:$DUMP_INTERNO" "$PARCIAL"
/usr/bin/docker compose exec -T db rm -f "$DUMP_INTERNO"

test -s "$PARCIAL"
chmod 600 "$PARCIAL"
chown rui:rui "$PARCIAL"
mv -f "$PARCIAL" "$ARQUIVO"

echo "Backup concluído: $ARQUIVO"
ls -lh "$ARQUIVO"

# Retém aproximadamente 7 dias (apaga backups automáticos após 7 dias completos).
# Não afeta teste.dump, apenas sensorlab-*.dump.
find "$DESTINO" -maxdepth 1 -type f -name 'sensorlab-*.dump' -mtime +6 -delete
