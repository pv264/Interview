# AWS Architecture & Terraform Scenarios

## 1. Your application running on EC2 experiences traffic spikes only during business hours. How would you optimize cost and performance?
**Strategy: Auto Scaling + Hybrid Purchasing Options**

1.  **Auto Scaling:**
    * Implement an **Auto Scaling Group (ASG)** behind an Application Load Balancer.
    * Configure **Scheduled Scaling Policies** to scale up before business hours and scale down after hours.
    * Use **Dynamic Scaling** (CloudWatch alarms based on CPU or request count) to handle unexpected bursts.

2.  **Cost Optimization:**
    * **Base Load:** Use **Reserved Instances (RIs)** or **Savings Plans** for the baseline capacity (the minimum instances running 24/7).
    * **Burst Load:** Mix in **Spot Instances** for the scaling capacity during spikes.

3.  **Modernization (Optional):**
    * Enable **AWS Compute Optimizer** for ongoing right-sizing.
    * Consider migrating to **Fargate** or **Lambda** for better elasticity and pay-per-use efficiency.

[Image of AWS Auto Scaling architecture]

## 2. You have deployed an application on an EC2 Instance and it cannot download images from the internet. What might be the issue?
**Troubleshooting Network Connectivity:**

1.  **Public Subnet:**
    * Check if the **Route Table** has a route to an **Internet Gateway (IGW)** (`0.0.0.0/0 -> igw-xxx`).
    * Confirm the instance has a **Public IP**.
    * Verify **Security Groups** (Outbound rules) and **NACLs** allow traffic to port 80/443.

2.  **Private Subnet:**
    * Verify the **Route Table** points to a **NAT Gateway** located in a public subnet (`0.0.0.0/0 -> nat-xxx`).
    * Ensure the NAT Gateway itself has a valid public IP and route to the IGW.

## 3. Someone accidentally deleted data from an S3 bucket. How do you restore it?
**Recovery depends on Versioning status:**

* **If Versioning is Enabled:**
    * Restoration is easy. I can "delete the delete marker" to restore the object, or retrieve a previous version from the version history.
* **If Versioning is Disabled:**
    * I would check if **S3 Replication** (to another bucket) or **AWS Backup** was configured to restore from there.
    * *Note:* If no backups or versioning exist, the data is likely permanently lost.

**Prevention:**
* Enable **S3 Versioning**.
* Implement **MFA Delete** or **Object Lock**.
* Set up **Cross-Region Replication (CRR)**.

## 4. How do you connect your on-prem data center to AWS?
I would choose between **VPN** and **Direct Connect** based on requirements:

1.  **Site-to-Site VPN (Quick & Cost-effective):**
    * Configured between the on-prem router (Customer Gateway) and AWS (Virtual Private Gateway).
    *
