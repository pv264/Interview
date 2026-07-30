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

Taints and Tolerations

If the Events mention taints and tolerations, I inspect the node configuration using:

kubectl describe node <node-name>

to see whether the node has a NoSchedule taint and whether the Pod has the corresponding toleration.
