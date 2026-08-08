## 1.What was the last Terraform issue you fixed?

**Answer:**
# Terraform EC2 Instance Recreation Due to AMI Change

During a Terraform deployment, **`terraform plan`** showed that an EC2 instance would be recreated even though we had not made any intentional changes to the instance.

I reviewed the **`terraform plan`** output carefully and noticed that the AMI ID had changed. The AMI was being retrieved dynamically using a data source with **`most_recent = true`**. Whenever a new AMI was released, the data source returned the newer AMI ID. Terraform detected that the AMI attribute of the EC2 instance had changed, and because changing the AMI requires replacing an EC2 instance, Terraform planned to destroy and recreate it.

## Root Cause

The root cause was the dynamic AMI lookup using **`most_recent = true`**, which caused the AMI ID to change whenever a newer AMI became available.

## Resolution

To prevent Terraform from recreating the production EC2 instance because of an AMI change, we used the **`lifecycle` `ignore_changes`** rule for the AMI attribute.

Therefore, when a new AMI is released, Terraform does not automatically replace the running EC2 instance.

## 2.What is a production outage you handled recently? What was the root cause?

# Production Incident – 502 Errors

Recently, we had a production incident where users started experiencing **502 errors** while accessing the application. We had **CloudWatch monitoring configured for our Application Load Balancer (ALB)**, so we received an alert when the ALB 5xx error count crossed the configured threshold.

I started the investigation from the **ALB** because that was where the alert originated. I checked the ALB metrics and the target group health status and found that the backend **EC2 targets were unhealthy**.

I then connected to one of the affected EC2 instances and checked the application containers using Docker. I noticed that the application container was **repeatedly restarting**.

I checked the **Docker logs and Linux system logs** and found OOM-related messages indicating that the application process was being killed because the EC2 instance was running out of memory. I also checked the instance memory metrics and correlated the timing with the incident.

I then checked the recent deployment history and found that a **new application version had been deployed shortly before the issue started**. The new version had higher memory consumption compared to the previous stable version.

Because traffic had increased, the EC2 instance didn't have enough available memory, which caused the container to crash repeatedly. As a result, the **ALB health checks failed**, the targets became unhealthy, and users started receiving **502 errors**.

## Rollback

Since this was a production outage, my first priority was to **restore the service**.

Our application was deployed using **Docker containers**, and the Docker images were versioned and stored in **Amazon ECR**.

The problematic version was:

`1.5.0`

The previous known-good version was:

`1.4.0`

We had the image version parameterized in our **Jenkins CI/CD pipeline**.

So rather than manually changing the Docker image on the EC2 instance, I triggered the deployment pipeline with the previous stable image tag:

`1.4.0`


Jenkins pulled the existing `1.4.0` image from ECR and deployed it to the EC2 instance, replacing the container running `1.5.0`.

There was **no need to rebuild the Docker image** because the known-good `1.4.0` image was already available in ECR.

## Post-Rollback Verification

After the rollback, I verified:

- Docker container status
- Application logs
- Application health endpoint
- ALB target group health

I then monitored the ALB target group. Once the health checks started passing and the targets became **healthy**, traffic started flowing normally and the **502 errors stopped**.

## Root Cause Analysis

After the service was restored, we performed the root-cause analysis.

We confirmed that the new application version had **increased memory consumption** and that the EC2 instance didn't have sufficient memory capacity for the workload.

## Preventive Measures

As preventive measures:

1. **Increased EC2 memory capacity**

   We increased the memory capacity of the EC2 instances to provide sufficient resources for the application workload.

2. **Reviewed application memory requirements**

   We reviewed the application's memory consumption and requirements.

3. **Improved monitoring**

   We configured the **CloudWatch Agent** for OS-level memory metrics.

4. **Added additional alerts**

   We added alerts for:

   - High memory utilization
   - Unhealthy ALB targets
   - Container restarts

5. **Reviewed Auto Scaling configuration**

   We reviewed the Auto Scaling configuration to make sure sufficient capacity could be provisioned during traffic spikes.

## Final Root Cause

The root cause was **increased memory consumption introduced by the new application version combined with insufficient EC2 memory capacity**.

The immediate impact was **container crashes**, which caused the ALB health checks to fail and resulted in **502 errors for users**.

The service was restored by **rolling back from Docker image `1.5.0` to the previous stable image `1.4.0` through the Jenkins CI/CD pipeline**.
## 3.How did you reduce infrastructure cost in your project?

**Answer:**
In our project, we achieved a reduction in infrastructure costs by approximately **25–30%** through a multi-layered optimization strategy:

### Optimization Strategies

* **Implementing Auto Scaling:** Replaced fixed **EC2 capacity** with **Auto Scaling Groups (ASG)** to ensure we only pay for the resources needed based on real-time traffic.
* **Right-sizing Instances:** Analyzed **CloudWatch metrics** (CPU, Memory, and I/O) to identify over-provisioned instances and downgraded them to more appropriate, cost-effective instance types.
* **Spot Instances:** Utilized **Spot instances** for non-critical workloads, batch processing, and CI/CD runners, which offered significant savings compared to **On-Demand** pricing.
* **Storage Cleanup:** Automated the identification and deletion of **unused EBS volumes** and **outdated snapshots**.
* **Resource Scheduling:** Implemented scripts to automatically **shut down dev/test environments** during non-working hours and weekends.



> **Senior Signal:** Cost optimization is an ongoing process, not a one-time task. Beyond just cutting resources, look into **S3 Lifecycle policies** to move old data to **Glacier** and utilize **AWS Compute Optimizer** for AI-driven right-sizing recommendations.

---

### Key Outcomes
* **Cost Savings:** ~25–30% reduction in monthly **AWS bill**.
* **Efficiency:** Improved resource utilization across all environments.

## 4. What metrics did you configure personally?

**Answer:**
In my project, I personally configured monitoring and alerting using **Prometheus** and **Grafana** to track both system and **GPU metrics** for our AI inference infrastructure.

### 1. CPU and Memory Alerts
I configured alerts in **Prometheus** to trigger when:
* **CPU utilization** exceeds **80%**.
* **Memory usage** exceeds **85%**.

This helps identify resource saturation before it impacts application performance.

### 2. GPU Utilization Alerts
Since our **vLLM inference service** runs on **GPU instances**, I deployed **DCGM Exporter** to collect specialized metrics.

**Prometheus** scrapes metrics like:
* **GPU Utilization**
* **GPU Memory Usage**
* **GPU Temperature**

I configured alerts for when **GPU memory usage** crosses a threshold, as this is a primary cause for inference failures (e.g., **OOM** on the GPU).



### 3. Instance Health Monitoring
I used **Node Exporter** to monitor:
* **Disk usage**
* **Network traffic**
* **System load**

Alerts trigger if **disk utilization** exceeds **80%** or if the **Node Exporter** stops responding, which indicates potential instance-level issues.

### 4. Application Endpoint Monitoring
We monitored the **vLLM API endpoint** to ensure the inference service responded correctly.
* If the endpoint response failed or **latency** increased significantly, an alert would trigger.

### Notification Setup
All alerts were integrated with **Grafana Alerting** / **Alertmanager**, which sends notifications via **Slack** and **Email** for rapid incident response.

> **Senior Signal:** For AI/ML workloads, standard CPU/RAM monitoring isn't enough. Tracking **GPU Memory (FB Memory)** and **Temperature** is critical because AI models often fail due to GPU fragmentation or thermal throttling long before the system CPU shows any stress.

---

### Result
This monitoring setup allowed us to proactively detect **GPU memory saturation**, resource exhaustion, and service downtime, significantly improving system reliability.
## 5. which cicd failure that took long time to debug?
## Jenkins Pipeline Failure: AWS ECR Authentication Issue

**Answer:**
We had a **Jenkins pipeline** that builds a **Docker image** and pushes it to **AWS ECR**. Suddenly the pipeline started failing during the image push stage, even though the same pipeline was working earlier.

### First, I checked the pipeline logs in Jenkins and noticed the error:
`no basic auth credentials`

This indicated that the pipeline was not authenticated to **AWS ECR**.

### I verified:
* **Jenkins credentials configuration**
* **IAM permissions** for the **EC2 instance** running **Jenkins**
* **Docker login commands** in the pipeline

### Root Cause:
After deeper investigation, I found that the **ECR authentication token** had expired because the pipeline was using an old login method that cached credentials. Since **ECR tokens** are valid only for **12 hours**, the authentication failed.



### Prevention:
* Updated the **CI/CD pipeline** to always refresh **ECR login tokens**
* Improved **pipeline logs** to make authentication failures easier to identify
* Documented the fix for the team

> **Senior Signal:** When running **Jenkins** on **AWS**, the most secure way to handle **ECR** authentication is by using **IAM Roles** attached to the **EC2 instance** (Instance Profile) and ensuring the `aws ecr get-login-password` command is executed within the pipeline to handle the 12-hour token rotation automatically.

## 6. What is the complex issue that you handled recently?

**Answer:**
Recently, I worked on a complex issue in a **DevSecOps CI/CD pipeline** integrated with **GitOps**, where deployments to **Kubernetes** were failing intermittently even though **Jenkins** pipelines were succeeding.

**Jenkins** was building and pushing images to **ECR** correctly, and **Helm charts** were also getting updated. However, **ArgoCD** was not consistently deploying the latest version, which made the issue difficult to trace because everything looked fine at each individual stage.

### Systematic Troubleshooting:
I approached it systematically by validating each layer:

1.  **Jenkins Layer:** I checked **Jenkins** and found that sometimes the **Helm repo** changes were not being committed properly, which caused **ArgoCD** to miss updates.
2.  **Authentication Layer:** I discovered that **ECR authentication tokens** were expiring after instance restarts, causing **image pull failures** in **Kubernetes**.
3.  **ArgoCD Layer:** I analyzed **ArgoCD** and realized it was showing the app as **“Synced,”** but it wasn’t actually deploying new images because:
    * **Image tags** were not unique.
    * There was some **repo caching** involved.
4.  **Kubernetes Layer:** On the **Kubernetes** side, another issue was that the **`imagePullPolicy`** was set to **`IfNotPresent`**, so even when a new image was available, pods were not pulling it.



### Final Fix:
I implemented the following changes to resolve the issue:
* **Unique image tagging** using build numbers.
* Proper **Helm repo commit handling**.
* **Dynamic ECR login** in **Jenkins**.
* Enabled **ArgoCD auto-sync**, **self-heal**, and **prune**.
* Updated **`imagePullPolicy`** to **`Always`**.

> **Senior Signal:** Intermittent failures in GitOps pipelines often stem from "Silent Failures" where the status shows Green/Synced but the actual state is stale. Moving away from mutable tags (like `latest`) to unique, immutable tags is the most effective way to ensure Kubernetes recognizes a change and triggers a rolling update.

## Troubleshooting: EKS NodeCreationFailure


## 7. What is the complex issue that you handled recently?
**Answer:**
In a recent task, I faced a **NodeCreationFailure** issue while setting up an **EKS cluster**. The **EC2 instances** for worker nodes were launching successfully, but they were not joining the cluster.

### Investigation Steps:
1.  **IAM Verification:** I started by verifying **IAM roles** and confirmed the node group had the required policies.
2.  **Networking Check:** I checked the networking and realized the nodes were deployed in **private subnets** without a **NAT Gateway**.



### Root Cause:
Since **worker nodes** need outbound internet access to pull images from **ECR** and communicate with the **EKS control plane**, the lack of **NAT** was causing the failure.

### Resolution:
* I fixed this by creating a **NAT Gateway** in a **public subnet**.
* I updated the **private route tables** to route internet traffic through the **NAT Gateway**.
* After recreating the **node group**, the nodes successfully joined the cluster and were in **Ready state**.

> **Senior Signal:** When nodes fail to join an **EKS cluster**, the "Big Three" to check are **IAM Roles (AmazonEKSWorkerNodePolicy)**, **Security Group** (allowing Port 10250 and 443), and **Outbound Connectivity** (NAT Gateway or VPC Endpoints). This incident highlights why **VPC Routing** is as critical as the compute resources themselves in **EKS** setups.

---

### Key Takeaway
* **Outbound connectivity** is mandatory for nodes to register with the **Control Plane**.
* **NAT Gateways** or **Interface VPC Endpoints** (PrivateLink) are required for private subnet node communication.
