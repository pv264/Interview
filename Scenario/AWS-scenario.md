## AWS & Infrastructure Interview Prep

### 1. Setting up a Small Web Application on AWS
**Answer:**
1. **Launch EC2 Instance:** Select an appropriate **AMI** (e.g., **Amazon Linux** or **Windows Server**) based on application requirements.
2. **Web Server Installation:** Once running, install web server software like **Apache** or **Nginx**.
3. **Deploy Application:** Move application files onto the server.
4. **Data Storage:** Use **Amazon RDS** to create a relational database. Ensure it is configured to communicate securely with the **EC2 instance**.
5. **Security Groups:** Define inbound rules for **Port 80 (HTTP)** and **Port 443 (HTTPS)** to ensure the application is accessible yet secure.

---

### 2. Storing Images and Documents Securely
**Answer:**
**Amazon S3** is the ideal choice for durability and scalability.
* **Bucket Creation:** Create a new **S3 bucket** in your preferred region.
* **Versioning:** Enable **versioning** for an immutable history and easy recovery from accidental deletions.
* **Encryption:** Activate **Server-Side Encryption (SSE-S3)** to encrypt stored data.
* **Access Control:** Set up an **IAM policy** to grant access only to authorized users or applications.

---

### 3. Restricting Access to Office Premises
**Answer:**
Combine network restrictions and **IAM policies**:
1. **Determine Office IP Range.**
2. **VPC Configuration:** Attach an **Internet Gateway** and set up **Network ACLs (NACLs)** or **Security Groups** to allow traffic only from the office IP range.
3. **IAM Conditions:** Update **IAM policies** with a `Condition` element that restricts access to the specified IP range.

> **Senior Signal:** Using **IAM IP conditions** provides a second layer of defense. Even if credentials are leaked, they remain useless outside the corporate network.

---

### 4. Cost-Effective Static Website Launch
**Answer:**
Utilize **Amazon S3** and **Route 53**:
1. **Upload Files:** Upload **HTML/CSS/JS** to an **S3 bucket**.
2. **Static Hosting:** Configure the bucket for **static website hosting** and set public permissions.
3. **DNS Management:** Register or manage a domain using **Route 53**.
4. **DNS Records:** Point the domain to the **S3 bucket endpoint** using an **Alias record**.

---

### 5. Analyzing Access Patterns and Usage
**Answer:**
**Amazon CloudWatch** is the primary tool for insights.
* **Monitoring:** Track key metrics like **CPU Utilization**, **Network Traffic**, and **Disk I/O**.
* **Dashboards:** Create visualizations to identify usage patterns.
* **Alarms:** Set thresholds to notify administrators when resources are over-utilized.

---

### 6. Scaling Based on Traffic
**Answer:**
Integrate **AWS Auto Scaling** with **Elastic Load Balancing (ELB)**:
1. **Launch Template:** Specify **EC2 instance type**, **AMI**, and **Security Groups**.
2. **Auto Scaling Group (ASG):** Set **minimum**, **maximum**, and **desired** instance counts.
3. **ELB Attachment:** Attach the **ASG** to an **ELB** to distribute traffic and improve fault tolerance.
4. **Scaling Policies:** Configure policies based on metrics like **CPU Utilization** to automatically scale instances up or down.



---

### 7. Automating Data Retention (S3)
**Answer:**
Utilize **S3 Lifecycle Policies**:
* **Transition Rules:** Automatically move objects to **S3 Standard-IA** or **S3 Glacier** based on age or tags.
* **Expiration Actions:** Set rules to permanently delete old objects that are no longer required for compliance or business use.

---

### 8. High Availability & Disaster Recovery (Multi-Tier)
**Answer:**
* **Multi-AZ Deployment:** Deploy **EC2** instances across multiple **Availability Zones**.
* **ELB:** Distribute traffic across these zones.
* **RDS Multi-AZ:** Use **RDS Multi-AZ** for automatic failover and data replication.
* **Cross-Region Replication:** Use **S3 Cross-Region Replication** for critical data backups.
* **Route 53 Failover:** Implement **health checks** and **DNS failover** to redirect traffic to a backup site if the primary site fails.

---

### 9. Handling Sensitive Data Securely
**Answer:**
* **Network Isolation:** Use **Amazon VPC** with private subnets.
* **Traffic Control:** Enforce rules via **Security Groups** (Instance-level) and **NACLs** (Subnet-level).
* **Identity Management:** Use **IAM** for least-privilege access.
* **Encryption:** Use **AWS KMS** for encryption at rest and **SSL/TLS** for encryption in transit.
* **Auditing:** Use **AWS Config** and **Amazon GuardDuty** to monitor for threats.

---

### 10. Robust Monitoring and Automated Reactions
**Answer:**
Combine **AWS CloudWatch** and **AWS Lambda**:
1. **CloudWatch Alarms:** Set alarms for specific metric thresholds.
2. **SNS/Lambda Trigger:** Trigger an **SNS notification** or invoke a **Lambda function** when an alarm is breached.
3. **Automated Response:** The **Lambda function** can automatically adjust **ASGs**, modify **Security Groups**, or notify admins.

---

### 11. Optimizing Cost and Performance
**Answer:**
* **Right-sizing:** Select instance types based on actual workload using **AWS Cost Explorer**.
* **Auto Scaling:** Avoid over-provisioning by scaling based on demand.
* **Data Transfer:** Keep data in the same region and use **Amazon CloudFront** to reduce latency and transfer costs.

---

### 12. Multi-Region High Availability
**Answer:**
* **Global Distribution:** Deploy the application in at least two regions.
* **Global Databases:** Use **Amazon Aurora Global Database** or **DynamoDB Global Tables** for synchronization.
* **Route 53:** Use **Latency-based** or **Geoproximity** routing with **DNS failover**.
* **S3 CRR:** Enable **Cross-Region Replication** for all critical static assets.

---

### Scenario: Onboarding a New Developer (EC2 Access)

**Answer:**
When a new developer joins, we follow these steps to provide **secure access while maintaining least privilege**:

1. **Step 1: Create an IAM user specifically for the developer**

   We first create an IAM identity for the developer so they can access AWS resources based on the permissions assigned to them.

2. **Step 2: Generate a unique SSH key pair**

   We generate a unique SSH key pair for the developer. The **private key** stays securely with the developer, and the **public key** will be configured on the EC2 server.

3. **Step 3: Login to EC2 as an existing admin**

   A DevOps engineer or existing administrator who already has access logs into the EC2 server. We use this administrative access to set up the new developer's access.

4. **Step 4: Create a dedicated Linux user on the instance**

   We create a separate Linux user for the developer instead of giving them access through an existing or shared account. This gives each developer an individual identity on the server.

5. **Step 5: Configure SSH key access**

   We add the developer's **public SSH key** to the new Linux user's `authorized_keys` file. After this, the developer can connect to the EC2 server using their own private key.
