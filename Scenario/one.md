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

