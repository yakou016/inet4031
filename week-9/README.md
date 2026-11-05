# Week 9: Database Monitoring and Backups

I added a Postgres exporter so Prometheus can show whether the database is reachable, its size, and an estimated ticket count. The NetworkPolicy allows the web app and exporter to connect to Postgres. The exporter runs as a non-root user with resource limits.

`week-9/backup.sh` saves a checked database dump in `~/backups` every five minutes through cron and keeps the newest 12. I also copied one dump to my Windows computer and confirmed its SHA-256 hash matched. `sql.sh` helps inspect the database, `restore.sh` requires an explicit backup and confirmation, and `check.sh` checks the running setup.

## Recovery drill

I backed up a database with 3 tickets, dropped the `public` schema, and confirmed there were no tables. I restored from `/home/anthonyyakoub/backups/db-20261105-000043.dump`. Afterward, `public.tickets` and all 3 tickets were back.

- Backup age when measured: 1 second (the target is 5 minutes).
- Measured time from starting the wipe through restoration: 25 seconds (the target is 10 minutes).
- `pg_up` remained 1 because Postgres stayed online. The table metric still showed 3 immediately after the wipe; Prometheus had not scraped the deletion yet. That output does not prove it detected the missing table.

## If the tickets disappear

1. Check the database with `./week-9/sql.sh '\dt'` and `./week-9/sql.sh`.
2. Check `ls -lt ~/backups/db-*.dump` and choose a backup from before the loss. Do not assume the newest one is the right one.
3. Inspect the selected file with `kubectl exec -i deploy/db -- pg_restore --list < /path/to/backup.dump`.
4. Restore deliberately with `./week-9/restore.sh /path/to/backup.dump`, then verify the ticket count and the website.

The scripts and OpenTofu configuration are in GitHub. The database volume, cron entry, and VM backups are not. My separately copied dump survives losing the VM, but that copy is only as recent as my last manual transfer.

Limitations: backups are not encrypted, off-VM copying is manual, and no alert tells me when backups stop or `pg_up` changes. The exporter uses the existing database credentials instead of a dedicated read-only account. This drill tested restoration on the same VM, not rebuilding onto a new one.
