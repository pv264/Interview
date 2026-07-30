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
