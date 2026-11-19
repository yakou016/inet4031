#!/usr/bin/env bash
set -euo pipefail

# CI can override this path; local development uses the existing virtualenv.
venv="${DEVSECOPS_VENV:-$HOME/devsecops-pm-venv}"
exec "$venv/bin/yamllint" -c .yamllint.yaml "$@"
