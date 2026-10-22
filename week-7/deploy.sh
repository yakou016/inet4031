#!/usr/bin/env bash
# Pull-based deploy. If origin/master has a commit this VM has not deployed yet,
# and the deploy gate on GitHub passed for that exact commit, bring this folder
# up to date and apply it to the cluster. Safe to run by hand or from cron.
# Usage: ./week-7/deploy.sh

set -eu

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
export GIT_TERMINAL_PROMPT=0
export GH_PROMPT_DISABLED=1
export GH_NO_UPDATE_NOTIFIER=1
export TF_IN_AUTOMATION=1

REPO="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$HOME/.deployed-commit"
cd "$REPO"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }
trap 'log "FAILED. Nothing was recorded, so the next run tries again."' ERR

exec 9>"$HOME/.deploy.lock"
if ! flock -n 9; then
  log "another deploy is running, skipping"
  exit 0
fi

if ! git fetch --quiet origin master; then
  log "WAITING: could not reach GitHub"
  exit 0
fi

NEW="$(git rev-parse origin/master)"
OLD="$(cat "$STATE" 2>/dev/null || true)"

if [ "$NEW" = "$OLD" ]; then
  log "up to date at ${NEW:0:7}"
  exit 0
fi

log "new commit ${NEW:0:7} on origin/master"

if ! gate="$(gh api "repos/{owner}/{repo}/actions/workflows/deploy-gate.yml/runs?head_sha=$NEW" \
    --jq '(.workflow_runs[0] // empty) | "\(.status) \(.conclusion)"')"; then
  log "WAITING: could not read the gate result (no network, or gh is not logged in)"
  exit 0
fi

case "$gate" in
  "completed success")
    log "the gate passed" ;;
  "")
    log "WAITING: the gate has not started for ${NEW:0:7}"
    exit 0 ;;
  "completed "*)
    log "BLOCKED: the gate finished as ${gate#completed } for ${NEW:0:7}. A new commit that passes, or a re-run on GitHub, unblocks it."
    exit 1 ;;
  *)
    log "WAITING: the gate is still running ($gate)"
    exit 0 ;;
esac

if ! kubectl get nodes >/dev/null 2>&1; then
  log "WAITING: the cluster is not answering yet (is k3s running?)"
  exit 0
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" != "master" ]; then
  log "SKIPPED: this folder is on '$branch', not master"
  exit 1
fi

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  log "SKIPPED: tracked files have uncommitted changes"
  git status --short --untracked-files=no
  exit 1
fi

if ! git merge --ff-only --quiet origin/master || [ "$(git rev-parse HEAD)" != "$NEW" ]; then
  log "SKIPPED: this folder has commits that are not on origin/master"
  exit 1
fi

log "deploying ${NEW:0:7}"

log "step 1 of 2: tofu apply in week-5"
(
  cd week-5
  tofu init -input=false
  tofu apply -auto-approve -input=false -lock-timeout=60s
)

log "step 2 of 2: helm upgrade for prometheus"
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts \
  --force-update
helm repo update prometheus-community

helm upgrade --install prometheus prometheus-community/prometheus \
  --version 29.35.0 \
  --namespace monitoring \
  --create-namespace \
  --values week-6/prometheus-values.yaml \
  --wait \
  --rollback-on-failure \
  --timeout 5m

echo "$NEW" > "$STATE"
log "deployed ${NEW:0:7}"
