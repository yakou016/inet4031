#!/usr/bin/env bash
# Quick checks for the database, exporter, and backups.
set -u

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

failed=0
ok()  { echo "PASS  $*"; }
bad() { echo "FAIL  $*"; failed=1; }

if kubectl exec deploy/db -- sh -c \
  'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null 2>&1; then
  ok "database accepts connections"
else
  bad "database does not accept connections"
fi

metrics="$(kubectl exec deploy/web -- python -c \
  "import urllib.request; print(urllib.request.urlopen('http://db-exporter:9187/metrics').read().decode())" 2>/dev/null || true)"
if printf '%s\n' "$metrics" | grep -q '^pg_up 1'; then
  ok "exporter reaches the database"
else
  bad "exporter is unavailable or pg_up is not 1"
fi

newest="$(ls -1t "$HOME"/backups/db-*.dump 2>/dev/null | head -n 1 || true)"
if [ -z "$newest" ]; then
  bad "no database backups found"
else
  age=$(( $(date +%s) - $(stat -c %Y "$newest") ))
  if [ "$age" -le 900 ]; then
    ok "newest backup is $age seconds old"
  else
    bad "newest backup is over 15 minutes old"
  fi

  if kubectl exec -i deploy/db -- pg_restore --list < "$newest" 2>/dev/null |
    grep -q ' TABLE DATA public tickets '; then
    ok "newest backup lists ticket data"
  else
    bad "newest backup is unreadable or lacks ticket data"
  fi
fi

if crontab -l 2>/dev/null | grep -q 'week-9/backup.sh'; then
  ok "backup cron entry exists"
else
  bad "backup cron entry is missing"
fi

if [ "$failed" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
  exit 1
fi
