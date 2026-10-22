# Week 7, Continuous Delivery

## What this does

- `.github/workflows/deploy-gate.yml` runs on every push to `master` on GitHub's machines. One job checks the OpenTofu files in `week-5/`, and the other renders the Prometheus chart using `week-6/prometheus-values.yaml`.
- `week-7/deploy.sh` checks GitHub for a new commit on `master`. If the gate passed for that exact commit, it runs `tofu apply` for the application and `helm upgrade --install` for Prometheus.
- A cron job runs the script every two minutes. The VM connects out to GitHub; GitHub never connects into the VM. If the VM was off, its first run after boot catches up.
- A guard refuses to deploy if the working copy is not on `master`, contains uncommitted tracked changes, or contains commits that are not on GitHub.
- The repository is public, and no GitHub workflow runs directly on the VM.

## Requirements

- The Week 5 application and Week 6 Prometheus installation running on k3s
- `tofu`, `helm`, `kubectl`, and an authenticated `gh` installation
- The cron service running with a schedule for `week-7/deploy.sh`

## Deploy

Merge a pull request, wait for the deployment gate, and allow up to two minutes for cron. To deploy immediately, run:

    ./week-7/deploy.sh

## Roll back

Revert the merge commit, open a pull request containing the revert, and merge it:

    git revert -m 1 <merge-commit>

The angle-bracket value is a placeholder that must be replaced with an actual merge commit hash.

## Check on the pipeline

    crontab -l
    tail -n 20 ~/deploy.log
    gh run list --workflow deploy-gate.yml --limit 3

## Rebuild on a fresh VM

The cron entry, last-deployed record, and `week-5/terraform.tfvars` live on the VM rather than in this repository.

1. Install k3s, OpenTofu, Helm, and `gh`, then authenticate with `gh auth login`.
2. Clone the repository.
3. Copy `week-5/terraform.tfvars.example` to `week-5/terraform.tfvars` and provide real values.
4. Import the `week-4-web` image into k3s.
5. Run `./week-7/deploy.sh`.
6. Add the deployment schedule from the repository root:

       ( crontab -l 2>/dev/null; echo "*/2 * * * * $PWD/week-7/deploy.sh >> $HOME/deploy.log 2>&1" ) | crontab -

## Known limitations

The deployment runs from a folder that I also edit, while the OpenTofu state and variable values live on one VM. Nothing requires human approval before `tofu apply` runs, and the gate only detects problems covered by its checks. The cron job runs as my user, so anything that reaches `master` and passes the gate can run commands with my permissions.
