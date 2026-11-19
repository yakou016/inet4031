# Capstone QA report

Author and tester: Anthony Yakoub
Track: DevSecOps and IT Project Management
Status: Working report; final signoff pending.

Evidence paths below are relative to capstone/devsecops-pm/evidence/.

## Test cases

1. Existing protection
   Expect protect-master to remain active with the original three required
   checks: tofu fmt and validate, render the Prometheus chart, and security scan.
   Result: verified at the current checkpoint; final verification pending.
   New capstone checks remain non-required.
   Evidence: branch-protection.txt.

2. Clean local checks
   Run pre-commit run --all-files and expect exit code 0.
   Result: ShellCheck, Hadolint, and YAML lint passed locally.
   Evidence: pre-commit-clean.txt and pre-commit-with-ci.txt.

3. Local rejection
   Attempt a commit containing deliberately invalid shell syntax.
   Expect ShellCheck to reject it and Git HEAD to remain unchanged.
   Result: commit rejected; HEAD unchanged.
   Evidence: hook-rejection.txt.

4. Dockerfile CI gate
   Add RUN cd /app on an isolated test branch.
   Expect Dockerfile lint to fail and close the PR without merging.
   Result: PR #24 failed with DL3003 and SC2164; six other checks passed.
   PR #24 was closed without merging.
   Evidence: dockerfile-gate.txt and dockerfile-gate-failure.txt.

5. Shell CI gate
   Add a shell script with a missing fi on an isolated test branch.
   Expect shell script lint to fail and close the PR without merging.
   Result: PR #25 failed with shell syntax errors including SC1046 and
   SC1072. The xargs pipeline exited 123; six other checks passed.
   PR #25 was closed without merging.
   Evidence: shell-gate.txt and shell-gate-failure.txt.

6. Additional security scan
   Scan the web image with Trivy and apply the documented security policy.
   Result: the local baseline had 48 HIGH findings and no CRITICAL findings.
   The zlib patch reduced the local full report to 47 HIGH findings.
   The filtered gate found no fixable HIGH/CRITICAL findings.
   The container vulnerability scan passed on PR #23.
   Remaining findings are unresolved risk, not a vulnerability-free result.
   Evidence: trivy-baseline.txt, trivy-patched-full.txt,
   trivy-patched-gate.txt, and pr-23-container-scan/.
   Policy: capstone/devsecops-pm/SECURITY-POLICY.md.
   These scans do not establish that the live v2 image contains the patch.

7. Expanded performance gate
   Verify health JSON, homepage content, bounded ticket rows, and separate
   health and homepage latency thresholds.
   Good result: PR #23 passed all 450 checks with zero HTTP failures.
   Homepage p95 was 12.28 ms; health p95 was 2.55 ms.
   Negative result: PR #26 returned incorrect health JSON while HTTP status
   checks and latency thresholds passed. All 90 health-content checks failed.
   Overall check success was 80%; k6 exited 99 on the checks threshold.
   Six other CI jobs passed. PR #26 was closed without merging.
   Evidence: pr-23-performance-ci.txt, health-content-gate.txt,
   and health-content-gate-failure.txt.

8. Real PR coverage
   Expect all four capstone checks on at least five real PRs, including
   three bad PRs closed without merging and a merged good PR.
   Result: five PRs recorded, covering PRs #23 through #27.
   PR #23: seven checks passed and the good change was merged.
   PR #24: Dockerfile lint failed; closed without merging.
   PR #25: shell script lint failed; closed without merging.
   PR #26: expanded performance check failed; closed without merging.
   PR #27: seven checks passed on the revision recorded in gate-runs.txt.
   Fifth-PR coverage is verified for that recorded revision.
   Evidence: gate-runs.txt and the individual failure logs.
   The four capstone checks are Dockerfile lint, shell script lint,
   container vulnerability scan, and the expanded performance smoke test.
   These failures demonstrate detection, not required-check merge blocking.

9. Releases and rollback
   Verify two annotated release tags, their image tags, and changelog entries.
   Time rollback from PR merge to the older image serving /health.
   Expect recovery in under five minutes.
   Result: not run.

10. Rebuild
    Follow the documented setup on a separate fresh VM.
    Verify hooks, release images, application health, and rollback.
    Record failures and fixes in REBUILD-GAPS.md.
    Result: not run.

## Evidence formatting

Copied negative-test logs have trailing whitespace removed.
Their original captures remain outside the repository on the VM.
No check results, measurements, timestamps, or URLs were rewritten.

## Final signoff

Pending release and rollback tests, fresh-VM rebuild, and final review
of the evidence. This is not a completed final signoff.
