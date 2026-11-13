# EC2 Unresponsive Instance Troubleshooting Guide

When an EC2 instance suddenly becomes unresponsive, I follow a structured, step-by-step approach to identify the root cause, restore service, and prevent future recurrences.

---

## 1. Initial Infrastructure & Status Checks
* **EC2 Instance State:** Verify if the instance is `Running`, `Stopped`, or `Rebooting`.
* **AWS Status Checks:** 
  * Check the **System Status Check** to verify if the underlying AWS hardware/infrastructure is healthy.
  * Check the **Instance Status Check** to determine if the issue is inside the instance's OS or software layer.

---

## 2. Resource Utilization Analysis
* Review **Amazon CloudWatch Metrics** to spot potential bottlenecks or crashes:
  * **CPU Utilization:** Check for 100% CPU spikes or exhaustion.
  * **Memory Usage:** Look for memory leaks or high utilization.
  * **Disk I/O & Disk Space:** Check for full disks or high read/write latency.
  * **Network Usage:** Inspect `NetworkIn` and `NetworkOut` for traffic drops or sudden spikes.

---

## 3. Network & Connectivity Verification
* Audit networking configurations to ensure traffic is reaching the instance:
  * **Security Groups:** Confirm inbound and outbound rules allow required traffic.
  * **Network ACLs (NACLs):** Verify subnet-level allow/deny traffic rules.
  * **Route Tables:** Ensure correct routing to Internet Gateways or NAT Gateways.
  * **SSH Access:** Attempt standard SSH connectivity to rule out network-level blocks.

---

## 4. Deep-Dive Diagnostics
* If **SSH is unavailable**, connect via **AWS Systems Manager (SSM) Session Manager**:
  * **System Logs:** Inspect `/var/log/messages`, `/var/log/syslog`, or `dmesg` for kernel panics or Out-Of-Memory (OOM) killer events.
  * **Processes:** Check running processes using commands like `top`, `htop`, or `ps aux` to identify runaway processes.
  * **Disk & Memory:** Run `df -h` and `free -m` to inspect disk space and RAM directly on the host OS.

---

## 5. Application Troubleshooting
* If the underlying infrastructure and OS are healthy:
  * Check the **Application Service Status** (e.g., `systemctl status <service-name>`).
  * Inspect **Application Error Logs** for unhandled exceptions or crashes.
  * Review recent **Deployments** and **Configuration Changes** that might have introduced bugs or resource degradation.

---

## 6. Remediation & Prevention
* **Recovery:** Resolve the immediate root cause (e.g., restart services, clear disk space, reboot instance) to minimize downtime.
* **Prevention:** Implement long-term guards such as CloudWatch alarms, auto-recovery actions, Auto Scaling Groups, and automated health checks to prevent recurring issues.
### 2  How do you decide how much CPU and memory an application needs?
 I don't determine CPU and memory purely by estimation. I start by understanding the application's workload, expected traffic, concurrency, and whether it is CPU or memory intensive. I initially allocate reasonable resources and deploy it in a lower environment. Then I perform load testing with realistic traffic and monitor CPU, memory, response time, and error rates using tools such as CloudWatch or Prometheus/Grafana. I size the application based on peak usage rather than just average usage and keep some headroom for traffic spikes. After production deployment, I continue monitoring and tune the resources or configure horizontal scaling based on the observed workload.


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


# Interview Question: Explain the Request Flow from Client to Application Pods in AWS EKS Using API Gateway and an Internet-Facing ALB

## Architecture Overview

In our AWS EKS architecture, we use Route 53, API Gateway, an internet-facing Application Load Balancer (ALB), and Kubernetes Ingress to route incoming client requests to application Pods.

## Request Flow – Step by Step

### 1. Route 53 – DNS Resolution

When a user accesses our application using a domain name, such as `api.example.com`, Route 53 resolves the domain to the API Gateway custom domain endpoint.

### 2. API Gateway – API Management

The request reaches API Gateway, where we handle:

- Authentication and authorization.
- Request validation.
- Throttling and rate limiting.
- API management.

Once the request passes these checks, API Gateway forwards it to the backend ALB using its publicly accessible endpoint.

### 3. Internet-Facing Application Load Balancer

The ALB is deployed in public subnets across multiple Availability Zones.

It receives incoming HTTP/HTTPS requests and distributes traffic to the appropriate backend targets based on the routing configuration.

We configure HTTPS using an SSL/TLS certificate from AWS Certificate Manager (ACM), where applicable.

### 4. AWS Load Balancer Controller

In EKS, we install the AWS Load Balancer Controller.

It watches Kubernetes Ingress resources and automatically creates and manages the corresponding AWS ALB, including:

- Listeners.
- Listener rules.
- Target groups.
- Load balancer configuration.

**Important:** The AWS Load Balancer Controller manages the ALB configuration. It does not sit in the actual application request path.

### 5. Kubernetes Ingress

Ingress defines the routing rules based on hostnames and URL paths.

For example:

- `/users` routes to the user service.
- `/payments` routes to the payment service.
- `/orders` routes to the order service.

### 6. Kubernetes Service and Application Pods

The ALB forwards traffic to the appropriate application Pods.

When using the ALB **IP target type**, the ALB routes directly to Pod IP addresses.

Kubernetes Services and EndpointSlices help the AWS Load Balancer Controller discover the backend Pods.

The application container inside the Pod processes the request and sends the response back through the same network path.

---

## Complete Architecture Flow

```text
Client / Browser
       |
       v
    Route 53
   (DNS Resolution)
       |
       v
  API Gateway
(Authentication, Authorization,
 Throttling, Request Validation)
       |
       v
Internet-Facing ALB
       |
       v
  Ingress Rules
(Host-based / Path-based Routing)
       |
       v
Kubernetes Service / EndpointSlice
       |
       v
  Application Pod
       |
       v
 Application Container
```

**Note:** The AWS Load Balancer Controller manages the ALB and its routing configuration. It is not a network hop in the request flow.

---

## Common Interview Follow-up Questions

### 1. Why are you using API Gateway when you already have an ALB?

API Gateway provides API-level capabilities such as authentication, authorization, throttling, request validation and API lifecycle management.

ALB primarily handles load balancing and Layer 7 routing.

### 2. Why are you using an internet-facing ALB?

Because API Gateway is forwarding requests to the ALB's publicly reachable endpoint without using VPC Link.

We need to secure the ALB so that clients cannot bypass API Gateway and directly access the application.

### 3. Does the AWS Load Balancer Controller receive incoming requests?

No. It is a control-plane component.

It watches Kubernetes resources and configures AWS load-balancing resources. The ALB handles actual application traffic.

### 4. Does traffic go through the Kubernetes Service when using ALB IP target mode?

Not as a network hop.

The ALB sends traffic directly to the Pod IP. The Service and EndpointSlice provide backend discovery information to the AWS Load Balancer Controller.

### 5. Can we use an internal ALB instead?

Yes. We can use an internal ALB with API Gateway through VPC Link.

This is generally preferable when API Gateway should be the only public entry point because the ALB remains private and is not directly accessible from the internet.

---

## Important Production Consideration

If API Gateway is supposed to be the only public entry point, an internal ALB with VPC Link is generally preferable to a publicly exposed ALB.

If we use an internet-facing ALB, we should implement appropriate security controls to prevent unauthorized direct access and bypassing API Gateway.

The exact API Gateway integration configuration also depends on whether we use a REST API or HTTP API.

## Final Architecture to Remember

**Without VPC Link:**

```text
Client → Route 53 → API Gateway → Internet-facing ALB
       → Ingress Rules → Service / EndpointSlice → Pod
```

**With VPC Link (private architecture):**

```text
Client → Route 53 → API Gateway → VPC Link → Internal ALB
       → Ingress Rules → Service / EndpointSlice → Pod
```



