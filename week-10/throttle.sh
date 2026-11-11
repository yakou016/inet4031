#!/usr/bin/env bash
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <label>" >&2
  exit 2
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
QUERY='sum(rate(container_cpu_cfs_throttled_periods_total{container="web"}[3m])) / sum(rate(container_cpu_cfs_periods_total{container="web"}[3m]))'
answer="$("$HERE/../week-6/pq.sh" "$QUERY")"
value="$(printf '%s\n' "$answer" | awk '/->/ {print $NF; exit}')"

percent="$(python3 - "$value" <<'PY'
import math, sys

try:
    value = float(sys.argv[1])
except ValueError:
    sys.exit("No CPU-period data. Check the Prometheus port-forward and scrape window.")

if not math.isfinite(value):
    sys.exit("No measurable CPU periods in this window. Retry after running the test.")
print(round(value * 100))
PY
)"

printf '%s\n' "$percent" > "$HOME/.throttle-$1"
printf '%s: web CPU throttled in %s%% of CPU periods\n' "$1" "$percent"
