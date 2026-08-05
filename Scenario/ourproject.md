## 1. Why use Request Count per Target for scaling rather than CPU metrics?

**Answer:**
**CPU utilization** is not always a reliable scaling metric because CPU may remain relatively low even when the application is experiencing high traffic and increased response times.

### The Problem with CPU Scaling (I/O Bound Workloads)
In our **Haystack-vLLM** architecture, each request involves operations such as vector searches in **Milvus** and inference calls to **vLLM**. 
* During these operations, the **Haystack** service spends part of its time *waiting* for responses from downstream services (I/O wait) rather than actively consuming CPU.
* As traffic increases, new requests continue to arrive while existing requests are still being processed.
* This can lead to a growing request queue and increased response times, even though CPU utilization may not be high enough to trigger a scale-out.



### The Solution: Request Count
Therefore, we scale based on **`RequestCountPerTarget`**, which directly reflects user demand and allows us to add capacity before request queues become too large and impact the user experience.

> **Senior Signal:** Recognizing the difference between CPU-bound workloads (like video encoding) and I/O-bound workloads (like an AI orchestration layer waiting on Milvus/GPU inferences) is a hallmark of a Senior Engineer. Mentioning that waiting on downstream services can cause "thread starvation" or "connection pool exhaustion" long before the CPU maxes out will really impress your interviewer!


## 2. Explain how you implemented your scaling strategy

**Answer:**
Our application consisted of two layers:
* **Haystack layer (CPU instances):** For request orchestration and RAG pipeline execution.
* **vLLM layer (GPU instances):** For LLM inference.

Both layers were deployed behind **AWS Auto Scaling Groups** and **Application Load Balancers (ALB)**.

### Why We Chose RequestCountPerTarget
During load testing, we observed that **CPU utilization** was not a reliable indicator because **Haystack** spends a significant amount of time waiting for **Milvus** searches and **vLLM** responses. 

As a result, request queues and response times increased before CPU utilization became high. Therefore, we chose **`RequestCountPerTarget`** from the ALB as our scaling metric because it directly represented user demand.

### Baseline Capacity & Math
During testing, we determined that our baseline capacity was:
* **2 Haystack instances**
* **1 vLLM instance**

This setup could comfortably handle approximately **60 requests every 10 seconds**.
* 60 requests / 10 sec = **6 requests / sec**
* 6 × 60 = **360 requests / min**

Since there were **2 Haystack instances**, the ALB calculates:
* 360 / 2 = **180 RequestCountPerTarget**

### Scaling Execution
* When traffic exceeded **180 `RequestCountPerTarget`**, we scaled **Haystack (2 to 3)** and **vLLM (1 to 2)**.
* We also implemented **scale-in policies** so that when traffic dropped below the thresholds, the environment automatically returned to its baseline capacity. 
* This helped reduce infrastructure costs while maintaining availability.

---

### Summary Overview
We implemented **AWS Auto Scaling** using the ALB metric **`RequestCountPerTarget`** because it reflected actual user demand better than CPU utilization. During load testing, we found that our baseline environment of **2 Haystack instances** and **1 vLLM instance** could handle about 60 requests every 10 seconds, which translated to 360 requests per minute. Dividing that across 2 Haystack instances resulted in a threshold of **180 `RequestCountPerTarget`**.

When that threshold was exceeded, we scaled **Haystack** from 2 to 3 instances and **vLLM** from 1 to 2 instances. For higher traffic levels, we further scaled Haystack to 4 instances. We also configured scale-in policies to automatically return to baseline capacity when traffic decreased. This approach ensured high availability during traffic spikes while optimizing infrastructure costs during normal workloads.

> **Senior Signal:** Mentioning both scale-out and **scale-in** policies is a massive green flag. Many engineers forget to design the scale-in process, leading to "cloud waste." Furthermore, explicitly walking the interviewer through the math (from 60 req/10s to the 180 threshold) proves that your scaling policies are strictly data-driven based on load testing, not just random guesses!

## 3. Explain the request flow in your LLM application

**Answer:**
Here is the end-to-end request flow for our Retrieval-Augmented Generation (RAG) architecture:

### Step-by-Step Execution Flow
1. **Inbound Routing:** A user request first reaches the **Application Load Balancer (ALB)**, which routes it to a **Haystack** instance (CPU-based orchestration layer).
2. **Context Retrieval:** **Haystack** generates an embedding for the query and performs a similarity search in the **Milvus** vector database to retrieve relevant document chunks.
3. **Prompt Construction:** **Haystack** combines the retrieved context with the user's original question to build the final, enriched prompt.
4. **LLM Inference:** The prompt is sent to the **vLLM** service (GPU-based instance) for inference.
5. **Response Delivery:** **vLLM** generates the final response and returns it to **Haystack**, which then sends it back out to the user through the **ALB**.



> **Senior Signal:** Because **Haystack** spends significant time *waiting* for embedding generation, vector searches, and LLM inference to complete (I/O wait time), CPU utilization alone does not accurately represent the actual application load. Highlighting this architectural reality perfectly explains *why* you chose to use **`RequestCountPerTarget`** instead of CPU metrics for your Auto Scaling strategy!

## 4 How do you monitor and troubleshoot high CPU utilization alerts?

**Answer:**
In our environment, we have a robust monitoring stack: we monitor infrastructure using **Prometheus** with **Node Exporter**, visualize the metrics in **Grafana**, and configure **Alertmanager** to route critical alerts to Slack or PagerDuty. 

If we receive an alert that CPU usage has stayed above 90% for five minutes, I follow this structured troubleshooting process:

### 1. Triage in Grafana
The first thing I do is open the Grafana dashboard to understand the blast radius. 
* I determine whether the issue affects a single isolated server or multiple servers across the cluster.
* I correlate the CPU spike with other related metrics, such as memory utilization, network I/O, and the application request rate.

### 2. System-Level Investigation
Next, I SSH into the affected EC2 instance. 
* I run command-line tools like `top` or `htop` to identify exactly which process or PID is consuming the CPU cycles.

### 3. Traffic vs. Application Issue
If I determine the application process itself is causing the spike, I need to know *why*:
* **Traffic Spike:** I check the ALB request metrics and Auto Scaling Group (ASG) activity to see if there is a legitimate surge in user traffic.
* **Application Issue:** If traffic is normal, I investigate recent deployments, review application logs, and check for any resource-intensive scheduled background jobs running at that time.

### 4. Remediation & Verification
Based on the root cause identified, I take the appropriate action:
* Scale the application (if it's a legitimate traffic spike).
* Roll back a recent deployment (if bad code was introduced).
* Optimize the application or reschedule heavy background jobs to off-peak hours.

Finally, I verify in Grafana that the CPU utilization has returned to baseline levels and confirm that the overall application is healthy.

> **Senior Signal:** What sets this response apart is the distinction between a **traffic-induced spike** and an **application-induced spike**. Junior engineers often see high CPU and immediately assume they need to scale up or reboot the server. A senior engineer checks the ALB/ASG first to see if scaling is actually the right answer, or if a recent deployment introduced an infinite loop or inefficient query that requires a rollback instead.



# Workload Identity Federation (WIF) Implementation for Jenkins (AWS EC2 → GKE)

## Project Overview

Implemented **Workload Identity Federation (WIF)** to securely connect a **Jenkins agent running on AWS EC2** with **Google Kubernetes Engine (GKE)**. The objective was to eliminate the use of **long-lived Google Cloud service account keys** and instead authenticate using the **AWS IAM role attached to the EC2 instance**.

---

## Implementation

- Created a **Google Cloud Service Account (GSA)** for GKE access.
- Configured a **Workload Identity Pool** and **AWS Workload Identity Provider** in GCP.
- Mapped the **AWS IAM role** to the GCP service account.
- Generated the **Workload Identity Federation credential configuration**.
- Integrated the WIF authentication configuration into the **Jenkins pipeline** for keyless authentication.

---

## Issue Encountered

During validation:

- Authentication from **AWS EC2 to Google Cloud** was successful.
- However, **service account impersonation** consistently failed with the following error:

```text
iam.serviceAccounts.getAccessToken permission denied
```

---

## Troubleshooting Performed

Systematically verified the following components:

- AWS IAM Role configuration
- EC2 IMDSv2 metadata access
- Workload Identity Pool configuration
- AWS Workload Identity Provider configuration
- Service Account IAM bindings
- Required IAM roles and permissions

After eliminating configuration issues, the root cause was identified.

---

## Root Cause

The **runtime identity (`google.subject`)** generated by the Workload Identity Provider did **not match** the identity referenced in the **Service Account IAM binding**.

Because of this mismatch, Google Cloud rejected the **service account impersonation request**, resulting in the `iam.serviceAccounts.getAccessToken` permission error.

---

## Resolution

To resolve the issue:

- Recreated the **Workload Identity Pool** and **AWS Provider**.
- Configured both:
  - `google.subject`
  - `attribute.aws_role`
- Ensured both resolved to the **same normalized AWS IAM Role ARN**.
- Regenerated the **Workload Identity Federation credential configuration**.
- Updated the Jenkins pipeline with the new credential configuration.
- Installed the required GKE authentication tools:
  - `kubectl`
  - `gke-gcloud-auth-plugin`

---

## Result

After implementing the changes:

- Jenkins successfully authenticated to Google Cloud using **Workload Identity Federation**.
- Service account impersonation worked successfully.
- Jenkins was able to access and deploy to the **GKE cluster**.
- No long-lived service account keys were required.

---

## Outcome

Successfully implemented a **secure, keyless authentication mechanism** between **AWS and Google Cloud** using **Workload Identity Federation (WIF)**.

This solution enables Jenkins running on AWS EC2 to securely deploy to GKE using **temporary credentials** obtained through Workload Identity Federation, eliminating the need to store or manage long-lived Google Cloud service account keys.
