## 1.What is the difference between physical server, virtualization, and containerization?

A **physical server** runs all applications on a single operating system. While this is simple, it can cause dependency conflicts because all applications share the same OS and installed software. It can also lead to poor resource utilization if the server's CPU and memory are not fully used.

**Virtualization** solves this by using a hypervisor to create multiple virtual machines (VMs) on a single physical server. Each VM has its own operating system, libraries, and applications, providing strong isolation. However, since every VM runs a complete OS, it consumes more CPU, memory, and storage, and takes longer to start.

**Containerization** takes a different approach. Instead of running a separate operating system for each application, containers share the host operating system's kernel and package only the application along with its required libraries and dependencies. As a result, containers are lightweight, start much faster, and use system resources more efficiently. This is why Docker and Kubernetes have become the preferred choice for building and deploying modern, cloud-native microservices.


## 2 IAAS VS PAAS VS SAAS

**Infrastructure as a Service (IaaS)** provides virtualized infrastructure such as servers, storage, and networking. The cloud provider manages the physical infrastructure, while the customer manages the operating system, runtime, applications, and data. A common example is Amazon EC2.

**Platform as a Service (PaaS)** provides a complete platform for developing and deploying applications. The provider manages the infrastructure, operating system, runtime, and middleware, allowing developers to focus only on their application and data. AWS Elastic Beanstalk is a good example.

**Software as a Service (SaaS)** delivers fully managed software over the internet. The provider manages everything, and users simply access the application through a browser or client. Examples include Gmail, Microsoft 365, and Salesforce.

The main difference is the level of responsibility: IaaS gives the most control but requires more management, PaaS reduces operational overhead by managing the platform, and SaaS requires almost no infrastructure management because the entire application is managed by the provider.


## 3.How do you manage os updates for the critical application instance

For a critical production application, I don't update the operating system directly.

### Step 1: Pre-update Checks & Scheduling
First, I check which updates are available and whether a reboot is required. I schedule the update during an approved maintenance window and inform the relevant stakeholders.

### Step 2: Backups & Rollback Option
Before making any changes, I create an AMI and ensure backups are available so I have a rollback option.

### Step 3: Non-Production Validation
I then validate the updates in a non-production environment.

### Step 4: Production Rolling Update
In production, if the application is running on multiple EC2 instances behind an Application Load Balancer, I perform a rolling update. I remove one instance from the target group, apply the OS updates, reboot if required, verify the application and health checks, and then add it back to the load balancer. After that, I repeat the same process for the remaining instances.

### Step 5: Monitoring & Stability
Finally, I monitor CloudWatch metrics, application logs, and ALB target health to ensure the application remains stable.

This approach keeps the application available while safely applying OS patches.


## 4 How do you perform EKS cluster upgrade?

### Step 1: Preparation and Review
When upgrading an EKS cluster, I start by reviewing the Kubernetes and AWS EKS release notes to identify any breaking changes, deprecated APIs, or compatibility issues with our applications and add-ons. Before making any changes, I verify that the cluster is healthy by checking that all nodes are in the Ready state and all pods are running without issues. I also ensure that backups are available and that I have a rollback plan if anything goes wrong.

### Step 2: Control Plane Upgrade
Next, I upgrade the EKS control plane using the AWS Management Console or the AWS CLI. Since the control plane is managed by AWS, the upgrade is handled by AWS with minimal disruption to the cluster. 

### Step 3: Update Add-ons
Once the control plane upgrade is complete, I update the EKS-managed add-ons such as the Amazon VPC CNI plugin, CoreDNS, and kube-proxy so they remain compatible with the new Kubernetes version.

### Step 4: Worker Node Upgrade
After that, I upgrade the managed worker node groups. AWS performs this as a rolling update by creating new nodes with the upgraded Kubernetes version, draining the old nodes, moving the pods to the new nodes, and then terminating the old nodes. This ensures that the application remains available throughout the upgrade.

### Step 5: Validation
Finally, I validate the upgrade by checking the Kubernetes version of all nodes, verifying that all pods and deployments are healthy, confirming that the application is accessible, and reviewing monitoring dashboards and logs to ensure there are no errors after the upgrade.

### Short Interview Version (60–90 secon
*(Note: Your text was cut off here, but I have retained exactly what was provided!)*

## 5 .Cost Optimization in DevOps

Cost optimization is a crucial part of DevOps to ensure efficient resource utilization without compromising performance. Here are five best practices:

## 1️⃣ Rightsizing Resources
- 🔹 Use the correct instance sizes for workloads (CPU, memory, storage).
- 🔹 Scale down underutilized resources (e.g., EC2 instances, Kubernetes nodes).
- 🔹 Use autoscaling to match demand dynamically.

## 2️⃣ Leverage Spot & Reserved Instances
- 🔹 Use spot instances for non-critical, fault-tolerant workloads.
- 🔹 Use reserved instances or savings plans for predictable workloads to get cost discounts.

## 3️⃣ Optimize CI/CD Pipelines
- 🔹 Run CI/CD jobs on ephemeral environments instead of always-on instances.
- 🔹 Use caching and artifact repositories to avoid redundant builds.
- 🔹 Schedule non-essential jobs during off-peak hours.

## 4️⃣ Implement Cost Monitoring & Alerts
- 🔹 Use tools like AWS Cost Explorer, Azure Cost Management, or GCP Billing.
- 🔹 Set up alerts for unexpected cost spikes.
- 🔹 Continuously analyze cloud billing reports and identify waste.

## 5️⃣ Use Serverless & Managed Services
- 🔹 Use FaaS (Lambda, Azure Functions, Google Cloud Functions) to reduce compute costs.
- 🔹 Offload workloads to managed services (e.g., RDS, DynamoDB, EKS, AKS).
- 🔹 Optimize Kubernetes cluster usage with Karpenter (AWS), Cluster Autoscaler, or KEDA.
