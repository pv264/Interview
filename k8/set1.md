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
