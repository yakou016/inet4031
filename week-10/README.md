# Week 10: End-to-End Performance Investigation

## What this does

- The k6 smoke and ramped tests measure the web app under load. `run-k6.sh` runs them against the web Service, and `k6-stat.sh` reads the saved results.
- `pg_stat_statements` shows how often Postgres runs a query, how long it takes, and how many rows it returns. `sql.sh` runs SQL in the database pod, and `throttle.sh` queries Prometheus for CPU throttling.
- `./week-10/check.sh` verifies the live setup, the repository configuration, and the saved recovery result.

## What lives where

| Where | What | Survives deleting the VM? |
| --- | --- | --- |
| GitHub | App and OpenTofu changes, test scripts, workflow, and this runbook | Yes |
| VM and database | Local k6 results, the imported v2 image, and the index created by hand | No |
| Prometheus | CPU, memory, and throttling history | No; this setup also loses history if the Prometheus pod restarts |

## Runbook 1: The home page loads every ticket

- **Symptom:** With 10,003 tickets in the database, the smoke test missed the 500 ms p95 target. A single homepage response was about 7.28 MB.
- **Diagnosis:** `pg_stat_statements` showed 10,003 rows per homepage query. `EXPLAIN (ANALYZE, BUFFERS)` showed the query already used the primary-key index and took 2.184 ms in that run. The problem was asking the web app to render and send every row.
- **Fix:** Add `LIMIT 50` in `week-4/app/app.py`, rebuild and import `week-4-web:v2`, and deploy it through OpenTofu. Rerun the same smoke test with the seeded rows still present.
- **Measured:** p95 went from 4370 ms to 18 ms. The homepage response dropped to 37,875 bytes in the curl check. Prometheus showed 96% of web CPU periods were throttled in the separate unbounded run.
- **Separate index test:** For the query that selects the 10 newest open tickets, adding `idx_tickets_status_created` changed a sequential scan and sort to an index scan. Execution time went from 1.598 ms to 0.047 ms. This index was not the homepage fix.

## Runbook 2: The web CPU limit is too low

- **Symptom:** With the web CPU limit manually lowered to 50m, the ramped test slowed down and requests started failing. I stopped that run after seeing connection refusals; 85 of 545 requests failed.
- **Diagnosis:** Compare the live Deployment's CPU limit with `week-5/web.tf`. `tofu plan` showed the manual change as drift. Use Prometheus to measure the share of CPU periods that were throttled.
- **Fix:** Restore the declared 500m limit with OpenTofu, verify the live limit and rollout, and rerun the ramped test.
- **Measured:** At 50m, the interrupted run had a p95 of 3185 ms. A historical three-minute Prometheus query showed about 78% throttled periods. At 500m, the full rerun had a p95 of 17 ms, 2% throttled periods, and zero failed requests.

## Regression check

The GitHub Actions workflow starts a disposable stack, seeds 10,000 tickets, and checks for p95 under 500 ms and an HTTP failure rate under 1%. It passed on PR #20. On PR #21, removing `LIMIT 50` pushed p95 to 1.22 seconds even though all 58 requests returned HTTP 200. PR #21 was closed without merging.

## Known limitations

The homepage has no pagination beyond the newest 50 tickets. The index was created manually and is not managed in Git. Local load tests share the VM with the app, and the GitHub check is not required for merging or able to detect live cluster drift.
