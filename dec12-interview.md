# AWS, Kubernetes & Linux Interview Questions

## 1. How can we give temporary access to an object stored in an S3 bucket to an external user while keeping it private?
If we need to give temporary access to an S3 object while keeping the bucket private, the best method is generating a **Pre-signed URL**.

* **How it works:** A pre-signed URL is created by an identity (user/role) that already has permission to access the object. It grants time-bound access (e.g., 10 minutes or 1 hour) to anyone who possesses the link.
* **Benefits:** We don’t modify bucket policies, and external users do not need AWS accounts.
* **Expiration:** When the URL expires, access is automatically revoked.

## 2. One application is running on AWS Account A and needs to access an S3 bucket in Account B. How do you set this up?
To enable cross-account access:

1.  **Account A (Source):** Create an IAM Role (or use an existing one) that the application uses.
2.  **Account B (Destination):** Update the **S3 Bucket Policy** to explicitly allow the Principal (the ARN of the Role from Account A) to perform actions (like `s3:GetObject`).

> **Note:** No new IAM roles are strictly required in Account B; the permission is managed via the Bucket Policy in Account B trusting the Role in Account A.

## 3. I have two AWS buckets in 2 different regions. One hosts a static website, the other stores images. The website needs to fetch the images. What setup is required?
**Recommended Approach (Production): CloudFront**
Use **Amazon CloudFront** in front of both S3 buckets.
* **Performance:** Acts as a global CDN, caching content closer to users and reducing cross-region latency.
* **Security:** Provides HTTPS and avoids most browser-side CORS issues since both origin paths are served under the same domain.

**Alternative Approach (Direct S3):**
If CloudFront is not used, you must configure **CORS (Cross-Origin Resource Sharing)** on the image bucket.
* The image bucket must allow public read access (since static sites run in the browser and can't use IAM roles).
* Without proper CORS configuration, the browser will block the cross-origin requests from the website bucket to the image bucket.

## 4. You have a Lambda function associated with a VPC in AWS Account A. It needs to connect to an application running on EC2 in AWS Account B. How will you establish communication?
Since the Lambda is inside a VPC, we must establish **network-level connectivity** between the two VPCs.

**Method 1: VPC Peering (Recommended for simple setups)**
1.  Create a **VPC Peering connection** between Account A’s VPC and Account B’s VPC.
2.  Update **Route Tables** in both VPCs to route traffic to the peer.
3.  Configure **Security Groups** and NACLs to allow traffic on specific ports.
4.  The Lambda allows access to the EC2 instance using its **Private IP**.

**Method 2: Transit Gateway (Recommended for scale)**
For larger environments with multiple VPCs, use **AWS Transit Gateway** to route traffic between the accounts.

> **Note:** If private connectivity is not required (less secure), you could expose the EC2 via an Internet-facing Load Balancer (ALB/NLB), but private peering is preferred for security.

## 5. I want specific pods to be scheduled on specific nodes. How will you ensure this?
I use **Taints and Tolerations**.

1.  **Taint the Node:** This tells Kubernetes to reject any pod that does not have a matching toleration.
    `
  ## 6. Let's say a Jenkins agent is running on an EC2 instance in AWS Account A and it has to fetch the image from ECR from AWS Account B. How do you setup?

**Strategy: Cross-Account IAM Role Assumption**

1.  **Account B (Target/ECR):**
    * Create an **IAM Role** in Account B.
    * Attach **ECR Read Permissions** (e.g., `AmazonEC2ContainerRegistryReadOnly`) to this role.
    * Configure the **Trust Policy** on this role to explicitly allow Account A (specifically the IAM Role attached to the Jenkins EC2) to assume it.

2.  **Account A (Source/Jenkins):**
    * The IAM Role attached to the Jenkins EC2 instance must have permission to perform `sts:AssumeRole` on the role ARN created in Account B.

3.  **Execution (The Workflow):**
    * Jenkins runs a command (via CLI or plugin) to **assume the role** in Account B using AWS STS (`aws sts assume-role`).
    * It receives **temporary security credentials** (Access Key, Secret Key, Session Token).
    * It uses these credentials to log in to ECR (`aws ecr get-login-password`) and pull the Docker image securely.
