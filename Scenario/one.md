## 1.What was the last Terraform issue you fixed?

**Answer:**
During a **Terraform** deployment, **`terraform apply`** started showing that it would **recreate** an **EC2 instance** even though we had not changed anything related to the instance.

### Problem Identification:
I reviewed the **`terraform plan`** output carefully and noticed that the **AMI ID** had changed because it was being fetched using a **data source** for the latest **AMI**.


Whenever a new AMI was released, Terraform detected it as a change and tried to replace the EC2 instance.

Root Cause:
The root cause was using dynamic AMI lookup with most_recent = true, which caused Terraform to detect changes and plan instance replacement.

Resolution:
We pinned the AMI ID explicitly or

Used lifecycle rules:

## 2.What is a production outage you handled recently? What was the root cause?

**Answer:**
Recently we had a production outage where the application became inaccessible to users.

### Situation:
Users reported that the application endpoint was returning **502 errors** from the **Application Load Balancer (ALB)**. The service was running on **EC2 instances** behind an **ALB**.

### Initial Investigation:
* First, I checked the **AWS ALB Target Group** health status, and I noticed that all targets were marked **unhealthy**.
* Then I logged into one of the **EC2 instances** and checked the application service.



### Findings:
* The application container was **crashing repeatedly**, which caused the **health checks** to fail.
* I checked the **Docker logs** and **system logs**, and noticed the application was running **out of memory (OOM)**.

### Root Cause:
A new application deployment had introduced **higher memory consumption**, but the **EC2 instance size** had not been updated. As traffic increased, the application exhausted the available memory and the container kept restarting, which caused the targets to become **unhealthy** in the load balancer.

### Resolution:
To restore service quickly:
1. I **rolled back** the application to the previous stable version.
2. **Restarted** the containers.
3. Verified that the **target group health checks** became healthy again and traffic started flowing normally.

### Prevention:
After the incident:
* We **increased the instance memory capacity**.
* Added **CloudWatch alarms** for memory utilization.
* Implemented **Auto Scaling** based on traffic and resource usage.
* Added better **monitoring and alerts** to detect container restarts earlier.

### Result:
The service was restored quickly and we improved monitoring to prevent similar outages in the future.

> **Senior Signal:** 502 errors at the **ALB** level almost always point to a communication failure between the **Load Balancer** and the **Target Group**. When targets are "Unhealthy," the priority is identifying if it's a **Network/Security Group** issue or an **Application/Runtime** failure like an **OOM Kill**.

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
