If I receive a High CPU alert from Prometheus/CloudWatch or any monitoring tool, I won't immediately restart the server. My goal is first to identify what is consuming the CPU and whether it is affecting users."

Step 1: Verify the Alert

First, I verify the alert in the monitoring dashboard.

Questions I ask:

Which server or pod has high CPU?
Is it one server or all servers?
When did it start?
Did it happen after a deployment?

If it started immediately after deployment, I already suspect the new release.

Step 2: Check Current CPU Usage

On Linux I use

top

or

htop

This shows

CPU utilization
Memory usage
Processes consuming CPU

Example

PID   USER   %CPU   COMMAND

4210  java    280   java
1456  nginx    12   nginx

Now I know the Java application is consuming CPU.

Step 3: Identify Which Process

Sometimes there are multiple Java processes.

I run

ps -ef | grep java

or

ps -eo pid,ppid,%cpu,%mem,cmd --sort=-%cpu

This tells me

PID
Application name
CPU usage

Now I know exactly which application is responsible.

Step 4: Check if Users are Impacted

Now I verify whether users are actually facing issues.

I check

ALB Target Response Time
HTTP 5xx errors
Request count
Latency
Grafana dashboards

If CPU is high but users aren't affected, it may just be temporary traffic.

If users are getting

Slow responses
Timeouts
502/503

then it becomes a production incident.

Step 5: Check Recent Deployments

I verify

GitLab

Jenkins

ArgoCD

Deployment history

Questions:

Was a new version deployed?
Was a feature enabled?
Any configuration changes?

Many CPU issues start after deployment.

Step 6: Check Application Logs

I check

journalctl -u myapp

or

kubectl logs pod-name

or

/var/log/application.log

I'm looking for

Infinite retries
Exceptions
Database connection failures
External API failures
Stack traces
Step 7: Check Traffic

Sometimes the application is healthy.

The CPU is high simply because traffic increased.

I verify

CloudWatch

ALB metrics

Prometheus

Request count

Example

Normal traffic

200 requests/minute

Current

3000 requests/minute

The high CPU may simply be due to increased traffic.

Step 8: Check Database

Many applications consume CPU while waiting for the database.

I check

Slow queries
Connection pool
Database CPU
Database latency

Example

Application CPU
95%

Database CPU
100%

The application keeps retrying database calls, causing CPU usage to rise.

Step 9: Check External Dependencies

If the application calls

Redis
Kafka
Elasticsearch
Third-party APIs

I verify

Response time
Timeouts
Connection failures

Applications often consume CPU while repeatedly retrying failed requests.

Step 10: Take Immediate Action

Depending on the root cause:

If traffic increased

Scale horizontally.

For Kubernetes

kubectl get hpa

or

kubectl scale deployment myapp --replicas=6

If using Auto Scaling Groups

Increase desired capacity.

If one pod is stuck

Restart only that pod.

kubectl delete pod pod-name

Kubernetes recreates it automatically.

If deployment caused the issue

Rollback.

kubectl rollout undo deployment myapp

or

Rollback via ArgoCD.

If a memory leak or application bug is causing high CPU

Raise the issue to developers with:

Logs
Thread dump
CPU graphs
Time of occurrence
Step 11: Verify Recovery

After the fix, I monitor

CPU utilization
Response time
Error rate
Request success rate
User complaints

If CPU returns to normal and users are no longer impacted, I consider the incident resolved.

Commands I Use

Check CPU

top

Detailed process list

ps -eo pid,%cpu,%mem,cmd --sort=-%cpu

Live process monitoring

htop

Application logs

journalctl -u myapp -f

Kubernetes logs

kubectl logs pod-name

Resource usage

kubectl top pod
kubectl top node

Deployment history

kubectl rollout history deployment myapp

Rollback

kubectl rollout undo deployment myapp
Real-Time Example (Interview)

"In one of our production environments, we received a Prometheus alert indicating that CPU usage on one of the application pods had exceeded 90%. I first confirmed the alert in Grafana and identified the affected pod. Using kubectl top pod, I verified that only one pod had high CPU while the others were normal. I checked the pod logs with kubectl logs and found repeated retries due to failures connecting to an external API. This retry loop was driving CPU usage. As an immediate mitigation, I restarted the affected pod, which restored normal CPU levels. I then shared the logs and findings with the development team, who fixed the retry logic in a subsequent release."

This answer demonstrates a logical production troubleshooting process: confirm the alert, identify the affected process, determine user impact, investigate recent changes and dependencies, mitigate the issue, and verify recovery. That's the kind of structured thinking interviewers expect from a DevOps engineer.
