# Load and stress testing

[locustfile.py](locustfile.py) reads `/Todos` and runs a create/read/delete
workflow through the application. Each virtual user has its own cookies and
reads the antiforgery token from the HTML forms. The script verifies that a
created item appears in the list, then deletes that specific item.

Read tasks have weight 4 and write workflows have weight 1, with a 1–3 second
pause between tasks. These are task weights, not percentages of HTTP requests.
SQL is in the request path for both workflows. No database credentials are needed
by the load test.

## 1. Record the URL baseline

1. Open **App Service > Performance > Load Testing > Create test > Create a
   URL-based test**.
2. Create or select an Azure Load Testing resource in the application's resource
   group. Use one region for all comparison runs.
3. Name the test **Todo URL baseline**, select production, and clear **Run test
   after creation** while configuring it.
4. Add a **GET** request to the application's HTTPS URL with path `/`. Use the
   same hostname for the later stress and autoscale comparison runs.
5. Set **5 virtual users**, **1 minute ramp-up**, **2 minutes duration**, and
   **1 test engine**. Review these values before starting.
6. On **Monitoring**, add the production App Service, App Service plan,
   SQL database, and Application Insights. Configure the metrics listed below.
7. Run the test. Record its run ID, UTC interval, throughput, error percentage,
   p50, p95, and p99. Open the Workbook for the same interval and save evidence.

Set a monthly VUH limit under the load testing resource's **Overview > Usage
limits** before larger runs. The limit stops tests on a best-effort basis and
can be slightly exceeded. Check the pricing calculator for the chosen region.
See [usage limits](https://learn.microsoft.com/en-us/azure/app-testing/load-testing/how-to-manage-usage-limits).

## 2. Run the database workload

1. In the load testing resource, choose **Tests > Create > Upload a script**.
   Name this portal test **Todo database workload** and clear **Run test after
   creation**.
2. Select **Locust**, upload [locustfile.py](locustfile.py), then upload
   [locust.conf](locust.conf) with file relevance **Locust configuration**.
   No additional Python dependencies are required beyond Locust.
3. Under **Parameters > Environment variables**, set `TARGET_HOST` to the HTTPS
   base URL, for example `https://www.example.com`, without a path or trailing slash.
4. On **Load**, explicitly set **5 users**, **1 user/second spawn rate**,
   **2 minutes**, and **1 engine**. Keep these consistent with `locust.conf`.
5. Add the four app components and their metrics. Under **Test criteria**, add
   the failure conditions from [load-test.yaml](load-test.yaml): error rate over
   **1%**, p95 response time over **1,000 ms**, and fewer than **1** request for
   either `create-todo` or `delete-todo`. Enable autostop at **50% errors over
   60 seconds**. These are initial project targets; keep them fixed for comparisons.
6. Run the test and confirm that `list-todos`, `create-todo`, and `delete-todo`
   all appear in the results. Save this run as the database-workload baseline.

The script creates items prefixed `loadtest-` and deletes only its own items.
Failed or interrupted workflows can leave items behind; remove those test items
through the app before the next comparison. Keep the starting dataset comparable.

### Server-side metrics

Open the saved test's **Configure > Server side metrics** to select:

| Component | Metrics |
| --- | --- |
| Production App Service | Requests, HTTP 4xx/5xx, response time, memory working set, health check status |
| App Service plan | CPU percentage, memory percentage, HTTP queue length; observe instance count in the Workbook and autoscale run history |
| SQL database | CPU percentage, data IO percentage, log IO percentage, storage percentage, failed connections, deadlocks |
| Application Insights | Failed requests, exceptions, failed dependencies, request duration |

Use the Workbook to correlate Traffic Manager endpoint health and the detailed
KQL queries with the same UTC interval. Metrics can arrive after the run ends.
The plan also hosts staging, so keep staging idle during comparisons.
See [server-side metrics](https://learn.microsoft.com/en-us/azure/app-testing/load-testing/how-to-monitor-server-side-metrics).

## 3. Find the breaking point

Keep the plan at one instance initially. Pause deployments and slot swaps during
each run, and record the deployed commit and resource tiers.

1. Edit the portal database-workload test, increasing users gradually: **5 → 10
   → 20 → 50**, then higher only if the results and budget justify it. Use a
   gradual spawn rate, one engine, and a consistent duration. Change one load
   variable at a time.
2. Review each run before increasing load. The breaking point is the first
   repeatable breach of the agreed latency or error targets; a service outage
   is not necessary. Check per-request statistics as well as aggregate p95.
3. At the first breach, inspect the matching Workbook interval, Application
   Insights dependencies/exceptions, and server metrics. Record which resource
   saturated first. If a cold start or short spike explains a result, verify it
   with another run at that load.
4. Check the load engine's CPU and memory too. A saturated engine limits the
   generated load and does not establish an application bottleneck.

| Evidence | What to investigate |
| --- | --- |
| High plan CPU and HTTP queue length | App compute capacity |
| High plan memory or app restarts | Memory pressure |
| High SQL CPU/data IO/log IO and slower SQL dependencies | Database capacity or query behavior |
| HTTP 400 with antiforgery exceptions | Token/session handling or concurrent slot swaps |
| Errors with low resource utilization | Request details, configuration, limits, or failed dependencies |

Record observations before choosing a fix. Increasing App Service instances can
leave a database bottleneck unchanged.

## 4. Enable autoscale and compare

If app compute is the bottleneck, configure Azure Monitor autoscale on the
**App Service plan > Scale out > Rules based / Custom autoscale**:

1. Set minimum/default instances to **1** and choose a maximum within your
   budget, for example **2**.
2. Add a scale-out rule: average **CPU percentage > 70% for 5 minutes**, increase
   by **1**, cooldown **5 minutes**.
3. Add a scale-in rule: average **CPU percentage < 30% for 10 minutes**, decrease
   by **1**, cooldown **5 minutes**. Save the settings.
4. Repeat the workload that breached the targets, using the same URL, script,
   users, spawn rate, and duration. Allow enough sustained load for the evaluation
   window and instance startup. A two-minute run cannot demonstrate this rule.
   If extending the duration, repeat the one-instance run for the same duration.
5. Capture the autoscale event and instance count changing, then compare latency,
   throughput, errors, and SQL utilization before and after the added instance.
   Check traffic and CPU by instance to confirm that the extra worker receives load.

If scaling fails, retain the failed event and error details. A triggered rule
does not demonstrate successful scaling; confirm that the instance count increased
before attributing a performance change to autoscale.

If SQL saturated first, document it and address that bottleneck separately.
Record any SQL tier or query change as a separate experiment. After testing,
return the plan to the intended instance count and disable temporary scaling
rules if appropriate. Capture retained infrastructure changes in Terraform before
the next apply.
See [Azure Monitor autoscale](https://learn.microsoft.com/en-us/azure/azure-monitor/autoscale/autoscale-get-started).

## 5. Run the pipeline smoke test

[azure-pipelines.yml](../azure-pipelines.yml) runs an `AzureLoadTest@1` stage after
the production swap and smoke test succeed. Its configuration uses **5 users for
2 minutes on 1 engine**, with the criteria in
[load-test.yaml](load-test.yaml). The `loadTestHost` pipeline variable supplies
the application's custom-domain HTTPS base URL to `TARGET_HOST`.

1. Install the **Azure Load Testing** Azure DevOps marketplace extension.
2. On the self-hosted Linux/WSL agent, install **PowerShell and Azure PowerShell
   (Az modules)** as required by the task. Verify installation as the agent user:

   ```bash
   pwsh -NoProfile -Command 'Get-Module -ListAvailable Az.Accounts'
   ```

   See [AzureLoadTest@1 prerequisites](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-load-test-v1?view=azure-pipelines).
3. On the load testing resource's **Access control (IAM)**, grant **Load Test
   Contributor** to the service principal behind `azure-appservice-wif`.
   The existing web deployment role covers different operations.
   See [load testing roles](https://learn.microsoft.com/en-us/azure/app-testing/load-testing/how-to-assign-roles).
4. Set `loadTestingResourceName` in YAML to your existing resource's name. The
   pipeline expects it in `resourceGroupName`. Keep the service connection
   authorized for this pipeline. In Azure DevOps, open the pipeline's
   **Edit > Variables** and add `loadTestHost` with your custom-domain HTTPS base
   URL, for example `https://www.example.com`, without a trailing slash.
5. Commit and push your reviewed files to the branch configured in the pipeline's
   CI trigger. The pipeline deploys the application, then runs the paid load test
   automatically after the production smoke test succeeds.

The load test also runs after a successful deployment started manually. The
pipeline uses test ID `todo-crud-smoke`; the portal stress test uses its own ID
and app component settings. Use the Workbook for server-side evidence during the
pipeline smoke run. The pipeline publishes downloaded results and reports as the
`load-test-results` artifact. They are also available in the Azure Load Testing
resource under the test's runs.

## Report

See [REPORT.md](REPORT.md) for the measured baselines, stress-test results,
bottleneck analysis, and autoscale outcome.
