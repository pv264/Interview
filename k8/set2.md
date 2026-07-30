## Deployment vs. StatefulSet vs. DaemonSet

While all three are Kubernetes workload resources, each is engineered to address a completely different architectural requirement.

---

### 1. Deployment
*   **Best for:** Stateless applications where any Pod can handle any incoming request.
*   **Core Features:** Automatic scaling, self-healing, rolling updates, and rollbacks. It is the most commonly used workload type for standard application deployments.
*   **Real Use Case:** Spring Boot APIs, Node.js services, or React applications.

### 2. StatefulSet
*   **Best for:** Stateful applications that require a stable identity, a predictable hostname, and dedicated persistent storage.
*   **Core Features:** Preserves the Pod's unique identity and automatically reconnects to the exact same persistent storage volume even if the Pod is restarted or rescheduled. This is essential for data integrity in clustered environments.
*   **Real Use Case:** Databases and distributed data platforms like MySQL, PostgreSQL, MongoDB, or Kafka.

### 3. DaemonSet
*   **Best for:** Pods that need to run continuously on every single worker node across the entire cluster.
*   **Core Features:** Automatically provisions a new Pod instance onto a node as soon as it is added to the cluster, ensuring 100% node coverage.
*   **Real Use Case:** Node-level infrastructure components such as Fluent Bit for log collection, Prometheus Node Exporter for monitoring, or networking agents like Calico.

---

### Production Architecture Summary
In a typical production environment, a well-architected cluster leverages all three in tandem:
*   Use **Deployments** for standard application and API frontend/backend services.
*   Use **StatefulSets** for databases, caches, and stateful storage layers.
*   Use **DaemonSets** for node-level background operations (logging, monitoring, and networking).

## ConfigMaps vs. Secrets

Both ConfigMaps and Secrets are Kubernetes resources used to provide configuration to applications without hardcoding values into the container image. The main difference is the type of information they store.

*   **ConfigMap:** Used for non-sensitive configuration such as application settings, service URLs, log levels, or feature flags.
*   **Secret:** Used for sensitive information like database passwords, API keys, authentication tokens, and TLS certificates.

---

## The Base64 Misconception: Encoding vs. Encryption

One common misconception is that Kubernetes Secrets are secure because they are stored in Base64 format. 

*   **Base64 is only an encoding method:** It simply converts data into a text format so it can be stored and transmitted easily. 
*   **It is not encryption:** Because it does not use an encryption key, anyone with access to the encoded value can decode it back to the original data in a few seconds.

---

## How Secrets Are Stored and Secured

By default, Kubernetes stores Secrets in `etcd` as Base64-encoded data. To properly protect them, you should implement stronger security measures:

*   **Encryption at Rest:** You should explicitly enable encryption at rest for `etcd` so that the underlying data cannot be read directly from the disk.
*   **External Secret Management:** In production environments, organizations often go a step further by integrating Kubernetes with external secret management solutions such as AWS Secrets Manager, Azure Key Vault, or HashiCorp Vault. This provides stronger security, centralized secret management, auditing, and automatic secret rotation.

## Kubernetes Health Probes: Startup vs. Readiness vs. Liveness

Kubernetes utilizes three distinct types of health probes to manage the availability and self-healing lifecycle of containerized workloads.

---

### 1. Startup Probe
*   **Purpose:** Checks whether the application has finished initializing and booting up.
*   **Target Workloads:** Mainly used for heavy or slower-initializing applications, such as certain Spring Boot services.
*   **Behavior:** Until the Startup Probe successfully passes, Kubernetes completely disables and pauses both the Readiness and Liveness probes. This prevents the application from being killed and restarted prematurely before it has had enough time to fully start.

### 2. Readiness Probe
*   **Purpose:** Evaluates whether the application is currently capable of handling live incoming requests.
*   **Behavior:** Unlike other probes, if the Readiness Probe fails, Kubernetes **does not restart the Pod**. Instead, it isolates the Pod by removing it from the backend endpoints of the corresponding Service.
*   **Traffic Management:** No network traffic will be routed to the Pod until the probe begins passing successfully again.

### 3. Liveness Probe
*   **Purpose:** Continuously monitors the container throughout its lifetime to ensure it remains responsive.
*   **Behavior:** It detects if an application has entered an unrecoverable state, such as a deadlock, a frozen main thread, or a severe internal crash.
*   **Self-Healing:** If the Liveness Probe fails repeatedly, Kubernetes assumes the application is stuck and **automatically restarts the container** to clean the state.

---

### The Impact of Misconfiguration

Getting the configuration wrong on these probes can lead to severe operational issues:

*   **A Readiness Probe that Never Passes:** If a readiness check is misconfigured (e.g., targeting a misspelled endpoint or an unprivileged port), the Pod will show a status of `Running` but will **never receive traffic** from its Service. 
*   **Stuck Rollouts:** During a rolling update, a Deployment waits for new Pods to pass their Readiness Probes before terminating old ones. If the probe never passes, the rollout will stall indefinitely, blocking updates from completing.
*   **The "Liveness Death Spiral":** If a Liveness Probe is too aggressive (e.g., timeouts are too short or thresholds are too strict), an application undergoing a brief spike in high CPU traffic might miss a health check. Kubernetes will mistakenly assume it's dead, kill it, and restart it—creating a continuous loop of downtime precisely when the app is trying to recover.

In our project, our Spring Boot microservices connect to PostgreSQL, Redis, and Temporal during startup, so the application takes some time before it's fully operational. We use a Startup Probe to give the application enough time to initialize and prevent Kubernetes from restarting it too early. Once startup is complete, the Readiness Probe checks whether the service can handle requests. For example, if PostgreSQL becomes temporarily unavailable, the readiness check fails and Kubernetes removes that Pod from the Service so it stops receiving traffic, but it doesn't restart the application because it can recover once the database is back. Finally, we use a Liveness Probe to detect situations where the application becomes unresponsive due to issues like a deadlock or an infinite loop. In that case, Kubernetes automatically restarts the container to restore the service.


## How does Kubernetes handle rolling updates and rollbacks for a Deployment? What's maxSurge and maxUnavailable?

Kubernetes Deployments support rolling updates, which means the application is updated gradually instead of stopping all existing Pods at once. During a rolling update, Kubernetes creates new Pods with the updated version while keeping some of the old Pods running. Once the new Pods become healthy and pass their readiness checks, traffic is shifted to them, and the old Pods are terminated. This ensures that the application remains available throughout the deployment with little or no downtime.

If the new version has an issue, Kubernetes also supports rollbacks. A rollback restores the Deployment to the previous ReplicaSet, bringing back the last stable version of the application. This can be triggered manually using `kubectl rollout undo deployment <deployment-name>` or through automation in a CI/CD pipeline.

The rolling update behavior is controlled by two important parameters: **maxSurge** and **maxUnavailable**. maxSurge defines how many extra Pods Kubernetes can create above the desired replica count during an update, while maxUnavailable defines how many existing Pods are allowed to be unavailable during the update. These settings help balance deployment speed and application availability.


# Kubernetes Ingress vs. LoadBalancer Service[cite: 1]

An **Ingress** is a Kubernetes resource that manages how external HTTP and HTTPS traffic is routed to applications running inside the cluster.[cite: 1] Instead of exposing each application separately, an Ingress lets multiple applications share a single external endpoint.[cite: 1] It routes incoming requests to the correct Service based on rules such as the URL path (for example, `/api` or `/admin`) or the hostname (for example, `api.company.com` or `admin.company.com`).[cite: 1]

A **Service of type LoadBalancer**, on the other hand, exposes only one Service to the internet by provisioning a cloud load balancer.[cite: 1] If you have several applications, creating a separate LoadBalancer Service for each one means multiple cloud load balancers, which increases both cost and operational overhead.[cite: 1]


# Kubernetes Resource Requests vs. Limits

In Kubernetes, resource requests and limits are used to manage CPU and memory for containers. 

* **Request:** Specifies the minimum amount of CPU or memory that a container needs, and Kubernetes uses this information when deciding which worker node should run the Pod. 
* **Limit:** Defines the maximum amount of CPU or memory that the container is allowed to use.

## What happens when limits are exceeded?

CPU and memory limits are enforced differently:

* **CPU:** If a container exceeds its CPU limit, Kubernetes doesn't terminate it. Instead, the Linux kernel throttles the container, meaning it gets less CPU time and the application may become slower. 
* **Memory:** If a container exceeds its memory limit, it cannot be throttled because memory can't be reclaimed in the same way. Instead, the container is terminated with an Out Of Memory (OOM) kill, and Kubernetes restarts it according to the Pod's restart policy.

An **Ingress** addresses this by allowing multiple Services to be accessed through a single external LoadBalancer.[cite: 1] However, it's important to understand that an Ingress itself doesn't handle any network traffic.[cite: 1] It's simply a set of routing rules.[cite: 1] The actual traffic management is performed by an **Ingress Controller**, such as NGINX Ingress Controller, Traefik, or HAProxy.[cite: 1] The Ingress Controller continuously watches for Ingress resources and automatically configures the underlying reverse proxy to route incoming requests to the appropriate Kubernetes Service.[cite: 1]


# What is a PersistentVolume (PV) vs a PersistentVolumeClaim (PVC) vs a StorageClass?

A PersistentVolume (PV), PersistentVolumeClaim (PVC), and StorageClass work together to provide persistent storage to applications running in Kubernetes.

* **PersistentVolume (PV):** Represents the actual storage resource, such as an AWS EBS volume, Azure Disk, or NFS share.
* **PersistentVolumeClaim (PVC):** A request made by a Pod for storage with specific requirements like size and access mode. Kubernetes matches the PVC with an available PersistentVolume or dynamically creates one using a StorageClass.
* **StorageClass:** Defines the type of storage to provision, such as `gp3` on AWS, along with properties like performance and reclaim policy.

This setup allows applications to request storage without needing to know the underlying infrastructure details.


# What is a NetworkPolicy, and how would you restrict traffic between namespaces or services?

A **NetworkPolicy** is a Kubernetes resource that controls which Pods are allowed to communicate with each other. By default, most Kubernetes clusters allow all Pods to communicate freely, which isn't ideal from a security perspective. 

A NetworkPolicy lets you define exactly which Pods can send or receive traffic based on:
* Pod labels
* Namespaces
* Ports
* IP ranges

This helps implement the principle of least privilege, where each application can communicate only with the services it actually needs.

## Example: Restricting Traffic Between Microservices

In our project, we have Spring Boot microservices such as the UI Service, Document Processing Service, User Service, and a PostgreSQL database. 

* The **UI Service** should communicate with the **Document Processing Service**.
* The **Document Processing Service** should communicate with **PostgreSQL**.
* The **UI Service** should *never* connect directly to the PostgreSQL database.

We can enforce this using a NetworkPolicy by allowing only the Document Processing Pods to access PostgreSQL on port `5432`, while blocking all other Pods from reaching the database.




## What's the difference between a ServiceAccount and a User in Kubernetes RBAC? How would you scope permissions for a CI/CD pipeline deploying to the cluster?

In our CI/CD pipeline, Jenkins needs to communicate with the Kubernetes API to deploy applications.[cite: 1] Instead of using a personal user account or granting cluster-admin permissions, I would create a dedicated ServiceAccount for Jenkins.[cite: 1] By default, a ServiceAccount has no permissions, so the first step is to create a ServiceAccount in the namespace where Jenkins will deploy the application, for example, `jenkins-deployer` in the `dev` namespace.[cite: 1]

Next, I would create a namespace-scoped **Role** that grants only the permissions Jenkins actually needs, such as `get`, `list`, `create`, `update`, and `patch` on resources like `Deployments`, `Services`, `ConfigMaps`, and `Pods`.[cite: 1] After creating the Role, I would create a **RoleBinding** to bind that Role to the `jenkins-deployer` ServiceAccount.[cite: 1] This gives the ServiceAccount only the required permissions within that namespace.[cite: 1]

The next step is to configure Jenkins to use this ServiceAccount.[cite: 1] In a typical setup, I would generate a token for the ServiceAccount (or use the recommended authentication method for the Kubernetes version in use), securely store the token and the cluster details in Jenkins Credentials, and configure either the Kubernetes plugin or the `kubeconfig` used by the pipeline to authenticate with those credentials.[cite: 1]

Now, whenever the Jenkins pipeline executes commands such as `kubectl apply -f deployment.yaml` or `kubectl rollout status deployment/my-app`, the Kubernetes API authenticates the request as the `jenkins-deployer` ServiceAccount.[cite: 1] Kubernetes RBAC then checks whether that ServiceAccount has permission to perform the requested operation.[cite: 1] If the permission exists, the deployment succeeds; otherwise, the API returns a `Forbidden` error.[cite: 1]

This approach follows the **principle of least privilege** because Jenkins receives only the permissions required for deployment instead of full cluster-admin access.[cite: 1] It also improves security and auditability, since all deployment actions are performed by a dedicated ServiceAccount rather than a personal user account.[cite: 1]



 ## How does DNS resolution work inside a cluster (CoreDNS, service discovery by name)?


 # Kubernetes Service Discovery with CoreDNS

In Kubernetes, service discovery is handled by **CoreDNS**. Whenever a **Service** is created, Kubernetes automatically assigns it a DNS name. Applications communicate using this Service name instead of Pod IP addresses because Pod IPs are temporary and can change when Pods are recreated.

When a Pod makes a request to another service, such as `http://user-service`, the request first goes to **CoreDNS**. CoreDNS looks up the Service information from the Kubernetes API and returns the Service's **ClusterIP**. The application then sends the request to that ClusterIP, and the Kubernetes Service forwards the request to one of the healthy backend Pods using **kube-proxy**. This allows applications to communicate reliably even when Pods are restarted, replaced, or scaled.



## What are taints and tolerations?



Taints and tolerations are used to control which Pods can be scheduled onto specific worker nodes. 

* **Taint:** Applied to a node and tells the Kubernetes Scheduler not to place Pods on that node unless they explicitly tolerate the taint. 
* **Toleration:** Added to a Pod and allows it to be scheduled onto nodes with the matching taint.

## Production Use Case: Dedicated GPU Nodes

A very common production use case for taints and tolerations is GPU nodes. GPU instances are significantly more expensive than CPU instances, so we don't want regular application Pods using them. 

In one of my projects, we had Spring Boot APIs running on CPU nodes and vLLM inference servers running on NVIDIA GPU instances. Here is how we configured it:

* **Tainting the Node:** We labeled the GPU nodes, for example `accelerator=nvidia`, and applied a taint such as `gpu=true:NoSchedule`. This prevented normal application Pods from being scheduled on GPU nodes. 
* **Tolerating the Taint:** In the vLLM Deployment, we added a matching toleration along with a node selector targeting the GPU label. 

The node selector directed the vLLM Pods to GPU nodes, while the toleration allowed them to bypass the taint. This ensured that only AI inference workloads consumed GPU resources, reducing infrastructure costs and keeping the GPU nodes available for workloads that actually required them.

