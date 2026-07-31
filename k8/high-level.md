# Kubernetes Control Plane Components

The Kubernetes control plane is basically the brain of the Kubernetes cluster. Its job is to receive requests, decide what should happen, store the cluster state, and ensure that the actual cluster always matches the desired state. 

The main control plane components are the API Server, Scheduler, Controller Manager, etcd, and Cloud Controller Manager. Let me explain each one.

## 1. API Server
The API Server is the entry point to the Kubernetes cluster. Every request, whether it's from a user, `kubectl`, Helm, ArgoCD, Jenkins, or even internal Kubernetes components like the Scheduler and Controller Manager, goes through the API Server.

The API Server performs several checks:
* It authenticates the user to verify who is making the request.
* It authorizes the request using RBAC to check whether the user has permission.
* It validates the YAML to ensure it's a valid Kubernetes object.

If everything is correct, it stores the desired state in etcd. 

One important point is that the API Server doesn't create Pods itself. It only accepts the request and records the desired state. 

If the API Server goes down, the existing Pods continue running because they're already running on the worker nodes. However, no new changes can be made. We cannot create Pods, delete resources, scale Deployments, or use `kubectl`, because every operation depends on the API Server.

## 2. Scheduler
Once the API Server stores the Deployment, the next component involved is the Scheduler. 

The Scheduler's responsibility is to decide which worker node should run each new Pod. It constantly watches for Pods that don't yet have a node assigned. 

When it finds one, it evaluates all available worker nodes by checking:
* Available CPU and memory
* Resource requests
* Node labels and selectors
* Node Affinity and Pod Affinity rules
* Taints and Tolerations
* Topology constraints

Based on these factors, it selects the most suitable node and tells the API Server which node the Pod should run on. 

The Scheduler doesn't start the Pod. It only assigns a node. For example, if I have three worker nodes and one of them doesn't have enough CPU, the Scheduler skips that node and chooses another with sufficient resources. 

If the Scheduler goes down, existing Pods continue running normally, but any new Pods remain in the Pending state because no one is assigning them to a worker node.

## 3. Controller Manager
The Controller Manager is responsible for maintaining the desired state of the cluster. 

It continuously compares:
* What the user wants (desired state)
* What is actually running (current state)

If there's any difference, it works to correct it. For example, suppose I create a Deployment with 3 replicas. Initially, only two Pods are running because one Pod crashed. The Controller Manager notices that the actual state is two Pods while the desired state is three Pods. It immediately creates another Pod to restore the replica count back to three. This process is called the reconciliation loop.

The Controller Manager actually contains several controllers, such as:
* Deployment Controller
* ReplicaSet Controller
* Node Controller
* Job Controller
* CronJob Controller

Each controller is responsible for maintaining a different Kubernetes resource. 

If the Controller Manager goes down, running Pods continue to work, but Kubernetes stops correcting problems. Failed Pods won't be recreated, Deployments won't progress, and Jobs or CronJobs won't be managed.

## 4. etcd
etcd is the database of Kubernetes. 

It stores the complete cluster state. Whenever we create a Deployment, Service, Secret, ConfigMap, Namespace, or any Kubernetes object, the information is stored in etcd. 

Because etcd contains the entire cluster state, it is one of the most critical components in Kubernetes. 

If etcd goes down, the API Server cannot read or write cluster information. Existing Pods may continue running for some time, but no new changes can be made, making the cluster effectively unmanageable.

## 5. Cloud Controller Manager
The Cloud Controller Manager is mainly used in managed Kubernetes services like Amazon EKS, Azure AKS, and Google GKE. 

Its responsibility is to connect Kubernetes with the cloud provider.


# 2 What Happens if the API Server Goes Down?

The API Server is the entry point to the Kubernetes control plane. Every request to the cluster goes through it, whether it's from `kubectl`, the Scheduler, the Controller Manager, ArgoCD, Helm, or the kubelets.

If the API Server goes down, the impact depends on what's already running.

The good news is that existing applications usually continue to run. The Pods that are already running on the worker nodes are not immediately affected because the kubelet and the container runtime continue running the containers locally.

However, all control plane operations are affected because every component depends on the API Server. For example:

* If I run `kubectl get pods`, it fails because `kubectl` cannot communicate with the API Server.
* I cannot create new Deployments or Pods.
* I cannot scale an application.
* ArgoCD or Jenkins cannot deploy new versions.
* The Scheduler cannot assign newly created Pods to nodes because it communicates through the API Server.
* The Controller Manager cannot update or reconcile cluster objects through the API Server.

So if a Pod crashes during this period, Kubernetes may not be able to recreate it because updating cluster state requires the API Server.


# What Happens if etcd Becomes Unavailable?

**etcd** is the database of the Kubernetes cluster. It stores the entire cluster state, such as Pods, Deployments, Services, Secrets, ConfigMaps, Nodes, RBAC objects, and almost every Kubernetes resource.

The API Server does not store any cluster information itself. Whenever it needs to read or update the cluster state, it communicates with etcd. So, if etcd becomes unavailable, the API Server loses access to the cluster's data.

## Impact on the Cluster

Let's say we already have an application running with 10 Pods. If etcd suddenly goes down:

The existing Pods usually continue running because they're already running on the worker nodes. However, the control plane cannot read or update the cluster state anymore. 

As a result:
* We cannot create new Pods or Deployments.
* We cannot scale applications.
* We cannot delete or modify resources.
* `kubectl get pods` may fail or return stale information because the API Server cannot retrieve the latest state from etcd.
* The Scheduler cannot schedule new Pods.
* The Controller Manager cannot reconcile resources because it also depends on the API Server, which depends on etcd.

So, the cluster becomes unmanageable, even though the existing workloads may continue running for some time.


# How the Kubernetes Scheduler Selects a Node

The Scheduler's responsibility is to assign a newly created Pod to the most suitable worker node. 

When you create a Deployment, the Controller Manager generates the required Pod objects. Initially, these Pods do not have a node assigned, so their status remains `Pending`. The Scheduler continuously watches for these unscheduled Pods through the API Server.

Once it identifies an unscheduled Pod, it follows a strict two-step process to determine the best placement:
1. **Filtering** – It removes nodes that cannot run the Pod.
2. **Scoring** – It ranks the remaining nodes and chooses the absolute best fit.

---

## Step 1: Filtering (Can this node run the Pod?)
The Scheduler evaluates every worker node in the cluster and eliminates the ones that fail to meet the Pod's hard requirements. Key checks include:

* **Available CPU and Memory:** Does the node have enough allocatable resource capacity to satisfy the Pod's resource requests?
* **Node Selector:** Does the node possess the specific labels requested by the Pod's `nodeSelector` or node affinity configurations?
* **Taints and Tolerations:** Does the node have a taint that the Pod does not explicitly tolerate?

## Step 2: Scoring (Which node is the best fit?)
If multiple nodes successfully pass the filtering stage, the Scheduler assigns a score to each remaining node based on standard scheduling policies. It scores nodes higher if they:

* **Optimize Resources:** Have sufficient free CPU and memory to easily handle the workload without hitting capacity ceilings.
* **Balance Workloads:** Effectively distribute workloads evenly across the cluster to avoid hot-spotting individual nodes.
* **Satisfy Topology Constraints:** Adhere to topology spread constraints to distribute Pods across different availability zones or racks for maximum fault tolerance.

**Final Action:** The node that scores the highest wins the selection. The Scheduler then updates the Pod specification with the selected node name and commits it back to the API Server.
