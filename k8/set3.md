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
For a multi-environment deployment strategy, I prefer using a single reusable Helm chart with separate values files for each environment, such as values-dev.yaml, values-sit.yaml, values-uat.yaml, and values-prod.yaml. The Helm templates remain the same across all environments, while the values files contain environment-specific settings like replica count, image tag, resource limits, ingress hostname, and autoscaling configuration. This avoids maintaining separate Kubernetes manifests for each environment.

In our EKS environment, Jenkins builds the Docker image, pushes it to AWS ECR, and updates the image tag in the appropriate Helm values file. ArgoCD watches the Git repository, detects the change, renders the Helm chart with the corresponding values file, and deploys it to the correct Kubernetes cluster or namespace. As the application moves from development to production, we reuse the same chart and only change the environment-specific values, ensuring consistency across deployments while allowing each environment to have its own configuration.

If I were using Kustomize instead, I would maintain a common base configuration and create separate overlays for development, staging, and production. Each overlay would patch only the differences, such as replica count, image tag, or ingress hostname. Both approaches reduce duplication, but in our environment Helm is the better fit because we already use Helm charts with ArgoCD and benefit from templating, release management, and easy upgrades.
