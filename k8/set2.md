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

An **Ingress** addresses this by allowing multiple Services to be accessed through a single external LoadBalancer.[cite: 1] However, it's important to understand that an Ingress itself doesn't handle any network traffic.[cite: 1] It's simply a set of routing rules.[cite: 1] The actual traffic management is performed by an **Ingress Controller**, such as NGINX Ingress Controller, Traefik, or HAProxy.[cite: 1] The Ingress Controller continuously watches for Ingress resources and automatically configures the underlying reverse proxy to route incoming requests to the appropriate Kubernetes Service.[cite: 1]
