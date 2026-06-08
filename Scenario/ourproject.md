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
