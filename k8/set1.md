## 1 Explain the concept of liveness and readiness probes

**Answer:**
In Kubernetes, liveness and readiness probes are health checks configured inside the container specification of a Pod or Deployment YAML. While they sound similar, they trigger completely different actions by the Kubernetes control plane.

### 1. Readiness Probes (Traffic Control)
* **What it does:** Determines whether a pod is fully initialized and ready to receive real user traffic. 
* **The Action:** If a readiness probe fails, Kubernetes **stops sending traffic** to the pod by removing its IP address from the Service endpoints. It *does not* restart the pod.
* **Use Case:** A Spring Boot application might take 40 seconds to connect to the database, warm up the cache, and load configurations. The readiness probe ensures users aren't routed to that pod prematurely while it is still booting.

### 2. Liveness Probes (Self-Healing)
* **What it does:** Determines whether the container is fundamentally healthy or if it has entered a broken state where it cannot recover on its own.
* **The Action:** If a liveness probe fails repeatedly, Kubernetes **kills and restarts** the container.
* **Use Case:** Used to detect application hangs, deadlocks, or infinite loops after the application is already running. If the app freezes and becomes completely unresponsive, the liveness probe triggers an automatic restart to recover the service.

> **Senior Signal:** A strong candidate will clearly emphasize the difference in Kubernetes' reaction: Readiness failures mean "stop sending traffic," while Liveness failures mean "restart the container." To show advanced knowledge, mention the **`startupProbe`**. If you have a legacy application that takes several minutes to start, relying solely on a liveness probe might cause an endless crash-loop because it kills the container before it finishes booting. A `startupProbe` disables the liveness/readiness checks until the app successfully starts for the first time!


## 4 .What happens when a container image isn't available in ECR, and how do you troubleshoot it?

**Answer:**
When an image isn't available in Amazon ECR, the issue isn't just that the container fails to start—it triggers a specific failure in the underlying image pull workflow.

### The Failure Workflow
1. **The Request:** The `kubelet` running on the worker node instructs the container runtime to pull the specified image.
2. **Authentication & Fetch:** The runtime authenticates with ECR and attempts to download the requested image.
3. **The Rejection:** ECR cannot find the requested tag and returns an error, which the container runtime reports back to the `kubelet`.
4. **State Transition:** Kubernetes first reports an **`ErrImagePull`** state. Shortly after, as it begins retrying the pull request using an exponential backoff delay, the pod transitions into the **`ImagePullBackOff`** state.

### Troubleshooting Steps
In a production environment, I troubleshoot this systematically by checking the following:
* **Check Pod Events:** Run `kubectl describe pod <pod-name>` to look at the events at the bottom. This reveals the exact error message returned by the runtime.
* **Verify the Deployment:** Double-check the Deployment YAML to ensure there are no typos in the image URI or the specific tag.
* **Confirm in ECR:** Check the AWS Console or use the AWS CLI to confirm that the specific image tag actually exists in the target ECR repository.
* **Review CI/CD:** Review the CI/CD pipeline's push stage (e.g., in Jenkins or GitHub Actions) to ensure the image build and push were actually successful.
* **Validate IAM Permissions:** Ensure the worker node's IAM role has the necessary permissions (`ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`) to pull from ECR.
* **Check Network Connectivity:** Ensure the nodes have a valid network path to ECR, either through a NAT Gateway or via VPC Endpoints (AWS PrivateLink).

> **Senior Signal:** Pointing out that an `ImagePullBackOff` isn't *always* a missing image is a great way to demonstrate real-world experience. Often, the image tag is perfectly correct, but the worker node lacks the correct IAM permissions or network routing to reach ECR, which results in the exact same Kubernetes error state. Emphasizing `kubectl describe pod` as the fastest way to differentiate a "Not Found" error from an "Unauthorized" or "Timeout" error shows strong operational maturity.

## 5. What happens when a Pod's main application process crashes, and how do you troubleshoot it?

**Answer:**
When a Pod's main application process crashes, Kubernetes relies on the `kubelet` and the container's predefined restart policy to handle the failure and attempt recovery.

### The Crash and Recovery Workflow
1. **Detection:** The `kubelet` running on the worker node detects that the container's primary process has exited. 
2. **Immediate Restart:** For a Deployment, the restart policy is typically set to `Always`. Therefore, the `kubelet` automatically restarts the container within the same Pod. The Pod name and IP address remain identical, but you will see the `RESTARTS` count increase.
3. **CrashLoopBackOff:** If the application keeps crashing repeatedly, Kubernetes intervenes to protect the cluster's resources. It transitions the Pod into a **`CrashLoopBackOff`** state and retries the restarts with exponentially increasing delays (e.g., 10s, 20s, 40s, up to 5 minutes).

### Troubleshooting Steps
To diagnose and resolve the crashing pod, I follow this process:
* **Check Pod Status:** Run `kubectl get pods` to observe the current state and see how many times it has restarted.
* **Inspect the Pod:** Run `kubectl describe pod <pod-name>`. I specifically look at the `State` and `Reason` (to see if it exited with an `Error` or an `OOMKilled` status) and review the Events at the bottom for probe failures.
* **Review Logs:** I check the application logs to find the exact exception. 
* **Identify Root Cause & Fix:** Based on the logs and describe output, I determine if the issue is an application code error, an Out Of Memory (OOM) kill, a failing liveness probe, or a missing configuration (like a Secret or ConfigMap), and apply the appropriate configuration change or code rollback.

> **Senior Signal:** Emphasizing how you check the logs is a major differentiator here. A junior engineer will just run `kubectl logs <pod-name>`, which only shows the logs for the *current*, newly restarted container (which might be empty). A senior engineer will explicitly state they run **`kubectl logs <pod-name> --previous`** (or `-p`) to retrieve the logs of the container that actually crashed, which contains the crucial stack trace or error message!

## 6 What happens when a worker node goes down, and how do you troubleshoot it?

**Answer:**
When a worker node goes down, Kubernetes' self-healing mechanisms automatically detect the failure and reschedule the affected workloads to maintain high availability.

### The Failure and Recovery Workflow
1. **Detection:** The `kubelet` on the failed node stops sending its regular heartbeats to the API Server. The Node Controller detects these missing heartbeats and marks the node's status as **`NotReady`**.
2. **Pod Unavailability:** The Pods running on that specific node become unavailable.
3. **ReplicaSet Intervention:** If those Pods are managed by a Deployment, the ReplicaSet notices that the number of available replicas has dropped below the desired count and creates replacement Pods.
4. **Rescheduling & Execution:** The Scheduler evaluates the cluster and places these newly created Pods onto healthy nodes. The `kubelets` on those selected nodes then start the new containers.
5. **Traffic Routing:** Once the readiness probes for the new Pods pass, the Service updates its endpoints, and network traffic is seamlessly routed to the newly provisioned Pods.

### Troubleshooting Steps
During an active node failure, I would investigate and monitor the situation using the following methods:
* **Node Status:** Run `kubectl get nodes` and `kubectl describe node <node-name>` to investigate *why* it went down (e.g., checking for resource exhaustion or network disconnects).
* **Blast Radius:** Run `kubectl get pods -o wide` to see exactly which pods were impacted by the downed node.
* **Cluster Activity:** Run `kubectl get events` to track cluster-wide control plane actions and errors.
* **Monitor Recovery:** Run `kubectl get pods -w` to actively watch the replacement Pods being recreated and initialized in real time.
* **Capacity Check:** If the cluster doesn't have enough spare capacity to schedule the replacement Pods, I would verify whether the **Cluster Autoscaler** is successfully provisioning and adding new worker nodes to handle the load.

> **Senior Signal:** A great detail to add in an interview is mentioning the **`pod-eviction-timeout`**. By default, Kubernetes waits 5 minutes after a node goes `NotReady` before it forcefully evicts the pods and reschedules them (to prevent thrashing in case of a brief network blip). Mentioning this built-in 5-minute delay shows you understand the nuances of Kubernetes failure states and how they impact actual application downtime!


## Your company has a production application running on EKS, After a new deployment users start reporting intermittent 502/503 errors. CPU amd memory usage of the pods looks normal and pod are in running state how would you trouble shoot the issue step by step


# Troubleshooting Kubernetes 502/503 Errors with Healthy Pods

When Pods are running fine and CPU/memory usage look normal, but users are receiving **502 Bad Gateway** or **503 Service Unavailable** errors, the problem isn't the workload itself. It indicates a breakdown in the traffic path between the user and the Pod. 

To isolate the issue, work through the request path systematically from the outside in using this 6-step framework.

---

## 1. Verify Readiness Probes (Running ≠ Ready)
A Pod can be in a `Running` state but not actually be ready to serve traffic. 
* **The Risk:** If a readiness probe fails or flaps intermittently, Kubernetes pulls the Pod out of the Service endpoints. This creates an on-and-off traffic gap, resulting in intermittent 502 errors.
* **Action:** Run the following commands to inspect the `READY` column and check for flapping probes in the events:
  ```bash
  kubectl get pods
  kubectl describe pod <pod-name>


  If the endpoint list is empty or flickering, that's the smoking gun — traffic is being sent to nowhere, hence 502.

Third, I look at the Ingress or Load Balancer layer, since that's usually where 502/503 actually gets generated — not from the pod, but from whatever's in front of it. If it's an ALB Ingress Controller, I check the target group health in AWS directly, and check ALB access logs for the actual error codes and target response times. A 502 here usually means the target closed the connection or timed out; a 503 usually means no healthy targets were available at that moment.

Fourth, I think about what changed in the deployment. Since this started right after a new deployment, I'd check:

Did the rollout use a rolling update, and were old pods terminated before new ones were fully ready? That causes a brief gap where there aren't enough healthy endpoints.
Did the app change its port, health check path, or startup time, without the readiness probe or ingress config being updated to match?
Is there a graceful shutdown problem — old pods getting SIGTERM but still receiving traffic for a few seconds before they finish in-flight requests, causing dropped connections during termination?

Fifth, I check for resource limits I might be missing — not CPU/memory usage, but things like connection limits, thread pool exhaustion, or the app hitting max connections to a database and returning errors under load, even though the pod itself looks 'healthy' from Kubernetes' point of view.

Sixth, I check timing correlation — are the 502s constant, or do they spike specifically during pod restarts, scale-up/down events, or a specific time window? That tells me if it's a steady-state config issue or a rollout/scaling timing issue.

So basically — since the pod itself isn't the problem, I move outward: readiness and endpoints first, then ingress/load balancer, then what actually changed in the new deployment, and finally application-level connection handling. That covers almost every real-world cause of this exact symptom."

# Troubleshooting Kubernetes CrashLoopBackOff

**CrashLoopBackOff** means a container keeps crashing, and Kubernetes keeps trying to restart it, waiting longer between each subsequent attempt (exponential backoff). It is not the root cause itself—it is simply a symptom indicating that something underneath is broken.

---

## Initial Troubleshooting Steps

Before guessing the cause, run these two essential diagnostic commands to gather data:

1. **`kubectl describe pod <pod-name>`**  
   Look at the container's **Exit Code** and inspect the **Events** section at the bottom for structural or lifecycle errors.
2. **`kubectl logs <pod-name> --previous`**  
   Because the container keeps restarting, checking the standard logs only shows the current (booting) instance. The `--previous` flag pulls the logs from the specific container instance that just crashed.

---

## 6 Common Root Causes

Most `CrashLoopBackOff` issues fall into one of these six buckets:

### 1. Application-Level Errors
The code itself is throwing an unhandled exception or runtime error. This is frequently caused by missing environment variables, missing configuration files, or database connection failures. 
* **Diagnostic:** The application logs (`--previous`) will usually output a stack trace showing exactly what failed.

### 2. Resource Limitations (OOMKilled)
The container is attempting to use more memory than its defined resource limit allows, forcing Kubernetes to terminate it.
* **Diagnostic:** `kubectl describe pod` will show **Exit Code 137** and a termination reason of **OOMKilled**. 
* **Resolution:** Increase the memory `limits` in the Pod spec or debug the application for memory leaks.

### 3. Misconfigured Health Probes
The application is actually completely fine, but its **Liveness Probe** is too aggressive or strict. For example, if an application takes 40 seconds to fully boot up but the liveness probe starts checking after 10 seconds, Kubernetes will kill the healthy, booting container thinking it is deadlocked.
* **Resolution:** Use a **Startup Probe** (`startupProbe`) to give the container a safe buffer time to initialize before the standard liveness checks take over.

### 4. Image or Command Problems
This happens when you reference an incorrect image tag, or the container's startup command (`CMD` or `ENTRYPOINT`) exits immediately instead of running as a long-lived foreground process.
* **Diagnostic:** Often shows **Exit Code 0** (completed successfully) when Kubernetes expected a continuous running process.

### 5. Volume or Mount Issues
The container cannot start because its required dependencies are missing at the cluster level. This includes referencing a `ConfigMap` or `Secret` that hasn't been created yet, or trying to mount a `PersistentVolumeClaim` (PVC) that is not currently bound.

### 6. Init Container Failures
If the Pod relies on an `initContainer` to run setup tasks (like running database migrations or waiting for a dependency) and that init container keeps crashing, the main application container will never get the chance to start. 
* **Diagnostic:** The Pod status will show `CrashLoopBackOff`, but looking closer at the container states will show the error originated in the init container.

---

> **Summary Checklist:** Check the exit code and events first using `describe`, pull the `--previous` logs, and match the findings against these six buckets to quickly isolate the issue.
