# Capstone QA report

Author and tester: Anthony Yakoub
Track: DevSecOps and IT Project Management

## Test cases

1. Existing protection
   Confirm protect-master remains active and requires tofu fmt and validate,
   render the Prometheus chart, and security scan.
   Before record: capstone/devsecops-pm/evidence/branch-protection.txt.
   Final verification: pending.

2. Clean local checks
   Run pre-commit run --all-files and expect exit code 0.
   Initial result: all three hooks passed.
   Evidence: capstone/devsecops-pm/evidence/pre-commit-clean.txt.

3. Local rejection
   Attempt a commit containing deliberately invalid shell syntax.
   Expect ShellCheck to reject it and Git HEAD to remain unchanged.
   Result: commit rejected; HEAD unchanged.
   Evidence: capstone/devsecops-pm/evidence/hook-rejection.txt.

4. Dockerfile CI gate
   Open a deliberately bad Dockerfile PR.
   Expect the Dockerfile check to fail. Close it without merging.
   Result: not run.

5. Shell CI gate
   Open a deliberately bad shell-script PR.
   Expect the shell check to fail. Close it without merging.
   Result: not run.

6. Additional security scan
   Scan the web image with Trivy and record its findings and exit status.
   Document which findings fail the job and which only warn.
   Result: not run.

7. Expanded performance gate
   Test new behavior beyond the Week 10 homepage latency check.
   Verify a good build passes and an intentional regression fails.
   Result: not run.

8. Real PR coverage
   Record all new gate names and results on at least five real PRs,
   including three deliberately bad PRs and a merged good PR.
   Result: not run.

9. Releases and rollback
   Verify two annotated release tags, their image tags, and changelog entries.
   Time the rollback from PR merge to the older image serving /health.
   Expect recovery in under five minutes.
   Result: not run.

10. Rebuild
    Follow the documented setup on a separate fresh VM.
    Verify hooks, release images, application health, and rollback.
    Record failures and fixes in REBUILD-GAPS.md.
    Result: not run.

## Final signoff

Pending completion of the test cases and review of the saved evidence.
