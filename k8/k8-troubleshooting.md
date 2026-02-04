## 1. Pods are Running but Application is Not Reachable via Service
# Kubernetes Troubleshooting

**What’s really being tested:**
* Service selectors
* Endpoints
* Networking basics

First, I’ll check whether the Service has endpoints using:
`kubectl get endpoints <service-name>`

* If endpoints are empty, it usually means the **Service selector** does not match the **Pod labels**.
* I’ll verify labels on the pods using `kubectl get pods --show-labels` and compare them with the Service selector.
* If labels match and endpoints exist, I’ll then check the Service type, `targetPort` vs `containerPort`, and finally test connectivity using a temporary debug pod with `curl`.

---

**OR**

If a pod is running but the app isn’t accessible:

1. I first verify the **container logs** and confirm the app is listening on the correct port.
2. Then I check the **Service `targetPort`** and ensure the application is bound to `0.0.0.0`, not `localhost`.

> In many cases, it’s a port mismatch or binding issue.

## 2. Pod is Stuck in CrashLoopBackOff but Logs Look Fine
# CrashLoopBackOff Troubleshooting

**What’s being tested:**
* Exit codes
* Liveness probes
* App startup behavior

**CrashLoopBackOff doesn’t always mean the app is failing.**

1. **Check Exit Codes:**
   I’ll first check the container exit code using:
   `kubectl describe pod`

2. **Analyze Liveness Probes:**
   If the exit code is `0` or the logs look normal, I suspect a failing **liveness probe**.

3. **Verify Configuration:**
   I’ll verify the probe configuration:
   * `initialDelaySeconds`
   * `timeoutSeconds`
   * Whether the app is actually ready when the probe runs.

> **Note:** Often, aggressive liveness probes kill healthy containers during startup.

## 3. Kubernetes Node is NotReady Intermittently

**What’s being tested:**
* Node health
* kubelet
* System resources

1. **Describe Node:**
   I’ll start by describing the node to see conditions using:
   `kubectl describe node`

2. **Common Causes:**
   Common causes are disk pressure, memory pressure, or kubelet issues.

3. **Node Access:**
   Then I’ll SSH into the node and check `kubelet` status, disk usage, and system logs.

4. **Disk Pressure:**
   If disk pressure is the issue, I’ll look for container logs or unused images consuming space.

> **Note:** Intermittent NotReady usually points to resource exhaustion or network instability.

---

## 4. Deployment Rollout is Stuck and Never Completes

**A rollout usually gets stuck because new pods are never becoming Ready.**

1. **Check Status:**
   I’ll run the following command and then inspect the new pods:
   `kubectl rollout status deployment`

2. **Inspect Issues:**
   Most of the time, the **readiness probe** is failing or the app is waiting for a dependency like a database.

> **Resolution:** Until readiness passes, Kubernetes won’t terminate old pods, so the rollout remains stuck.

---

## 5. Pod Cannot Pull Image but Node Has Internet Access

1. **Check Error:**
   First, I’ll check the exact error using:
   `kubectl describe pod`

2. **Authentication:**
   If it’s an authentication error, I’ll verify the **ImagePullSecret** is created in the same namespace and referenced correctly in the pod spec.

3. **Cloud Registries (ECR/GCR):**
   If it’s a cloud registry like ECR, I’ll ensure the node **IAM role** has permission to pull images.

> **Key Takeaway:** Internet access alone is not enough — registry auth is mandatory.

---

## 6. High Pod Restarts but No Errors in Logs

**When logs are clean, I immediately suspect OOMKilled.**

1. **Check State:**
   I’ll check pod events and container state for `OOMKilled`.

2. **The Cause:**
   If memory limits are too low, the kernel kills the process without app-level logs.

3. **The Fix:**
   The fix is either increasing memory limits or optimizing application memory usage.

---

## 7. Requests Are Slow Even Though Pods and Nodes Are Healthy

1. **Check CPU Limits:**
   I’ll first check CPU limits. Even if CPU usage looks low, strict CPU limits can cause **throttling**.

2. **Verify Metrics:**
   Using `kubectl top pod` and metrics, I’ll verify if pods are CPU throttled.

> **Optimization:** Often removing CPU limits or setting proper requests improves latency significantly.

---

## 8. Service Works Inside Cluster but Fails Externally

**If it works internally, the app and service are fine.**

1. **Focus Area:**
   I’ll then focus on the **Ingress** or external **Load Balancer**.

2. **Verification Points:**
   I’ll check listener ports, target group health checks, and security group rules.

> **Common Issue:** In cloud environments, missing inbound rules is a very common issue.

---

## 9. Pods Can’t Communicate Across Namespaces

1. **Default Behavior:**
   By default, Kubernetes allows cross-namespace communication.

2. **Network Policies:**
   If it’s failing, I immediately suspect **NetworkPolicies**.

3. **Troubleshooting:**
   I’ll check if there’s a deny-all policy applied and whether the required namespace selectors are missing.

> **Rule:** NetworkPolicies are namespace-scoped, so explicit allow rules are required once policies are enabled.

## 10. I have configured a desired replica count of 5 pods, but only 3 pods are running. What could be the issue?

**Core Issue:** If the desired replica count is 5 but only 3 are running, it usually means the remaining pods are in a **Pending** state and cannot be scheduled.

**Common Causes:**
1.  **Insufficient Resources:** Nodes do not have enough available **CPU or Memory** to meet the pod's requests.
2.  **Scheduling Constraints:** Pods are restricted by **Node Selectors** or **Affinity/Anti-Affinity** rules that cannot be satisfied.
3.  **Taints & Tolerations:** Nodes are tainted, and the new pods do not have the matching tolerations.
4.  **Resource Quotas:** The **Namespace** has hit its hard limit for CPU, memory, or pod count.
5.  **Pod Errors:**
    * **ImagePullBackOff:** Pods are scheduled but failing to download the image.
    * **CrashLoopBackOff:** Pods start but immediately crash.

**Troubleshooting Steps:**
* Check Pod Status: `kubectl get pods` (Look for Pending/Error).
* Check Events: `kubectl describe pod <pending-pod-name>` (The "Events" section will state exactly why it isn't scheduling).
* Check

## 11. what is OOM in kubernetes and why we get this error

# Kubernetes OOM (Out of Memory) Errors

In Kubernetes, **OOM** stands for **Out of Memory**. When you see this error (often appearing as `OOMKilled` in your pod status), it means a container was forcefully terminated because it tried to use more memory than it was allowed, or because the physical node it was running on ran out of RAM.

**Key Concept:**
Unlike CPU usage, which Kubernetes can "throttle" (slow down) to keep things running, **Memory is a non-compressible resource**. If a process needs memory and none is available, the system has no choice but to kill the process to protect the rest of the operating system.

## Why do you get this error?

There are two primary levels where an OOM event occurs:

### 1. Container Limit Exceeded (Cgroup OOM)
This is the most common cause. You have defined a limit in your YAML file, and the application tried to go past it.

* **The Cause:** Your application legitimately needed more memory for a task, or it has a **memory leak** where it gradually consumes RAM without releasing it.
* **The Result:** The Linux kernel's "OOM Killer" identifies the specific container breaching its limit and sends a `SIGKILL`.
* **How to spot it:**
    Running `kubectl describe pod <pod-name>` will show:
    * **Reason:** `OOMKilled`
    * **Exit Code:** `137`
