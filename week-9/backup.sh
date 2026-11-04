#!/usr/bin/env bash
set -Eeuo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
umask 077

BACKUPS="$HOME/backups"
KEEP=12
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }

exec 9>"$HOME/.backup.lock"
if ! flock -n 9; then
  log "Another backup is running; skipping"
  exit 0
fi

if ! kubectl get nodes --request-timeout=10s >/dev/null 2>&1 ||
   ! kubectl wait --for=condition=Ready pod -l app=db --timeout=30s >/dev/null 2>&1; then
  log "WAITING: cluster or database is not ready"
  exit 0
fi

rows() {
  kubectl exec deploy/db -- sh -c \
    'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -v ON_ERROR_STOP=1 -c "SELECT COUNT(*) FROM public.tickets;"'
}

before="$(rows)"
if [[ ! "$before" =~ ^[1-9][0-9]*$ ]]; then
  log "SKIPPED: tickets is missing or empty; keeping existing backups"
  exit 1
fi

mkdir -p "$BACKUPS"
chmod 700 "$BACKUPS"
FILE="$BACKUPS/db-$(date +%Y%m%d-%H%M%S).dump"
PARTIAL="$FILE.partial"
trap 'rm -f -- "$PARTIAL"' EXIT

kubectl exec deploy/db -- sh -c \
  'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom' > "$PARTIAL"

listing="$(kubectl exec -i deploy/db -- pg_restore --list < "$PARTIAL")"
if [[ "$listing" != *" TABLE DATA public tickets "* ]]; then
  log "FAILED: archive has no tickets table data entry"
  exit 1
fi

kubectl exec -i deploy/db -- pg_restore --data-only --file=/dev/null < "$PARTIAL"

after="$(rows)"
if [ "$after" != "$before" ]; then
  log "SKIPPED: ticket count changed during backup; retry later"
  exit 1
fi

mv -- "$PARTIAL" "$FILE"
ls -1t "$BACKUPS"/db-*.dump | tail -n +$((KEEP + 1)) | xargs -r rm --
log "Backed up $before tickets to $FILE"
