## Explain what happens end-to-end when you run kubectl apply -f deployment.yaml (API server → etcd → scheduler → kubelet → container runtime).
When I run `kubectl apply -f deployment.yaml`, the lifecycle of the resource progresses through the following stages:

## 1. Authentication, Validation, and Storage (API Server → etcd)
* `kubectl` acts as a client and sends the Deployment manifest to the Kubernetes **API Server** over HTTPS.
* The **API Server** validates the request, including the manifest, authentication, authorization through RBAC, and resource schema.
* If everything is valid, it stores the Deployment object as the desired state in **etcd**, which is Kubernetes' persistent key-value store.

## 2. Resource Orchestration (Controllers)
* The **Deployment Controller** notices the new Deployment and creates a ReplicaSet.
* The **ReplicaSet Controller** compares the desired number of replicas with the current state and creates the required Pod objects. These Pods are initially unscheduled.

## 3. Node Assignment (Scheduler)
* The **Scheduler** detects Pods without an assigned node and evaluates all worker nodes based on factors such as available CPU and memory, taints and tolerations, node affinity, and other scheduling constraints.
* It selects the most suitable node and records that decision in the Pod specification.

## 4. Execution (Kubelet → Container Runtime)
* The **kubelet** running on the chosen worker node watches the API Server, sees that a Pod has been assigned to it, and instructs the **container runtime**, such as `containerd`, to create the Pod.
* The **container runtime** pulls the image from the registry if needed, creates the container, and starts the application.

## 5. Traffic Routing (Readiness Probes & Endpoints)
* Once the application starts, the **kubelet** performs the configured readiness probe.
* After the probe succeeds, Kubernetes marks the Pod as **Ready**.
* The **Endpoints Controller** adds the Pod's IP address to the Service endpoints, allowing the Service—and, in our environment, the Ingress and ALB—to begin routing traffic to the new Pod.



# How do Helm charts help with deployment management, and what's the difference between Helm and raw kubectl apply manifests?

**Helm** is the package manager for Kubernetes. Instead of creating and managing multiple Kubernetes YAML files individually, Helm allows us to group all those resources into a single package called a **Helm Chart**. 

A Helm Chart usually contains:
* Templates for resources such as `Deployments`, `Services`, `Ingresses`, `ConfigMaps`, and `HPAs`.
* A `values.yaml` file where we define environment-specific values like the image tag, replica count, resource limits, and hostnames.

During deployment, Helm replaces the placeholders in the templates with the values from `values.yaml`, generates the final Kubernetes manifests, and sends them to the Kubernetes API Server.

## CI/CD Workflow with Helm and ArgoCD

In our EKS environment, we use Helm together with **ArgoCD**:
1. When a developer pushes code, **Jenkins** builds a new Docker image and pushes it to **AWS ECR**.
2. Jenkins then updates the image tag in the Helm `values.yaml` file and commits that change to the Git repository.
3. **ArgoCD** continuously watches the repository, detects the updated Helm chart, renders the templates using the new values, and deploys the generated Kubernetes manifests to the EKS cluster.

This allows us to use the same Helm Chart across development, SIT, UAT, and production while changing only the values file for each environment.

## Helm vs. Raw `kubectl apply` Manifests

Compared to using raw `kubectl apply` manifests, Helm makes deployments much easier to manage:

* **Raw Manifests:** We have to maintain and update each YAML file separately, which becomes difficult as the number of microservices and environments grows.
* **Helm:** Solves this by providing reusable templates, environment-specific configuration through `values.yaml`, built-in release history, and easy upgrades or rollbacks using Helm commands.

Ultimately, Helm makes deployments more consistent, scalable, and easier to maintain in production environments.

# How would you design a multi-environment (dev/staging/prod) deployment strategy using Kustomize or Helm value overrides?


# Multi-Environment Deployment Strategy: Helm vs. Kustomize

For a multi-environment deployment strategy, I prefer using a single reusable Helm chart with separate values files for each environment, such as `values-dev.yaml`, `values-sit.yaml`, `values-uat.yaml`, and `values-prod.yaml`. The Helm templates remain the same across all environments, while the values files contain environment-specific settings like:
* Replica count
* Image tag
* Resource limits
* Ingress hostname
* Autoscaling configuration

This avoids maintaining separate Kubernetes manifests for each environment.

## CI/CD Workflow in EKS

In our EKS environment, **Jenkins** builds the Docker image, pushes it to **AWS ECR**, and updates the image tag in the appropriate Helm values file. 

**ArgoCD** watches the Git repository, detects the change, renders the Helm chart with the corresponding values file, and deploys it to the correct Kubernetes cluster or namespace. As the application moves from development to production, we reuse the same chart and only change the environment-specific values, ensuring consistency across deployments while allowing each environment to have its own configuration.

## Alternative Approach: Kustomize

If I were using **Kustomize** instead, I would maintain a common base configuration and create separate overlays for development, staging, and production. Each overlay would patch only the differences, such as replica count, image tag, or ingress hostname. 

## Conclusion

Both approaches reduce duplication, but in our environment **Helm** is the better fit because we already use Helm charts with ArgoCD and benefit from templating, release management, and easy upgrades.


 # What's your approach to Horizontal Pod Autoscaling (HPA) — what metrics would you scale on for a typical microservice?


 # Horizontal Pod Autoscaling (HPA) Strategy

My approach to Horizontal Pod Autoscaling (HPA) depends on the workload rather than always using CPU. HPA automatically adjusts the number of Pods based on observed metrics, but the right metric should reflect the application's bottleneck. 

## Scaling a Typical Microservice

For a typical stateless Spring Boot microservice, **CPU utilization** is a good starting point because CPU usage generally increases as request volume grows. I would configure:
* A minimum of two replicas for high availability
* A reasonable maximum based on cluster capacity
* A CPU target around 70%

## Beyond CPU: Identifying Workload-Specific Bottlenecks

I don't assume CPU is always the best metric. The key is to choose a metric that represents the workload's true bottleneck rather than using CPU by default:

* **Request Rate:** In one of our AI workloads, requests spent significant time waiting for Milvus searches and vLLM inference, so CPU stayed relatively low even though user response times increased. In that case, scaling based on request rate—such as ALB `RequestCountPerTarget`—was much more effective because it reflected actual user demand.
* **Alternative Metrics:** For other workloads, I might scale on memory, queue depth, or custom Prometheus metrics such as request latency, depending on what truly limits the application's performance.





# Kubernetes Pod Pending — Storage Troubleshooting

## Question

A kubernetes pod is stuck in pending state due to a storage related issue what possible cause would you investigate and how would you troubleshoot the issue

---

If a Kubernetes Pod is stuck in `Pending` state and the issue appears to be storage-related, I would first determine whether the problem is with **PVC provisioning, PV binding, storage class, CSI driver, or volume attachment/mounting**.

I would troubleshoot it step by step.

### 1. Check the Pod status and events

First:

```bash
kubectl get pod <pod-name> -n <namespace>
```

Then:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

The most important section is:

```text
Events:
```

For example, I might see:

```text
FailedScheduling
pod has unbound immediate PersistentVolumeClaims
```

or:

```text
FailedMount
MountVolume.SetUp failed
```

or:

```text
FailedAttachVolume
```

The event message usually tells me which layer I need to investigate.

---

### 2. Check the PVC

I would check:

```bash
kubectl get pvc -n <namespace>
```

For example:

```text
NAME          STATUS    VOLUME
app-storage   Pending
```

If the PVC is `Pending`, I would investigate why it hasn't been bound to a PV.

Then:

```bash
kubectl describe pvc app-storage -n <namespace>
```

I would check the events for messages such as:

```text
no persistent volumes available
storageclass not found
failed to provision volume
insufficient capacity
```

---

### 3. Check the StorageClass

I would verify which StorageClass the PVC is requesting:

```bash
kubectl get pvc app-storage -n <namespace> -o yaml
```

Look for:

```text
storageClassName: gp3
```

Then check:

```bash
kubectl get storageclass
```

And:

```bash
kubectl describe storageclass gp3
```

I would verify:

- StorageClass exists
- Provisioner is correct
- Parameters are correct
- `volumeBindingMode` is appropriate

For example:

```text
provisioner: ebs.csi.aws.com
```

for AWS EBS CSI.

---

### 4. Check whether the PV exists

If the environment uses statically provisioned volumes:

```bash
kubectl get pv
```

Then:

```bash
kubectl describe pv <pv-name>
```

I would check:

- PV status
- Capacity
- Access modes
- StorageClass
- Reclaim policy
- Claim reference

The PVC and PV must have compatible requirements.

For example:

```text
PVC:
Storage: 100Gi
AccessMode: ReadWriteOnce

PV:
Storage: 50Gi
```

The PVC cannot bind to that PV because the PV doesn't have enough capacity.

---

### 5. Check access modes

I would verify whether the application requires:

```text
ReadWriteOnce (RWO)
ReadOnlyMany (ROX)
ReadWriteMany (RWX)
```

For example, if multiple Pods running on different nodes need to write to the same volume, but I'm using an EBS volume with `ReadWriteOnce`, that can cause attachment/mounting problems.

In AWS:

```text
EBS → generally RWO
EFS → can support RWX
```

So I would make sure the storage technology matches the application's access requirements.

---

### 6. Check the CSI driver

In AWS EKS, I would verify that the EBS/EFS CSI driver is installed and healthy.

For example:

```bash
kubectl get pods -n kube-system | grep ebs-csi
```

I would also check:

```bash
kubectl get csidrivers
```

For EBS:

```bash
kubectl describe csidriver ebs.csi.aws.com
```

If the CSI controller or node components are unhealthy, dynamic volume provisioning or attachment may fail.

I would check their logs:

```bash
kubectl logs -n kube-system \
  deployment/ebs-csi-controller \
  -c ebs-plugin
```

The exact controller/pod name can vary depending on how the driver was installed.

---

### 7. Check CSI controller events/logs

If the PVC is stuck in `Pending`, I would look for errors such as:

```text
failed to provision volume
```

or:

```text
UnauthorizedOperation
```

or:

```text
CreateVolume failed
```

This could indicate an IAM issue.

For EKS, the EBS CSI driver needs appropriate AWS permissions to create and manage EBS volumes.

I would therefore check the driver's IAM role/IRSA configuration as well.

---

### 8. Check the Kubernetes node

If the PVC is already bound but the Pod is still pending or stuck during startup, I would check the node:

```bash
kubectl get nodes
```

Then:

```bash
kubectl describe node <node-name>
```

I would look for:

- Disk pressure
- Node conditions
- Volume limits
- Taints
- Allocatable resources

For example:

```text
DiskPressure=True
```

could indicate that the node is running out of local disk space.

---

### 9. Check volume attachment

If the volume is provisioned but cannot attach to the node:

```bash
kubectl get volumeattachment
```

Then:

```bash
kubectl describe volumeattachment <volumeattachment-name>
```

I would look for errors such as:

```text
Multi-Attach error
```

This can happen when an RWO volume is already attached to another node.

For example:

```text
Node-A
  |
  EBS Volume
  |
Pod-1

Pod-2 scheduled on Node-B
       |
       ↓
Cannot attach same RWO EBS volume
```

I would determine whether the old Pod/node still holds the attachment and resolve it safely.

---

### 10. Check AWS EBS itself

Since this is AWS, I would also verify the EBS volume:

```bash
aws ec2 describe-volumes \
  --volume-ids <volume-id>
```

I would check:

- Volume state
- Availability Zone
- Size
- Volume type
- Attachment state

A very important issue is **AZ mismatch**.

For example:

```text
EBS volume → us-east-1a
Node → us-east-1b
```

EBS volumes are AZ-specific, so the volume cannot simply attach to a node in another AZ.

This is one reason the EBS CSI driver's topology-aware provisioning and the StorageClass `volumeBindingMode` are important.

---

### 11. Check `WaitForFirstConsumer`

If the StorageClass uses:

```text
volumeBindingMode: WaitForFirstConsumer
```

the volume isn't provisioned until Kubernetes knows which node/AZ the Pod will run on.

This is useful for topology-aware storage such as EBS.

I would check:

```bash
kubectl describe storageclass <storage-class>
```

If the workload has node selectors, affinity, or topology constraints, I would make sure they aren't preventing the scheduler from finding a suitable node/AZ.

---

### 12. Check node volume limits

EC2 instance types have limits on the number of EBS volumes that can be attached.

If a node has reached its volume attachment limit, another Pod requiring an EBS volume may fail to attach.

I would check the Pod events:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

and look for errors related to:

```text
volume limit
```

or:

```text
maximum volume count
```

If that's the problem, I could schedule the workload on another suitable node or use an appropriate instance type/node group.

---

### 13. Check Pod scheduling constraints

I would also verify that the Pod can actually be scheduled onto a node where the volume can be used.

For example:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

I would check for:

- Node affinity
- Node selector
- Taints/tolerations
- Resource requests
- Topology constraints

Storage can interact with scheduling.

For example, if the EBS volume is in `us-east-1a` but the Pod is restricted to nodes in `us-east-1b`, Kubernetes cannot satisfy both requirements.

---

### Possible root causes I would investigate

| Problem | What I would check |
|---|---|
| PVC Pending | `kubectl describe pvc` |
| No matching PV | `kubectl get pv` |
| StorageClass missing | `kubectl get storageclass` |
| CSI driver unhealthy | CSI pods/logs |
| IAM issue | CSI driver's IAM/IRSA |
| EBS AZ mismatch | Node AZ vs volume AZ |
| Volume already attached | `kubectl get volumeattachment` |
| RWO multi-attach | Pod/node/volume relationship |
| Node volume limit | Node/Pod events |
| Disk pressure | `kubectl describe node` |
| Storage quota/capacity | Cloud/provider limits |
| Wrong access mode | PVC/PV access modes |
| Topology constraint | StorageClass/node affinity |
| Provisioning failure | CSI controller logs/events |

### How I would explain it in the interview

> "If a Pod is stuck in Pending because of a storage issue, I would first run `kubectl describe pod` and check the Events section to determine whether the issue is PVC provisioning, volume binding, scheduling, or attachment.
>
> I would then check the PVC using `kubectl get pvc` and `kubectl describe pvc`. If the PVC is Pending, I would check the StorageClass, PV availability, CSI provisioner and its logs. If the PVC is already Bound, I would investigate volume attachment and mounting.
>
> Since this is an AWS environment, I would specifically check the EBS CSI driver, its IAM permissions, the EBS volume's Availability Zone, volume attachment state, and whether the node has reached its EBS volume attachment limit. I would also check for RWO multi-attach issues and topology constraints.
>
> I would use commands such as `kubectl describe pod`, `kubectl describe pvc`, `kubectl get pv`, `kubectl get storageclass`, `kubectl get volumeattachment`, and CSI driver logs. If required, I would use `aws ec2 describe-volumes` to verify the actual EBS volume state.
>
> Once I identify the specific failure—for example, an AZ mismatch, CSI IAM issue, stuck volume attachment, or insufficient storage capacity—I would fix that underlying issue and then verify that the PVC becomes Bound, the volume attaches successfully, and the Pod reaches Running and Ready state."
