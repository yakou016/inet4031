# Week 8, Security Hardening and Shifting Left

## What this does

- Hardens the workload with OpenTofu: `web` runs as user 10001 with no privilege escalation and no capabilities; both Deployments have CPU and memory limits; a NetworkPolicy lets only `web` pods reach `db`.
- Moves checks left. The deploy gate runs a security scan on every pull request, and a GitHub ruleset (`week-8/ruleset.json`) refuses to merge unless the gate passes.
- Makes the deploy ask first. `week-7/deploy.sh` saves the plan and stops if it would delete or replace anything. I read the plan and run `tofu apply` by hand to approve it.
- Keeps secret files (state, logs) private to my user.

## What lives where

| Where | What | Survives deleting the VM? |
| --- | --- | --- |
| GitHub | The ruleset, the gate | Yes |
| This repository | The OpenTofu files, the deploy script, `ruleset.json` | Yes |
| The VM | File permissions, cron | No |

## Rebuild the VM side

After cloning the repository on a new VM and finishing the Week 7 rebuild steps:

```bash
chmod 600 week-5/terraform.tfstate* ~/deploy.log ~/.deployed-commit
```

If the ruleset is missing on GitHub, recreate it:

```bash
gh api --method POST repos/{owner}/{repo}/rulesets --input week-8/ruleset.json
```

## Check on it

```bash
kubectl exec deploy/web -- id
kubectl get networkpolicy
gh api repos/{owner}/{repo}/rulesets --jq '.[] | "\(.name) \(.enforcement)"'
grep BLOCKED ~/deploy.log | tail -n 3
```

## Known limitations

SSH still accepts passwords, there is no host firewall, and the state file holds secrets in plain text. The cron job runs as my own user. `web` can write to its filesystem, and `db` runs as root inside its container. The scan covers six rules in `week-5/` only, and the ruleset can be deleted by anyone with admin rights on the repository.
