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

**Answer# SonarQube and Jenkins Integration Workflow

We integrate **SonarQube** with **Jenkins** to perform automated code quality and security analysis during the CI/CD pipeline.

### Integration Workflow

1. **Install and Configure**

   * Install the **SonarQube Scanner for Jenkins** plugin.
   * Configure the SonarQube server URL and authentication token in Jenkins global configuration.
   * Store the authentication token securely in **Jenkins Credentials**.

2. **Configure Scanner and Pipeline**

   * Configure the required SonarQube scanner/tool.
   * Add a dedicated SonarQube analysis stage in the Jenkins pipeline.
   * Use **Maven, Gradle, or `sonar-scanner`**, depending on the application.

3. **Execute Analysis**

   * During pipeline execution, Jenkins invokes the **SonarQube Scanner**.
   * The scanner analyzes the source code for:

     * Bugs
     * Vulnerabilities
     * Code smells
     * Duplicated code
     * Code coverage
   * The analysis report is sent to the SonarQube server.

4. **Enforce Quality Gate**

   * Configure a **Quality Gate** in SonarQube with conditions such as:

     * Minimum code coverage
     * Zero critical vulnerabilities
   * Jenkins waits for the Quality Gate result using `waitForQualityGate`.
   * A **SonarQube webhook** notifies Jenkins when the analysis is complete.

5. **Continue or Stop Pipeline**

   * If the **Quality Gate passes**, Jenkins continues with subsequent stages such as:

     * Docker image build
     * Docker image push
     * Deployment
   * If the **Quality Gate fails**, Jenkins can stop the pipeline, preventing code that doesn't meet the defined quality standards from being deployed to higher environments.
:**

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

## 3. When do you choose jenkins and when do you choose github actions for cicd?
I choose **Jenkins** when the organization already has Jenkins in place, has many existing pipelines and integrations, or requires a high level of customization and control over the CI/CD infrastructure.

I choose **GitHub Actions** when the source code is hosted on GitHub and we want a simple, GitHub-integrated CI/CD solution with less infrastructure and maintenance overhead.

For a **new project hosted on GitHub**, I would generally prefer GitHub Actions because it is easy to set up and integrates directly with the repository. However, if the organization already has a mature Jenkins environment, I would continue using Jenkins instead of introducing another CI/CD tool unless there is a specific reason to migrate.


## 4 Jenkins builds fail only on specific agents. How do you debug?

"If a Jenkins build fails only on specific agents, I first compare the failing agent with a known-good agent because that indicates an environment-specific problem. I check the Jenkins console logs and agent logs, then validate Java and build-tool versions, environment variables, disk and memory utilization, workspace permissions, Docker configuration, and network connectivity.

I also check whether the Jenkins user can execute the required commands and access the required resources. If the pipeline uses external repositories or container registries, I test connectivity directly from the failing agent. Finally, I reproduce the failing build command manually on the agent and compare it with a working agent. Once I identify the difference, I fix the agent configuration or replace/rebuild the agent if it's an inconsistent or corrupted node."

