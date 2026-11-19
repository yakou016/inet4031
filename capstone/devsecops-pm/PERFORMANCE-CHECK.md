# Performance check scope

Week 10 checked homepage latency and HTTP failures. The capstone adds:
- A separate /health request, checking HTTP 200 and JSON status "ok".
- A provisional /health p95 target below 200 ms.
- A separate homepage p95 target below 500 ms.
- Checks for the ticket-list heading and 1 to 50 visible ticket rows.
- A 100% check-success threshold so incorrect content fails the job.

The test expects a populated database. CI seeds 10,000 tickets.
The homepage-specific threshold prevents fast health requests from hiding
slow homepage requests in the combined latency result.

The test only reads data. It does not create or delete tickets.
Each iteration now sends two requests instead of one, so combined request
rates should not be directly compared with the old smoke test.
This is a short regression check, not proof of production capacity.
