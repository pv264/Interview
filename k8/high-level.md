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

* **Optimize Resources:** Have sufficient free CPU and memory to easily handle the workload without hitting capacity 
ceilings.
* **Balance Workloads:** Effectively distribute workloads evenly across the cluster to avoid hot-spotting individual nodes.
* **Satisfy Topology Constraints:** Adhere to topology spread constraints to distribute Pods across different availability zones or racks for maximum fault tolerance.

**Final Action:** The node that scores the highest wins the selection. The Scheduler then updates the Pod specification with the selected node name and commits it back to the API Server.


# Explain kube-proxy in detail.

**kube-proxy** is a critical network component that runs on every worker node in a Kubernetes cluster. Its primary responsibility is to maintain network rules on nodes, enabling seamless communication between Services and Pods.

In Kubernetes, Pods are highly ephemeral and temporary. A Pod can crash, scale down, or be recreated with a completely new IP address. If client applications communicated directly with Pod IPs, every Pod restart would break the connection. To solve this, Kubernetes uses **Services**, which provide a stable, permanent virtual IP (ClusterIP). `kube-proxy` is the engine that makes this Service IP work under the hood by intercepting and forwarding traffic to the correct backend Pods.

## How kube-proxy Works (The Mechanics)

`kube-proxy` operates as a control-plane watcher on the local worker nodes:

1. **Watches the API Server:** It continuously monitors the Kubernetes API Server for any additions, modifications, or deletions of **Service** and **Endpoints** (or `EndpointSlice`) objects.
2. **Updates Local Network Rules:** When a Service or Endpoint changes (e.g., a new Pod is added to a Deployment), `kube-proxy` intercepts the change and updates the internal routing rules directly on its host worker node.
3. **Traffic Interception:** When traffic hits the node bound for a Service's virtual ClusterIP, the node's native routing mechanisms (configured by `kube-proxy`) rewrite the destination IP to a valid, healthy backend Pod IP instead.

## Modes of Operation

`kube-proxy` can configure node routing using different underlying networking modes. The two most common in production environments are:

### 1. iptables Mode (Default)
In this mode, `kube-proxy` writes standard Linux **iptables** rules into the node's netfilter subsystem.
* **Traffic Routing:** When traffic targets a Service IP, iptables randomly selects a healthy backend Pod from the Endpoints list using a sequential rule check and executes a Destination Network Address Translation (DNAT).
* **Limitations:** iptables checks rules sequentially. If a cluster grows to thousands of Services and Pods, the massive list of sequential routing rules causes performance degradation and higher CPU consumption on the nodes.

### 2. IPVS Mode (IP Virtual Server)
Designed specifically for large-scale production environments and clusters containing thousands of services.
* **Traffic Routing:** IPVS is built directly into the Linux kernel and uses hash tables rather than sequential lists. This provides $O(1)$ lookup times regardless of cluster size.
* **Advantages:** It supports more advanced load-balancing algorithms (e.g., least connection, shortest expected delay, round-robin) and handles high-throughput traffic with significantly lower latency and overhead compared to iptables.

### 3. Userspace Mode (Legacy)
An older, obsolete mode where `kube-proxy` acted as an actual proxy server in the userspace, routing traffic back and forth across the kernel/userspace boundary. This added extreme latency and context-switching overhead, and is no longer used in modern clusters.


# Understanding CoreDNS in Kubernetes

**CoreDNS** is the DNS server used inside a Kubernetes cluster. Its main responsibility is to provide **service discovery**. Instead of applications communicating using IP addresses, they communicate using DNS names.

## The Problem: Ephemeral Pod IPs
This is important because Pod IP addresses are temporary. Whenever a Pod is deleted and recreated, it gets a completely new IP address. 

For example:
* **Today:** `payment-pod` is at `10.244.1.20`
* **Tomorrow (after restart):** `payment-pod` is at `10.244.2.20`

Because the IP constantly changes, if every application relied directly on Pod IPs, the application network would constantly break.

## The Solution: Services and DNS
To solve this, Kubernetes uses **Services**, which are assigned stable, permanent DNS names. 
* Applications communicate using this stable DNS name instead of the ephemeral Pod IP.
* **CoreDNS** acts as the translator, resolving this DNS name to the correct Service IP.

## How CoreDNS Automates Service Discovery
CoreDNS continuously watches the Kubernetes **API Server** to keep its routing information accurate:

1. **Service Creation:** Whenever a new Service is created, the API Server stores its desired state in `etcd`.
2. **Automatic Updates:** CoreDNS detects this change through the API Server and updates its internal DNS records automatically. 
3. **Seamless Discovery:** Whenever a Service is added, deleted, or modified, CoreDNS updates its records without requiring any manual configuration.


# Container Network Interface (CNI) and Pod Networking

**CNI** stands for **Container Network Interface**. It is a standard interface that allows Kubernetes to configure networking for Pods. 

One important thing to understand is that Kubernetes itself does not implement networking. Kubernetes only defines *how* networking should work. The actual implementation is handled by a CNI plugin.

## Popular CNI Plugins

There are several widely used CNI plugins, depending on the environment and requirements:
* **Calico**
* **Cilium**
* **Flannel**
* **Weave Net**
* **AWS VPC CNI** (used in Amazon EKS)
* **Azure CNI** (used in Microsoft AKS)

## How It Works

When a new Pod is created, Kubernetes does not assign the IP address or set up the network routes itself. Instead, it delegates this task. Kubernetes asks the configured CNI plugin to configure the networking for that specific Pod, ensuring it gets a valid IP address and can communicate with other Pods across the cluster.
