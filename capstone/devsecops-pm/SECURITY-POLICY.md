# Container vulnerability policy

## Scope

Scan the web application image with Trivy before release.
This supplements the existing Checkov infrastructure scan.

## Pass and fail rules

- Scan operating-system and application dependencies.
- Fail the security job for HIGH or CRITICAL findings with an available fix.
- Scanner errors must fail the job.
- Retain an unfiltered HIGH/CRITICAL report as well as the filtered gate report.
- Do not silently ignore individual vulnerabilities.

The new check starts as non-required while we test it on real pull requests.
A non-required check can still fail; it simply does not block merging yet.
Existing required checks remain unchanged.

## Initial results

The baseline image reported 48 HIGH findings and no CRITICAL findings.
After applying the zlib package fix, the rebuilt image reported 47 HIGH
findings and no CRITICAL findings.

The filtered scan reported no fixable HIGH/CRITICAL findings.
The remaining findings are not resolved just because the gate passes.
These results describe the scanned images, not the live v2 deployment.

Evidence:
- evidence/trivy-baseline.txt
- evidence/trivy-patched-full.txt
- evidence/trivy-patched-gate.txt

## Remaining risk

Owner: Anthony Yakoub.

Review the remaining findings at the next weekly checkpoint and before
each release. Record available fixes, mitigation decisions, and any
exceptions in the risk register. Rebuild and rescan when fixes become
available.

A passing scan is not proof that the application is secure.
