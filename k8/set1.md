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


## 2. What happens when you execute `kubectl apply -f deployment.yaml`?

**Answer:**
When you run `kubectl apply -f deployment.yaml`, it triggers a highly coordinated workflow across the Kubernetes control plane and worker nodes to move your application from a declaration to a running state. 

Here is exactly what happens step-by-step:

### 1. Client-Side & Authentication (The Request)
* The `kubectl` CLI reads your local YAML manifest, validates it against client-side schemas, and sends it as an **HTTPS request** to the Kubernetes API Server.
* The API Server authenticates your identity (via tokens or certificates) and checks authorization rules using **RBAC (Role-Based Access Control)** to ensure you have permission to deploy.
* **Admission Controllers** then intercept the request to validate or mutate it (e.g., injecting sidecars or enforcing policy checks) if needed.
* Once fully accepted, the desired state of the deployment is securely written to **ETCD**.

### 2. Control Plane Orchestration (The Reconcile Loop)
* **Deployment Controller:** Detects the new Deployment object in ETCD and automatically creates a corresponding **ReplicaSet**.
* **ReplicaSet Controller:** Compares the desired number of replicas defined in your YAML against the current cluster state. Realizing pods are missing, it creates the required **Pod objects** in the API Server.
* **Scheduler:** Watches for newly created pods that don't have a node assigned to them. It evaluates all available worker nodes based on resources, taints, tolerations, and scheduling rules, selecting the most appropriate node for each Pod.

### 3. Node-Level Execution (The Realization)
* **Kubelet:** The Kubelet agent running on the selected worker node notices the pod assignment. It instructs the local **container runtime** (like `containerd` or `CRI-O`) to pull the container image from the registry (such as **Amazon ECR**) if it isn't already cached locally.
* **Container Lifecycle:** The runtime starts the containers. Once the Pods pass their health checks, the Kubelet reports their updated status back to the API Server, which updates ETCD.

### 4. Networking & Updates
* **Kube-Proxy:** Runs on every node and watches for changes to Services and Endpoints. It updates its routing rules (like iptables or IPVS) to ensure that cluster traffic is properly routed to the new Pods.
* **Rolling Updates:** If this action was an update to an existing deployment rather than a fresh install, Kubernetes handles the transition via a **rolling update**—gradually bringing up new Pods and ensuring they are healthy before terminating the old ones to avoid downtime.

---

### Summary of Responsibilities
* **`kubectl`:** Parses the manifest and initiates the API call.
* **API Server & ETCD:** Gatekeep the request and log the system's ground truth.
* **Controllers & Scheduler:** Determine *what* needs to be created and *where* it should live.
* **Kubelet & Runtime:** Physically fetch the images and spin up the containers.
* **Kube-Proxy:** Plumbs the network paths to expose the workloads.

> **Senior Signal:** Walking through the lifecycle of a `kubectl` command from the client API request down to the node runtime shows a comprehensive understanding of the Kubernetes architecture. Highlighting the separation between the **Scheduler** (which only chooses the node) and the **Kubelet** (which actually runs the runtime commands) is a key differentiator that separates senior engineers from those who treat Kubernetes like a black box.

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
Answer:
Whenever I troubleshoot production issues, I don't jump directly to the application. I follow the request path from the user to the application so I don't miss anything.

## Step 1: Verify the deployment
First, I verify whether the deployment completed successfully.


kubectl get deployment
Example:

Plaintext
NAME               READY   UP-TO-DATE   AVAILABLE
configurator-api   5/5     5            5
If the desired replicas aren't available, I inspect the deployment.

Bash
kubectl describe deployment configurator-api
I'm looking for:

Replica creation failures

Image pull failures

Probe failures

Recent rollout events

If everything looks good, I move on.

Step 2: Check Pod status
Next, I verify the Pods.

Bash
kubectl get pods -o wide
Example:

Plaintext
NAME                         READY   STATUS    RESTARTS
configurator-api-abc12       1/1     Running   0
configurator-api-def34       1/1     Running   0
Although the Pods are running, "Running" only means the container is running. It doesn't guarantee the application is healthy.

Step 3: Check Pod logs
Since this issue started immediately after a deployment, I inspect the application logs.

Bash
kubectl logs configurator-api-abc12
If there are multiple replicas:

Bash
kubectl logs configurator-api-abc12
kubectl logs configurator-api-def34
I'm looking for:

Database connection failures

NullPointerException

Timeouts

External API failures

Configuration errors

If the Pods restarted recently:

Bash
kubectl logs --previous configurator-api-abc12
Step 4: Verify Readiness Probe
This is one of the most common causes after deployments.
I check:

Bash
kubectl describe pod configurator-api-abc12
Example:

Plaintext
Readiness probe failed
HTTP probe failed with statuscode: 500
If the readiness probe is failing, Kubernetes removes that Pod from the Service endpoints.
If only some Pods are Ready and others are not, users may experience intermittent failures during rollouts or when capacity is reduced.

Step 5: Verify Service Endpoints
Now I verify which Pods the Service is actually routing traffic to.

Bash
kubectl get svc
Then:

Bash
kubectl describe svc configurator-api
or

Bash
kubectl get endpoints configurator-api
Example:

Plaintext
10.1.2.10:8080
10.1.2.11:8080
10.1.2.12:8080
If the endpoints list is empty, the Service has no healthy Pods to forward requests to.
That immediately explains a 503.

Step 6: Verify the Ingress
Now I inspect the Ingress.

Bash
kubectl get ingress
Then:

Bash
kubectl describe ingress configurator-api
I'm checking:

Correct Service name

Correct Service port

Correct host

Correct path rules

A wrong backend port is a very common issue after deployments.
For example, Application now listens on 8081 but Ingress still forwards to 8080.
The ALB cannot reach the application.

Step 7: Check ALB Target Health
Since we're using EKS with an AWS Application Load Balancer, I verify whether the targets are healthy.

AWS Console → EC2 → Target Groups → Health Status

or

Bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
Example:

Plaintext
Target        10.1.2.10
Unhealthy     Health check failed
If targets are unhealthy, the ALB returns: 503 Service Unavailable.
Now I know the problem is between the ALB and Kubernetes.

Step 8: Verify Health Check
I compare:

ALB Health Check: /health

Application: /actuator/health

Suppose developers changed /health to /healthz during the release.
The ALB keeps checking /health.
Every health check fails.
Targets become unhealthy.
Users receive 503 even though the Pods are running.

Step 9: Test the Service Internally
To isolate whether the issue is with the application or the load balancer, I test from inside the cluster.

Bash
kubectl run debug --rm -it --image=busybox -- sh
Inside the Pod:

Bash
wget -O- http://configurator-api:8080/actuator/health
or

Bash
curl http://configurator-api:8080/actuator/health
If this succeeds, the application is working inside Kubernetes.
Then I know the issue is probably:

ALB

Ingress

Security Group

Target Group

Step 10: Check Application Response Time
Sometimes the application is very slow after deployment.
The ALB waits only a certain amount of time before returning an error.

Application log Request Processing: 45 seconds

ALB Idle Timeout: 30 seconds

The client receives: 502 Bad Gateway.
The Pods still look healthy.

Step 11: Check Recent Deployment Changes
Since the issue started after deployment, I compare the new version with the previous one.
I check:

Environment variables

ConfigMaps

Secrets

Image tag

Resource limits

Health probes

Service port

Ingress configuration

If needed,

Bash
kubectl rollout history deployment configurator-api
If I suspect the deployment caused the issue, I can roll back.

Bash
kubectl rollout undo deployment configurator-api
If the errors disappear, I've confirmed the new deployment introduced the issue.
