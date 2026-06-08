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
