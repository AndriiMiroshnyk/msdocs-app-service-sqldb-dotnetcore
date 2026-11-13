# Load and stress test report

Tests ran on November 10 and 12, 2026. Results were verified against Azure Load
Testing, Azure Monitor metrics, and autoscale Activity Log events on November 13.
All timestamps below are UTC.

The workload passed at 200 concurrent users and breached the latency target at
300 users. App Service plan CPU saturation was the first observed bottleneck.
Autoscale requested a second instance, but Azure rejected the allocation and the
plan remained at one instance.

## Environment and workload

- Linux App Service on a **P0v4 plan with one worker** in Canada Central.
- Azure SQL Database: **General Purpose, Gen5, 2 vCores** (`GP_Gen5_2`).
- Azure Load Testing: **one test engine**, targeting the production HTTPS custom
  domain. Production and staging share the App Service plan.
- [Locust workload](locustfile.py) introduced in commit `2a27084`. The script
  downloaded from stress run 8 matches the repository file byte for byte.

The URL baseline sends GET requests to `/`. The Locust workload lists Todos,
creates a uniquely named item, reads it back to verify persistence, and deletes
that item. Each user has separate cookies and submits antiforgery tokens.
Read tasks have weight 4 and write workflows weight 1, with a 1–3 second pause
between tasks. Consequently, URL-baseline throughput is not directly comparable
with Locust throughput.

The Locust test fails if error percentage exceeds **1%**, p95 response time
exceeds **1,000 ms**, or either `create-todo` or `delete-todo` records fewer than
one request. Autostop is configured at **50% errors over 60 seconds**.

## Measured results

Users, duration, and spawn rate are configured values. Azure's lifecycle start
times include provisioning; configured duration describes the load phase.
Latency values are milliseconds. Each run used one load-test engine.

| Run | Start (UTC, 2026) | Users | Duration | Spawn/s | Requests/s | p95 / p99 | Errors | Result |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: | --- |
| URL baseline | Nov 10 10:26:09 | 5 | 2 min | 1 min ramp | 219.86 | 29 / 45 | 0% | Completed; no criteria |
| Locust baseline | Nov 10 11:18:01 | 5 | 2 min | 1 | 3.94 | 14 / 57 | 0% | Passed |
| Stress 1 | Nov 10 11:46:08 | 10 | 3 min | 1 | 7.42 | 14 / 29 | 0% | Passed |
| Stress 2 | Nov 10 11:55:41 | 20 | 5 min | 5 | 15.05 | 14 / 21 | 0% | Passed |
| Stress 3 | Nov 10 12:11:36 | 50 | 10 min | 25 | 39.69 | 15 / 23 | 0% | Passed |
| Stress 4 | Nov 10 12:59:25 | 100 | 30 min | 50 | 79.07 | 17 / 34 | 0% | Passed |
| Stress 5 | Nov 12 11:36:10 | 200 | 5 min | 10 | 149.90 | 25 / 56 | 0% | Passed |
| Stress 6 | Nov 12 11:55:43 | 300 | 3 min | 10 | 175.06 | 2,246 / 4,667 | 0% | Failed: p95 |
| Stress 7 | Nov 12 12:49:35 | 300 | 10 min | 10 | 193.06 | 1,508 / 3,478 | 0% | Failed: p95; scale-out rejected |
| Stress 8 | Nov 12 14:11:38 | 300 | 10 min | 10 | 199.37 | 1,177 / 2,438 | 0% | Failed: p95; scale-out rejected |

The portal names are `todo-url-baseline-run-1`, `todo-locust-baseline-run-1`,
and `todo-locust-stress-test-run-1` through `-8`. The p95 column uses the
pass/fail evaluation where present. For stress 8, Azure's aggregate statistics
report 1,175 ms while its criterion reports 1,177 ms; both exceed the target.

The Locust baseline completed 501 requests, including 67 creates and 67 deletes.
Stress 8 completed 120,619 requests, including 15,133 creates and 15,133 deletes,
with no client-reported failures. The failed result describes excessive latency,
not an application outage.

## Breaking point and bottleneck

Stress 5 was the last passing load. Increasing concurrency from 200 to 300 in
stress 6 increased throughput from 149.90 to 175.06 requests/s, approximately
17%, while p95 rose from 25 to 2,246 ms. Further 300-user runs also failed the
same latency criterion.

| Resource observation | Stress 5: 200 users | Stress 6: first failure | Stress 8: latest repeat |
| --- | ---: | ---: | ---: |
| Plan CPU: highest one-minute average | 72% | 98% | 100% |
| Plan memory: highest one-minute average | 56% | 60% | 60% |
| SQL CPU: highest reported maximum | 4% | 6% | 6% |
| Load-engine CPU: highest one-minute value | Not reviewed | 16.7% | 19.0% |

During stress 6, plan CPU averaged 97% and 98% at 11:58 and 11:59. During
stress 8 it remained between 91% and 100% from 14:14 through 14:22. SQL data IO
and log IO utilization reported 0% at the retrieved metric resolution during
these windows; this does not mean the workload performed no database operations.

These observations point to **App Service compute capacity**, rather than SQL
capacity or load-engine CPU, as the first limiting resource. They do not identify
a specific expensive application method or prove that no other bottleneck exists.

## Autoscale change and outcome

Azure Monitor autoscale was configured on the App Service plan with minimum and
default capacity **1**, maximum **2**, and these final rules:

- Scale out: average CPU **>70% for 5 minutes**, add one instance; 5-minute cooldown.
- Scale in: average CPU **<30% for 10 minutes**, remove one instance; 5-minute cooldown.

Stress 7 still used a 10-minute scale-out evaluation window. Its first recorded
failed scale action was at **13:00:06 UTC**. Stress 8 used the corrected 5-minute
window. Azure attempted **1 → 2 instances** at **14:18:55 UTC** and retried through
**14:25:55 UTC**. Every attempt failed with `Forbidden`, extended code `70001`:

> The subscription '[redacted]' is not allowed to create or update the serverfarm.

The plan remained at one instance. The rules triggered, but Azure prevented the
capacity change. The reported regional P0v4 usage was 1 of 30, the subscription
was enabled, and `Microsoft.Web` was registered. The error did not disclose the
underlying restriction; an Azure support request was opened for investigation.

Although stress 8 had lower aggregate latency than stress 6, **this is not
evidence of an autoscale benefit**. Their durations differ, and no second worker
became available. Even the two 10-minute runs both failed the original target.

## Evidence and limitations

The reported measurements were retrieved directly from Azure Load Testing run
statistics and criteria, Azure Monitor plan/SQL metrics, load-engine health
metrics, and autoscale Activity Log events. Useful Workbook intervals are:

| Evidence | UTC interval on November 12, 2026 |
| --- | --- |
| Last passing load, stress 5 | 11:36–11:44 |
| First observed failure, stress 6 | 11:55–12:04 |
| First autoscale attempt, stress 7 | 12:49–13:05 |
| Corrected autoscale rule, stress 8 | 14:11–14:26 |

Durations and spawn rates varied during exploration, so the runs do not establish
an exact maximum sustainable concurrency. The deployed application build and
starting database size were not independently recorded for every run.
