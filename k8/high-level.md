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
