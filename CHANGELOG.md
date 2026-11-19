# Changelog

Version entries describe release contents. Annotated Git tags and deployment
evidence establish which versions have actually been published and deployed.

## v0.1.0

### Changes

- Establish the first versioned capstone release baseline.
- Add Dockerfile lint, shell script lint, and Trivy image scanning.
- Expand k6 to verify health JSON, homepage content, ticket-row bounds,
  and separate health and homepage latency thresholds.
- Add local pre-commit hooks and fix existing shell lint findings.
- Apply the available zlib package fix in the web image.
- Preserve five-PR check coverage and three intentional failure tests.
- Retain the existing newest-50-ticket homepage behavior.
- Change the declared deployment image from legacy v2 to v0.1.0.
- Update the live checker to compare the declared semantic release image.

Related merged work:
- [PR #23: capstone checks and expanded k6](https://github.com/yakou016/inet4031/pull/23)
- [PR #27: negative-test evidence and QA](https://github.com/yakou016/inet4031/pull/27)

### Candidate validation

The candidate was tested with 10,000 tickets in a disposable database.
All 450 checks passed, with zero HTTP failures.
Homepage p95 was 15.66 ms; health p95 was 3.74 ms.

The full scan reported 47 HIGH findings and no CRITICAL findings.
The filtered gate reported no fixable HIGH/CRITICAL findings.
Unresolved findings remain a risk; this is not a vulnerability-free image.

### Image provenance

Image: docker.io/library/week-4-web:v0.1.0

Application source commit:
56bde4e7eee2ed1c817ffc297216741a5e315e79

The release-configuration commit is recorded by the annotated Git tag.
Image manifests, runtime configuration IDs, and validation results are
recorded in capstone/devsecops-pm/evidence/release-v0.1.0-*.

### Limitations

This is a single-VM lab release, not a production-capacity certification.
Release images are imported locally into k3s; GitHub does not store them.
No database schema or live ticket-data change is part of this release.
