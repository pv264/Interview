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

## What is a production outage you handled recently? What was the root cause?

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

