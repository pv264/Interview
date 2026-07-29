"Suppose CPU usage suddenly goes above 90%. How will you troubleshoot it?"

Interview Answer

"The first thing I do is understand the alert before taking any action. High CPU itself is not always a problem; I need to know whether it's affecting the application or users."

Step 1: Understand the Alert

"I'll first open our monitoring tool, such as Prometheus and Grafana or CloudWatch, depending on the environment.

I want to answer a few questions:

Which server or Kubernetes pod has high CPU?
Is it only one pod or all pods?
When did the spike start?
Did it happen after a deployment?

For example, if I see that only one out of four pods is at 95% CPU while the other three are around 20%, I know the issue is isolated to that pod rather than the entire application."

Why?

"This helps me narrow down whether I'm dealing with an application issue, a node issue, or just one unhealthy pod."

Step 2: Verify on the Server

"Next, I'll log in to the server or Kubernetes cluster to confirm what the monitoring tool is showing.

If it's a Linux server, I'll run:

top

or

htop

These commands show which process is consuming the CPU.

For example, I might see:

PID      COMMAND      CPU

2456     java         280%
1456     nginx         10%

That immediately tells me the Java application is consuming most of the CPU."

Why?

"Monitoring tells me there is a problem, but these commands tell me exactly which process is causing it."

Step 3: Find Out Which Application

"If there are multiple Java applications running, I need to identify which one is responsible.

I'll run:

ps -ef | grep java

or

ps -eo pid,%cpu,%mem,cmd --sort=-%cpu

This shows me the command that started the process, so I can identify whether it's my application or another service."

Why?

"I don't want to restart the wrong application."

Step 4: Check Whether Users Are Affected

"Now I want to understand the business impact.

I'll check Grafana or our Application Load Balancer metrics.

I'm looking for:

Increased response time
HTTP 500 errors
HTTP 502 or 503 errors
Increased latency

For example, if CPU is 95% but response time is still around 150 milliseconds and there are no errors, I know users are not currently affected.

If response time has increased to 5 seconds and users are seeing 503 errors, then this becomes a high-priority production incident."

Why?

"High CPU without user impact is very different from high CPU causing an outage."

Step 5: Check Recent Changes

"The next thing I check is whether anything changed recently.

I'll verify:

Jenkins pipeline
GitLab pipeline
ArgoCD deployment history
Kubernetes rollout history

Suppose a deployment happened at 10:00 AM and CPU increased at 10:05 AM.

That strongly suggests the new release introduced the issue."

Why?

"In production, many issues are introduced immediately after deployments."

Step 6: Analyze Application Logs

"Now I'll check the application logs.

If it's Kubernetes:

kubectl logs <pod-name>

If it's a VM:

journalctl -u myapp -f

I'm looking for:

Exceptions
Continuous retries
Database connection failures
External API failures
Infinite loops

For example, I may find something like:

Database connection failed.
Retrying...
Database connection failed.
Retrying...

This tells me the application is continuously retrying failed database calls, which explains the high CPU."

Step 7: Check Traffic

"Now I want to know whether the application is simply handling more requests than usual.

I'll check ALB metrics or Prometheus dashboards.

Suppose our application normally receives 200 requests per minute.

Today it's receiving 3,000 requests per minute.

In that case, high CPU is expected because demand has increased."

Why?

"The application may not have a bug—it may simply need additional capacity."

Step 8: Check Database and Other Dependencies

"If traffic looks normal, I'll investigate dependencies.

I'll check:

Database CPU
Slow queries
Redis
Kafka
Elasticsearch
Third-party APIs

For example, if the database CPU is already at 100%, every application request waits longer.

The application threads remain busy waiting or retrying, causing application CPU to increase as well."

Step 9: Decide the Correct Action

"Once I understand the cause, I'll take the appropriate action.

If traffic has increased, I'll scale the application by increasing replicas or Auto Scaling Group capacity.

If only one pod is affected, I'll restart that pod because Kubernetes will recreate it.

If the issue started immediately after deployment, I'll roll back to the previous stable version.

If it's an application bug, I'll collect logs, thread dumps, and metrics, then work with the development team on a permanent fix."

Why?

"I avoid restarting services immediately because that only treats the symptom. I want to identify and fix the actual cause."

Step 10: Confirm the Fix

"Finally, after taking corrective action, I'll continue monitoring for some time.

I'll verify that:

CPU returns to normal
Response time improves
Error rate drops
Users are no longer reporting issues

Only after confirming that the application is stable do I close the incident."

Real-Time Example from a Kubernetes Environment

"In one production incident, we received a Prometheus alert that one application pod's CPU had crossed 90%. I first confirmed the alert in Grafana and noticed that only one pod was affected while the remaining pods were healthy. Using kubectl top pod, I confirmed the high CPU usage on that pod. I checked the application logs with kubectl logs and found repeated retries due to failures connecting to an external API. The retry loop was keeping the CPU busy. Since user requests were starting to fail with increased latency, I restarted only the affected pod as an immediate mitigation. CPU usage returned to normal, and response times improved. I then collected the logs and shared them with the development team, who fixed the retry logic and released a permanent solution."
