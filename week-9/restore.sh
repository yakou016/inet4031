#!/usr/bin/env bash
# Manual database restore. Usage: ./week-9/restore.sh /path/to/backup.dump
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

if [ "$#" -ne 1 ] || [ ! -s "$1" ]; then
  echo "Usage: $0 /path/to/existing/backup.dump" >&2
  exit 1
fi

FILE="$1"
kubectl exec -i deploy/db -- pg_restore --list < "$FILE" |
  grep -q ' TABLE DATA public tickets ' || {
    echo "Backup does not list ticket data; refusing to restore." >&2
    exit 1
  }

echo "WARNING: This will replace the current database contents using $FILE"
read -r -p 'Type RESTORE to continue: ' answer
[ "$answer" = "RESTORE" ] || { echo "Cancelled."; exit 1; }

kubectl exec -i deploy/db -- sh -c \
  'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner --exit-on-error' < "$FILE"

"$(dirname "$0")/sql.sh"
