# A Pod is stuck in Pending — walk through your debugging steps.

If I see a Pod stuck in the Pending state, my first thought is that the Kubernetes Scheduler was unable to place the Pod on any worker node. Since the Pod is still in the Pending state, I know the container hasn't started yet, so I don't waste time checking application logs. The issue is most likely related to scheduling rather than the application itself.

My first step is to check the Pod status to confirm it's actually in the Pending state:

kubectl get pods -n <namespace>

Once I confirm that, the first command I run is:

kubectl describe pod <pod-name> -n <namespace>


I mainly focus on the Events section because it usually tells me why the Scheduler couldn't place the Pod. For example, I might see messages like Insufficient CPU, Insufficient memory, 0/3 nodes match node selector, node had taint that the Pod didn't tolerate, or pod has unbound PersistentVolumeClaims. That immediately points me toward the root cause.

Troubleshooting by Root Cause
1. Insufficient CPU or Memory
If the Events show insufficient CPU or memory, I verify the available resources on the worker nodes by running:

kubectl top nodes

This shows the current CPU and memory utilization of each node. I then compare that with the resource requests defined in the Deployment to see whether the Pod is requesting more resources than any node can provide.




# Troubleshooting Pods in CrashLoopBackOff

If a Pod is in `CrashLoopBackOff`, it means Kubernetes successfully scheduled the Pod and started the container, but the application keeps crashing, so Kubernetes repeatedly restarts it with an increasing backoff delay. 

## Step 1: Check Pod Details and Events
My first step is to inspect the Pod configuration and lifecycle events to check the restart count, last container state, exit code, and Events:


kubectl describe pod <pod-name> -n <namespace>


## Step 2: Inspect the Application Logs
Next, I check the application logs to find out why the process is failing:

Bash
kubectl logs <pod-name> -n <namespace>


Common Root Causes to Investigate
Based on the evidence gathered from the logs and describe output, I investigate issues such as:

Configuration Errors: Incorrect ConfigMaps or Secrets, or missing environment variables.

Connectivity Issues: Failure to connect to dependent services like a database or Redis.

Health Check Failures: Misconfigured or failing liveness/readiness probes.



# Troubleshooting: A Pod is Running but the app inside isn't reachable via the Service — where do you look first?

If a Pod is Running but the application isn't reachable through the Service, my first step is to verify whether the Pod is actually Ready by checking:


kubectl get pods


If a Pod is Running but the application isn't reachable through the Service, my first step is to verify whether the Pod is actually Ready by checking kubectl get pods. A Running Pod with 0/1 READY won't receive traffic because the readiness probe hasn't passed. If the Pod is Ready, I inspect the Service using <b>kubectl describe svc<b> to verify its selector, port, and targetPort. Then I check the Endpoints with kubectl get endpoints, because if the Endpoints list is empty, it usually means the Service selector doesn't match the Pod labels or the Pods aren't Ready. If Endpoints are present, I verify that the application's listening port matches the Service's targetPort, review the application logs, and test connectivity from another Pod. If everything looks correct, I investigate NetworkPolicies or, for external traffic, the Ingress and ALB configuration. In our EKS environment, I've seen issues where the Service selector didn't match the Deployment labels after a release, resulting in no Endpoints. Correcting the labels immediately restored traffic without restarting the application.
