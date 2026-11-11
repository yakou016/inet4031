#!/usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <test-file> <label>" >&2
  exit 2
fi

TEST="$1"
LABEL="$2"
OUT="$HOME/.k6-$LABEL.json"
TMP_OUT="$(mktemp "$HOME/.k6-$LABEL.XXXXXX")"
trap 'rm -f -- "$TMP_OUT"' EXIT

IP="$(kubectl get service web -o jsonpath='{.spec.clusterIP}')"
export BASE_URL="http://${IP}:8080"

status=0
k6 run --quiet --no-color --summary-export="$TMP_OUT" "$TEST" || status=$?

python3 - "$TMP_OUT" "$LABEL" <<'PY'
import json, sys

with open(sys.argv[1]) as f:
    metrics = json.load(f)["metrics"]

duration = metrics["http_req_duration"]
requests = metrics["http_reqs"]
kb = metrics["data_received"]["count"] / max(requests["count"], 1) / 1024
failed = metrics["http_req_failed"]["value"] * 100

print(f"{sys.argv[2]}: p50 {duration['med']:.0f} ms | "
      f"p95 {duration['p(95)']:.0f} ms | {requests['rate']:.1f} requests/s | "
      f"{failed:.1f}% failed | {kb:.0f} KB per response")
PY

mv -- "$TMP_OUT" "$OUT"
if [ "$status" -eq 0 ]; then
  echo "Thresholds: all passed."
else
  echo "k6 exited with code $status. Check the output above for the cause."
fi
exit "$status"
