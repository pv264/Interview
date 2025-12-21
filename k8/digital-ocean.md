# Kubernetes General Questions & Concepts

## 1. How to access a Service externally using NodePort?
To access a Kubernetes service externally using **NodePort**:

1.  **Create Service:** Create a Service of type `NodePort`.
2.  **Port Allocation:** Kubernetes exposes the application on a port between **30000 and 32767** on *every* node’s IP.
3.  **Access:** External users access the application using `<NodeIP>:<NodePort>`.
4.  **Routing:** `kube-proxy` receives the traffic on that port and routes it to the backend pods.

[Image of Kubernetes NodePort Service diagram]

## 2. How to check the health status of worker nodes?
1.  **Check Status:** Start with `kubectl get nodes` to verify their **Ready** status.
2.  **Describe:** Run `kubectl describe node <node-name>` to analyze conditions like memory, disk, and network availability.
3.  **Deep Dive:** If required, SSH into the node to check `kubelet` status, resource usage, and system logs.
4.  **Taints:** Note that Kubernetes automatically **taints** unhealthy nodes (e.g., `node.kubernetes.io/unreachable`), which prevents scheduling on them.

## 3. Is ResourceQuota attached to a Pod or a Container?
**Namespace Level.**
* `ResourceQuota` is applied at the **Namespace** level, not to individual pods or containers.
* It limits the *total* amount of resources (CPU, Memory, Storage) that all pods and containers in that namespace combined can consume.
* Pods/containers are affected indirectly because if the quota is full, new pods cannot be scheduled.

## 4. What is Gateway API?
**Gateway API** is a modern Kubernetes networking API designed to replace/evolve Ingress.
* **Role:** Provides explicit traffic entry points, advanced routing features, and strong role separation.
* **Components:** It splits configuration into `GatewayClass` (Infra provider), `Gateway` (Cluster Admin), and `HTTPRoute` (App Developer).
* **Use Case:** Designed for large-scale, multi-team, and production-grade environments.

[Image of Kubernetes Gateway API architecture]

## 5. How does every pod get a unique IP address?
* **CNI Plugin:** Every pod gets a unique IP through the **CNI (Container Network Interface)** plugin (e.g., Calico, Flannel, AWS VPC CNI).
* **Process:** When a pod is scheduled, the `kubelet` calls the CNI, which allocates an IP from the node’s assigned **Pod CIDR** range.
* **No NAT:** This design allows all pods to communicate directly with each other without NAT (Network Address Translation), which is a fundamental Kubernetes networking principle.

## 6. Is PVC attached to a Pod or a Container?
**Pod Level.**
* A **PersistentVolumeClaim (PVC)** is attached at the **Pod** level.
* The Pod specification references the PVC to request storage.
* **Containers:** Individual containers inside the pod then *mount* that volume to a specific path.
* *Distinction:* A **PersistentVolume (PV)** is the actual cluster storage resource, while the **PVC** is the request for that storage.

## 7. How does Scaling work in Kubernetes?
Scaling works at two distinct levels:

1.  **Pod Scaling (Workload):**
    * Managed by **Horizontal Pod Autoscaler (HPA)**.
    * Adjusts the number of pod replicas based on metrics like CPU, Memory, or custom metrics.
2.  **Node Scaling (Infrastructure):**
    * Managed by **Cluster Autoscaler** (or Karpenter).
    * Adds worker nodes when pending pods cannot be scheduled (resource exhaustion).
    * Removes worker nodes when they are underutilized to save costs.

[Image of Kubernetes HPA and Cluster Autoscaler]

## 8. Why Kubernetes over Docker Swarm?
Kubernetes is the de-facto standard because:
* **Advanced Orchestration:** Handles complex workflows, stateful sets, and jobs better.
* **Scalability:** Proven at massive scale (Google scale).
* **Self-Healing:** rigorous health checks and auto-restart policies.
* **Ecosystem:** Massive support for add-ons (Helm, Prometheus, Istio) and managed cloud services (EKS, AKS, GKE).
* **Networking/Storage:** More robust abstraction (CNI/CSI) compared to Swarm's simpler model.
