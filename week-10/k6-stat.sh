#!/usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <label> <p50|p95|rps>" >&2
  exit 2
fi

python3 - "$HOME/.k6-$1.json" "$2" <<'PY'
import json, sys

with open(sys.argv[1]) as f:
    metrics = json.load(f)["metrics"]

values = {
    "p50": f"{metrics['http_req_duration']['med']:.0f}",
    "p95": f"{metrics['http_req_duration']['p(95)']:.0f}",
    "rps": f"{metrics['http_reqs']['rate']:.1f}",
}
if sys.argv[2] not in values:
    sys.exit("Pick one of: p50, p95, rps")
print(values[sys.argv[2]])
PY
