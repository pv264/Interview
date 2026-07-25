## 1. A Jenkins pipeline suddenly starts failing at the Docker build stage, even though the same code was working previously. How would you troubleshoot it?

**Answer:**
First, I would check the **Jenkins console logs** to identify the exact error message during the **Docker build stage**.

Then I would verify:
* Whether the **Docker service** is running on the Jenkins agent.
* **Disk space** availability.
* **Docker daemon** health.
* Permission issues, like the Jenkins user not being part of the `docker` group.

Next, I would check:
* Recent changes in the **Dockerfile**.
* Dependency/package changes.
* **Image registry** connectivity.
* Expired **credentials** if pulling private base images.

If the build works locally but fails in Jenkins, I would compare:
* **Environment variables**.
* **Docker versions**.
* **Network access**.
* **Workspace contents**.

I would also verify whether:
* The Jenkins **workspace is corrupted**.
* **Cache issues** exist.
* The agent node has enough **CPU/memory**.

> **Senior Signal:** The most common hidden culprit when a previously working Docker build suddenly fails on a Jenkins agent is running out of disk space due to a buildup of dangling images and stopped containers. Implementing a routine `docker system prune` or migrating to a rootless container lifecycle (like Podman) on your worker nodes is a proactive way to prevent this exact outage.


## 2. How do you integrate SonarQube with Jenkins in a CI/CD pipeline?

**Answer:**
We integrate **SonarQube** with **Jenkins** to perform automated code quality and security analysis during the CI/CD pipeline. 

### Integration Workflow:

1. **Install and Configure:** First, we install the **SonarQube Scanner plugin** in Jenkins and configure the SonarQube server URL and authentication token under Jenkins global configuration.
2. **Add Pipeline Stage:** Then we configure the Sonar scanner tool and add a dedicated SonarQube analysis stage in the Jenkins pipeline using Maven, Gradle, or the `sonar-scanner` command depending on the application type.
3. **Execute Analysis:** During pipeline execution, Jenkins sends the source code to SonarQube for analysis, where it checks for bugs, vulnerabilities, code smells, duplicated code, and code coverage.
4. **Enforce Quality Gate:** We also configure a **Quality Gate** in SonarQube, and Jenkins waits for the Quality Gate result before proceeding further. 

If the **Quality Gate** fails, the pipeline automatically stops, preventing low-quality or vulnerable code from being deployed to higher environments.

> **Senior Signal:** When configuring the Quality Gate step in a Jenkinsfile, it is a best practice to use the `waitForQualityGate()` step combined with a **SonarQube webhook** pointing back to Jenkins. This allows the Jenkins pipeline to pause asynchronously without consuming an executor node thread while waiting for the SonarQube server to finish processing the analysis report.

## 2 How do you integrate Jenkins with Kubernetes?

**Answer:**
In our setup, Jenkins communicates with the Kubernetes cluster using a Kubernetes **Service Account** instead of a standard `kubeconfig` file. A Service Account provides a specific identity to Jenkins, and **RBAC (Role-Based Access Control)** determines what actions that identity is allowed to perform.

Here is the step-by-step integration process:

### 1. Create the Service Account and RBAC Rules
* **Service Account:** First, we create a Service Account in the Kubernetes cluster (e.g., `jenkins-sa`). 
* **Role/ClusterRole:** By itself, the Service Account has very limited permissions, so we create a Role (or ClusterRole) with the exact required permissions—such as creating, updating, listing, and deleting Deployments, Pods, and Services.
* **Binding:** We then bind that Role to the Service Account using a `RoleBinding` or `ClusterRoleBinding`.

### 2. Configure Jenkins Authentication
Jenkins is then configured to use the credentials associated with that Service Account:
* **If Jenkins is inside the cluster:** It can use the Service Account directly by having its token automatically mounted to the Jenkins pod.
* **If Jenkins is outside the cluster:** We extract the Service Account token and use it alongside the Kubernetes API server endpoint to authenticate remotely.

### 3. Pipeline Execution
When the CI/CD pipeline reaches the deployment stage, Jenkins executes commands like `kubectl apply -f deployment.yaml` or `helm upgrade --install`. The `kubectl` client sends the request to the Kubernetes API Server along with the injected Service Account token.

### 4. API Server Validation
* The API Server first **authenticates** the Service Account using the token.
* It then checks **RBAC** to verify whether that Service Account has permission to perform the requested operation.
* If the permissions are valid, the API Server accepts the request, stores the desired state in `etcd`, and the scheduler and `kubelet` work together to create or update the Pods on the worker nodes.

> **Senior Signal:** Using a dedicated Service Account is considered significantly more secure than giving Jenkins broad `cluster-admin` access. It allows us to strictly enforce the **principle of least privilege**, granting Jenkins only the exact permissions it needs to deploy specific applications.

## 3 .How does Jenkins running on EC2 authenticate to ECR?

**Answer:**
In our setup, Jenkins runs on an Amazon EC2 instance and authenticates to Amazon ECR securely by leveraging an attached **IAM role (Instance Profile)** rather than relying on static, hardcoded credentials. 

Here is how the authentication and push process works step-by-step:

### The Authentication Workflow
1. **IAM Role Attachment:** The EC2 instance hosting Jenkins is assigned an IAM role that contains the required ECR permissions (e.g., `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, etc.).
2. **Credential Retrieval:** During the pipeline, Jenkins executes `aws ecr get-login-password`. The AWS CLI automatically reaches out to the **EC2 Instance Metadata Service (IMDS)** to retrieve temporary, auto-rotating credentials based on the attached IAM role.
3. **Docker Login:** AWS validates the role and returns a temporary authentication token (valid for 12 hours). Jenkins pipes this token directly into the `docker login` command to authenticate the local Docker daemon with the ECR registry.
4. **Build & Push:** Jenkins builds the Docker image, tags it with the specific ECR repository URI, and finally pushes it to Amazon ECR.

> **Senior Signal:** Highlighting that this approach eliminates the need to store long-lived AWS Access Keys inside Jenkins is a major security win. To take this answer to the next level in an interview, mention that you enforce **IMDSv2** on the Jenkins EC2 instance. IMDSv2 requires session tokens for metadata retrieval, which protects the instance against SSRF (Server-Side Request Forgery) attacks that could otherwise be used to steal the temporary IAM credentials.
