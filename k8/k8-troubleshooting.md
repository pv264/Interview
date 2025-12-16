## 1. Pods are Running but Application is Not Reachable via Service
What’s really being tested
Service selectors
Endpoints
Networking basics
First, I’ll check whether the Service has endpoints using kubectl get endpoints <service-name>.
If endpoints are empty, it usually means the Service selector does not match the Pod labels.
I’ll verify labels on the pods using kubectl get pods --show-labels and compare them with the Service selector.
If labels match and endpoints exist, I’ll then check the Service type, targetPort vs containerPort, and finally test connectivity using a temporary debug pod with curl.”

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
