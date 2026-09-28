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


# Jenkins to Amazon EKS Authentication – Interview Explanation

In our setup, Jenkins runs on an EC2 instance and deploys applications to Amazon EKS. For authentication, we use an IAM-based approach instead of storing long-lived Kubernetes tokens or AWS access keys in Jenkins.

We attach an IAM role to the EC2 instance through an instance profile. This allows Jenkins to obtain temporary AWS credentials automatically through the EC2 instance metadata service, without requiring us to configure static access keys.

During the deployment stage, Jenkins uses the AWS CLI to configure the EKS cluster access. The kubeconfig uses the AWS EKS authentication mechanism to generate a short-lived authentication token whenever `kubectl` needs to communicate with the Kubernetes API server.

When the request reaches EKS, the API server authenticates the IAM identity. We configure the necessary EKS access permissions and Kubernetes RBAC rules to ensure Jenkins can perform only the required deployment operations within the target namespace.

Once the request is authorized, Kubernetes processes the deployment and reconciles the desired state.

Regarding token expiry, the EKS authentication token is valid for approximately 15 minutes. We don't manually generate or store a new token for every pipeline. The AWS CLI or authentication plugin generates a fresh token when needed. The underlying AWS credentials are also refreshed automatically through the EC2 instance profile.

From a security perspective, we follow the principle of least privilege, avoid static credentials, restrict Jenkins to the required Kubernetes resources, and keep the deployment process fully automated.

## If the interviewer asks follow-up questions

### Q: What happens when the EKS token expires?

"The AWS CLI or EKS authentication plugin generates a new token when `kubectl` needs to authenticate again, provided the underlying AWS credentials are valid."

### Q: How do you control what Jenkins can deploy?

"We associate the IAM role with the appropriate EKS access permissions and use Kubernetes RBAC where required. We scope permissions to the relevant namespace and resources rather than granting unrestricted cluster-admin access."

### Q: Where do you store the AWS credentials?

"We don't store static AWS access keys in Jenkins. We use an IAM role attached to the EC2 instance, and the AWS SDK or CLI obtains temporary credentials through the instance metadata service."

### Q: Is the EKS token the same as a Kubernetes Service Account token?

"No. In this approach, Jenkins authenticates using an IAM identity through the EKS IAM authentication mechanism. A Kubernetes Service Account token is a different authentication method."

**Important:** This is an interview-ready explanation of the IAM-based EKS approach. Describe it as your implemented setup only if your EC2 instance and Jenkins pipeline are actually configured this way.


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

## 5 How do you design a Jenkins pipeline from scratch?

**First, I understand the application, source-control strategy, build process, deployment target, environments, and security requirements. Then I design the pipeline into stages such as checkout, build, unit testing, code-quality analysis, security scanning, Docker image creation, image scanning, artifact publishing, and deployment.**

**I configure Jenkins agents with the required tools and avoid running builds on the controller. For credentials, I use Jenkins Credentials or preferably IAM roles/workload identity instead of hardcoding secrets. I also define environment-specific configuration separately for dev, QA, UAT, and production.**

**For containerized applications running on Kubernetes, I typically build the image, scan it with Trivy, push it to ECR, and then deploy using Helm or a GitOps tool such as ArgoCD. For production, I include approval gates, health checks, smoke tests, rollback mechanisms, notifications, and proper logging.**

**Finally, I make sure every deployment is traceable to a Git commit and immutable image version, so we know exactly what version is running in each environment.**

