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
    * Good for smaller workloads or immediate setup.
    * Traffic traverses the public internet (encrypted).

2.  **AWS Direct Connect (High Performance):**
    * A dedicated physical network connection.
    * Best for low latency, high bandwidth, and consistent performance.
    * **Hybrid Setup:** In production, I often use Direct Connect as the primary link and VPN as a backup for high availability.

3.  **Multi-VPC:**
    * If multiple VPCs are involved, I use **AWS Transit Gateway** to centralize the connection.



## 5. I have 2 EC2 instances running in different VPCs. They need to communicate but cannot. How do you fix that?
**Step 1: Establish a Network Path**
* **VPC Peering:** Best for a simple 1-to-1 connection. It makes the two VPCs behave as if they are on the same private network.
* **Transit Gateway:** Best if scaling to many VPCs (hub-and-spoke model).
* *Decision:* For just two instances, **VPC Peering** is the most direct solution.

**Step 2: Update Route Tables (Crucial Step)**
* **VPC A:** Add a route for VPC B’s CIDR block pointing to the `pcx-id` (Peering Connection).
* **VPC B:** Add a route for VPC A’s CIDR block pointing to the same `pcx-id`.

**Step 3: Security Groups**
* Ensure Security Groups on both instances allow inbound traffic from the peer VPC's IP range.



## 6. I have an app running on a POD in EKS. I want to access this using example.com. How do you set it up?
**Setup Flow:**

1.  **Service:** Create a Kubernetes `Service` (Type: LoadBalancer) or `NodePort`.
2.  **Ingress Controller:** Deploy an Ingress Controller (e.g., AWS Load Balancer Controller).
3.  **Ingress Resource:** Define an Ingress rule that routes traffic from `example.com` to the backend Service.
    * This provisions an **Application Load Balancer (ALB)**.
4.  **DNS:** Create a **CNAME record** in Route 53 pointing `example.com` to the ALB's DNS name.
5.  **HTTPS:** Attach an **ACM Certificate** to the ALB listener for SSL termination.



## 7. You have a manually created VPC. Now you have to create an EC2 instance inside it using Terraform. How do you pass the existing VPC ID?
**Using Data Sources:**

1.  **Define Data Source:** Use `data "aws_vpc"` to look up the VPC by its ID or tags (instead of hardcoding).
    ```hcl
    data "aws_vpc" "selected" {
      id = "vpc-12345678"
    }
    ```
2.  **Reference it:** When creating the EC2 instance or Security Group, reference `data.aws_vpc.selected.id`.
3.  **Benefit:** This allows Terraform to read the VPC's attributes without managing/importing the VPC itself.

## 8. You have provisioned a VPC using Terraform and someone deleted it manually. If you run `terraform apply`, how will it behave?
**Drift Detection & Remediation:**

1.  **State Mismatch:** The Terraform state file (`terraform.tfstate`) still believes the VPC exists.
2.  **Refresh:** When you run `terraform apply` (or plan), Terraform refreshes the state against the real world (AWS).
3.  **Detection:** It detects the VPC is missing (404 Not Found).
4.  **Action:** Terraform will attempt to **recreate** the VPC and any dependent resources defined in your `.tf` files to match the desired configuration.
