“Hi, my name is Pavan. I have over 4 years of experience in IT, primarily in Cloud and DevOps roles.

Currently, I’m working as a Cloud Engineer at Technoidentity, where I manage secure, scalable AWS infrastructure supporting GenAI deployments. My day-to-day work involves services like EC2, VPC, S3, Auto Scaling, and EKS, and I focus heavily on reliability, performance, and troubleshooting production issues in containerized environments.

Before this, I worked at TCS for more than 3 years in a customer-facing DevOps role. I started by handling L1 production issues related to deployments, and as I gained experience, I was promoted to Senior System Engineer, where I handled L3 and L4 tickets, including deeper root-cause analysis, complex incident troubleshooting, and coordinating fixes with multiple teams.

Across both roles, I’ve spent a lot of time diagnosing issues across AWS infrastructure, Kubernetes, Linux systems, and CI/CD pipelines, and communicating findings clearly to stakeholders.

I’m excited about the Senior Technical Solutions Engineer role at Databricks because it combines deep cloud troubleshooting, distributed systems, and direct customer impact, which aligns very closely with the work I’ve been doing and the direction I want to grow in.”**
# STAR Method Interview Answers

## ⭐ STAR ANSWER #1: Kubernetes Pods Restarting (CrashLoopBackOff / OOMKilled)

**S – Situation**
"In my current role as a Cloud Engineer, we were running a containerized GenAI workload on EKS, and we started seeing intermittent failures where pods were repeatedly restarting, impacting application availability."

**T – Task**
"My responsibility was to identify whether the issue was application-level or infrastructure-level, restore stability, and ensure it didn’t recur."

**A – Action (This Is Where You Impress)**
"I approached it in layers.
* First, I checked the pod status and events to understand why the restarts were happening. The `describe pod` output showed `OOMKilled` events, which immediately pointed to a memory issue rather than a code crash.
* I then pulled the previous container logs to confirm the workload was terminating under load and not due to startup failures.
* Next, I reviewed the resource limits and requests configured for the pod and found that the memory limits were too low for the model size and request pattern.
* I also verified node-level memory pressure to make sure the issue wasn’t caused by overall cluster exhaustion.
* Once I isolated the root cause, I adjusted the memory configuration and validated the fix under load."

**R – Result**
"After the change, the restarts completely stopped, application stability improved, and we documented resource guidelines so similar workloads wouldn’t repeat the issue. It also reduced incident noise for the team."

> **⭐ Senior Signal Sentence (Always Add This)**
> "I try to isolate whether an issue is due to application behavior, container configuration, or underlying infrastructure before making changes."

---

## ⭐ STAR ANSWER #2: Auto Scaling Not Triggering Under Load (EKS / HPA / ASG)

**S – Situation**
"In one production environment, we noticed that traffic was increasing significantly, but the application pods and nodes were not scaling as expected, leading to performance degradation."

**T – Task**
"I was responsible for diagnosing why scaling wasn’t happening and restoring performance without over-provisioning resources."

**A – Action**
"I started by checking the **Horizontal Pod Autoscaler (HPA)** configuration to see whether scaling rules were being evaluated correctly.
* While the HPA was present, it wasn’t scaling pods.
* I then verified metrics availability and confirmed that CPU metrics were being collected correctly.
* While reviewing the pod specifications, I identified that **CPU requests were not defined**, which meant the HPA didn’t have a baseline to make scaling decisions.
* After correcting the resource requests, I validated pod-level scaling.
* I also checked the **Cluster Autoscaler** logs to ensure that new nodes could be added when pod scheduling required additional capacity."

**R – Result**
"Once the configuration was fixed, pod scaling and node scaling started working as expected, application latency improved, and the system was able to handle traffic spikes automatically."

> **⭐ Senior Signal Sentence**
> "When troubleshooting scaling, I always validate metrics, resource definitions, and autoscaler behavior end-to-end rather than focusing on just one layer."
