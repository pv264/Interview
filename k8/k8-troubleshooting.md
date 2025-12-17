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
What’s being tested
Exit codes
Liveness probes
App startup behavior
CrashLoopBackOff doesn’t always mean the app is failing.
I’ll first check the container exit code using kubectl describe pod.
If exit code is 0 or the logs look normal, I suspect a failing liveness probe.
I’ll verify probe configuration, initialDelaySeconds, timeoutSeconds, and whether the app is actually ready when the probe runs.
Often, aggressive liveness probes kill healthy containers during startup.”

## 3. Kubernetes Node is NotReady Intermittently
What’s being tested
Node health
kubelet
system resources
“I’ll start by describing the node to see conditions using kubectl describe node.
Common causes are disk pressure, memory pressure, or kubelet issues.
Then I’ll SSH into the node and check kubelet status, disk usage, and system logs.
If disk pressure is the issue, I’ll look for container logs or unused images consuming space.
Intermittent NotReady usually points to resource exhaustion or network instability.”

## 4. Deployment Rollout is Stuck and Never Completes
A rollout usually gets stuck because new pods are never becoming Ready.
I’ll run kubectl rollout status deployment and then inspect the new pods.
Most of the time, the readiness probe is failing or the app is waiting for a dependency like a database.
Until readiness passes, Kubernetes won’t terminate old pods, so the rollout remains stuck.”

## 5.Pod Cannot Pull Image but Node Has Internet Access
“First, I’ll check the exact error using kubectl describe pod.
If it’s an authentication error, I’ll verify the ImagePullSecret is created in the same namespace and referenced correctly in the pod spec.
If it’s a cloud registry like ECR, I’ll ensure the node IAM role has permission to pull images.
Internet access alone is not enough — registry auth is mandatory.”

## 6. High Pod Restarts but No Errors in Logs
 When logs are clean, I immediately suspect OOMKilled.
I’ll check pod events and container state for OOMKilled.
If memory limits are too low, the kernel kills the process without app-level logs.
The fix is either increasing memory limits or optimizing application memory usage.

## 7.Requests Are Slow Even Though Pods and Nodes Are Healthy
“I’ll first check CPU limits.
Even if CPU usage looks low, strict CPU limits can cause throttling.
Using kubectl top pod and metrics, I’ll verify if pods are CPU throttled.
Often removing CPU limits or setting proper requests improves latency significantly.”

## 8. Service Works Inside Cluster but Fails Externally
“If it works internally, the app and service are fine.
I’ll then focus on the ingress or external load balancer.
I’ll check listener ports, target group health checks, and security group rules.
In cloud environments, missing inbound rules is a very common issue.”

## 9.Pods Can’t Communicate Across Namespaces
By default, Kubernetes allows cross-namespace communication.
If it’s failing, I immediately suspect NetworkPolicies.
I’ll check if there’s a deny-all policy applied and whether the required namespace selectors are missing.
NetworkPolicies are namespace-scoped, so explicit allow rules are required once policies are enabled.”
