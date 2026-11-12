#!/usr/bin/env bash
# Check this week's setup and print PASS or FAIL for each item.
set -u

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
failed=0
ok()  { echo "PASS  $*"; }
bad() { echo "FAIL  $*"; failed=1; }

q() {
  printf '%s\n' "$1" | kubectl exec -i deploy/db -- sh -c \
    'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -tA' 2>/dev/null
}

if command -v k6 >/dev/null 2>&1; then
  ok "k6 is installed"
else
  bad "k6 is not installed"
fi

preload="$(q 'SHOW shared_preload_libraries' || true)"
ext="$(q "SELECT count(*) FROM pg_extension WHERE extname = 'pg_stat_statements'" || true)"
if [[ "$preload" == *pg_stat_statements* && "$ext" == 1 ]]; then
  ok "pg_stat_statements is loaded and created"
else
  bad "pg_stat_statements is not set up (loaded: '$preload', created: '$ext')"
fi

idx="$(q "SELECT count(*) FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'tickets' AND indexname = 'idx_tickets_status_created'" || true)"
if [ "$idx" = 1 ]; then
  ok "the index idx_tickets_status_created exists"
else
  bad "the index idx_tickets_status_created does not exist on public.tickets"
fi

ip="$(kubectl get service web -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"
if [ -n "$ip" ] && page="$(curl -fsS --max-time 30 "http://${ip}:8080/")"; then
  rows="$(printf '%s\n' "$page" | grep -c '<tr class="status-' || true)"
  if [ "$rows" -gt 0 ] && [ "$rows" -le 50 ]; then
    ok "the live page shows $rows tickets (at most 50)"
  else
    bad "expected 1–50 ticket rows on the live page, found $rows"
  fi
else
  bad "the live page did not answer successfully"
fi

live_cpu="$(kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)"
live_image="$(kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [ "$live_cpu" = "500m" ] && grep -Eq '^[[:space:]]*cpu[[:space:]]*=[[:space:]]*"500m"' "$ROOT/week-5/web.tf"; then
  ok "the web CPU limit is 500m in the cluster and in week-5/web.tf"
else
  bad "expected a 500m CPU limit in the cluster and in week-5/web.tf (live: '$live_cpu')"
fi

if [[ "$live_image" == "week-4-web:v2" || "$live_image" == */week-4-web:v2 ]] &&
   grep -Fq 'week-4-web:v2' "$ROOT/week-5/web.tf"; then
  ok "web runs the v2 image, in the cluster and in week-5/web.tf"
else
  bad "expected week-4-web:v2 in the cluster and in week-5/web.tf (live: '$live_image')"
fi

( cd "$ROOT/week-5" && tofu plan -input=false -detailed-exitcode >/dev/null 2>&1 )
rc=$?
case "$rc" in
  0) ok "tofu plan finds no drift" ;;
  2) bad "tofu plan shows drift" ;;
  *) bad "tofu plan could not run (exit code $rc)" ;;
esac

if [ -f "$ROOT/.github/workflows/load-test.yml" ] &&
   grep -Fq 'p(95)<500' "$HERE/smoke-test.js"; then
  ok "the load-test workflow and smoke-test p95 threshold are in the repository"
else
  bad "load-test.yml or the smoke-test p95 threshold is missing"
fi

p95="$("$HERE/k6-stat.sh" restored p95 2>/dev/null || true)"
if [[ "$p95" =~ ^[0-9]+$ ]] && [ "$p95" -lt 500 ]; then
  ok "the saved restored ramped test had a p95 of $p95 ms"
else
  bad "no saved restored ramped test under 500 ms (p95: '${p95:-none}')"
fi

if [ "$failed" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
  exit 1
fi
