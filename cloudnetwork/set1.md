## 1. What is Cloud Network Security?

**Answer:**
**Cloud network security** is the practice of securing network infrastructure, traffic, applications, and data within cloud environments such as AWS, Azure, or GCP. It ensures the confidentiality and integrity of cloud resources by controlling access, segmenting networks, encrypting traffic, and monitoring for threats.

### Core Components & Services
In cloud environments, we typically use:
* **VPCs/VNets:** To create logically isolated networks.
* **Security Groups and Network ACLs (NACLs):** To control inbound and outbound traffic.
* **Web Application Firewalls (WAFs):** To protect web applications from common web exploits.
* **VPNs or Private Connectivity Solutions:** To securely connect on-premises environments to the cloud.

### Implementation Strategies
* **Network Segmentation:** We place internet-facing resources in public subnets while keeping application servers and databases securely isolated in private subnets.
* **Traffic Encryption:** All communication is secured using TLS encryption.
* **Threat Monitoring:** Tools such as VPC Flow Logs, GuardDuty, or Azure Defender help detect suspicious or malicious activity.
* **Zero Trust Model:** Modern cloud network security follows a Zero Trust model, where every user and service must be authenticated and authorized regardless of their network location.

---

### Real-World Example Architecture (AWS)
To implement these concepts in AWS, I would design a multi-tier architectural pattern:
1. **The VPC Setup:** Create a VPC divided into public and private subnets.
2. **Public Tier:** Place the Application Load Balancer (ALB) in the public subnet to accept HTTPS traffic from users.
3. **Application Tier:** Place the application servers in private subnets, configuring **Security Groups** to *only* allow traffic originating from the ALB.
4. **Database Tier:** Isolate the database further in its own private subnet, strictly restricting access so it only accepts connections from the application servers.
5. **Security & Governance:** Enable **AWS WAF** at the edge, configure **VPC Flow Logs** for network visibility, and use **IAM policies** to enforce least-privilege access.

> **Senior Signal:** Architecting a multi-tier VPC network with strict security boundary rules demonstrates a rock-solid understanding of defense-in-depth strategies. Emphasizing the **Zero Trust model** and leveraging stateful controls (Security Groups) alongside stateless ones (NACLs) ensures that your network perimeter remains highly resilient against lateral movement during a security event.

## 2. What is the difference between a Security Group and a NACL?

**Answer:**
**Security Groups** and **NACLs** (Network Access Control Lists) are both AWS network security mechanisms, but they operate at different levels and handle traffic states differently.

### Core Differences
* **Operating Level:** A **Security Group** acts as a virtual firewall at the **instance level** (e.g., attached directly to EC2 or RDS instances), whereas a **NACL** acts as a firewall at the **subnet level** (protecting everything inside that subnet).
* **Statefulness:** * **Security Groups are stateful:** If inbound traffic is allowed, the response/return traffic is automatically allowed, regardless of your outbound rules.
  * **NACLs are stateless:** You must explicitly allow both inbound and outbound traffic. If a request comes in, the network needs a specific outbound rule to allow the response back out.

---

### Real-World Application & Layered Security
In one of my projects, we had an ALB, EC2 application servers, and an RDS database. We used Security Groups as the primary security mechanism:
1. **ALB Security Group:** Allowed internet traffic on ports 80 and 443.
2. **EC2 Security Group:** Allowed traffic *only* from the ALB Security Group.
3. **RDS Security Group:** Allowed MySQL traffic *only* from the EC2 Security Group. 

This ensured a layered, Zero Trust security model. 

We used **NACLs** mainly as an additional subnet-level security layer. For example, when a suspicious IP range was identified, we added a **deny rule** in the NACL to block that traffic for the entire subnet without having to modify dozens of individual Security Groups.

> **Senior Signal:** Emphasizing that Security Groups allow rule referencing by *Group ID* (instead of static IPs) is a massive green flag for cloud-native architecture. Furthermore, noting that NACLs are perfect for incident response as a "kill switch" (because they evaluate numbered rules in order from lowest to highest and explicitly support DENY rules, unlike Security Groups) demonstrates strong SecOps maturity.


## 3. Explain Route 53 routing policies

**Answer:**
**Route 53 routing policies** determine how DNS responds to client requests and which resource IP address is returned. Different routing policies are used based on requirements such as load balancing, high availability, latency optimization, or disaster recovery.

Here is a breakdown of the most commonly used Route 53 routing policies:

### 1. Simple Routing
* **What it is:** The default routing policy. You map a domain to one or more IP addresses.
* **How it works:** If you provide multiple IP addresses in a single record, Route 53 returns all of them to the client in a randomized order.
* **Use case:** Standard, single-server environments. (Note: Simple routing does *not* support health checks).

### 2. Weighted Routing
* **What it is:** Distributes traffic across multiple resources based on assigned proportions (weights).
* **How it works:** You assign a weight (e.g., 80 and 20) to different records. Route 53 routes traffic based on that mathematical ratio.
* **Use case:** Canary deployments, A/B testing, or gradually rolling out a new application version.

### 3. Latency-Based Routing
* **What it is:** Routes traffic to the AWS region that provides the fastest response time for the user.
* **How it works:** AWS continuously monitors network latency between global users and AWS regions. When a query is made, it directs the user to the region with the lowest latency.
* **Use case:** Global applications requiring maximum performance and minimal lag.

### 4. Failover Routing
* **What it is:** Used to create an Active-Passive high-availability architecture.
* **How it works:** Route 53 monitors the primary resource using **Health Checks**. If the primary resource goes down, DNS automatically routes traffic to the secondary (standby) resource.
* **Use case:** Disaster recovery (DR) scenarios and maintaining high availability during outages.

### 5. Geolocation Routing
* **What it is:** Routes traffic based on the geographic location of your users.
* **How it works:** You can specify that users from a specific country, continent, or US state are strictly routed to a specific endpoint.
* **Use case:** Data sovereignty compliance (e.g., ensuring European users' data stays on EU servers) or serving localized content/language.

### 6. Geoproximity Routing
* **What it is:** Routes traffic based on the physical distance between your users and your AWS resources.
* **How it works:** It uses AWS Traffic Flow. You can optionally apply a "bias" to artificially expand or shrink the routing territory of a specific region to shift traffic.
* **Use case:** Highly complex global architectures where you need precise control over traffic boundaries.

### 7. Multi-Value Answer Routing
* **What it is:** Similar to Simple Routing, but **with Health Checks**.
* **How it works:** Route 53 returns multiple IP addresses, but it only returns the IPs of resources that are currently healthy.
* **Use case:** Simple, DNS-level load balancing across multiple healthy web servers.

> **Senior Signal:** To show real-world experience in an interview, frame these practically: "In production, I've typically seen **Latency-Based Routing** for global applications, **Weighted Routing** for canary deployments, and **Failover Routing** combined with strict Route 53 Health Checks for cross-region disaster recovery scenarios."

## Which Route 53 routing policies are most relevant to your GenAI architecture?

**Answer:**
In our GenAI architecture, the most relevant Route 53 routing policies would be **Weighted**, **Latency-Based**, and **Failover** Routing. 

Here is how each applies to our specific workload:

* **Weighted Routing (Canary Deployments):** This can be used when upgrading our infrastructure components, such as deploying new **Haystack** or **vLLM** versions. By assigning weights, we can gradually shift a small percentage of traffic to the new version to monitor for errors before fully cutting over.
* **Latency-Based Routing (Performance):** Generative AI applications are highly sensitive to network latency. This policy can direct users to the nearest AWS region to reduce the network transit time, ultimately lowering the overall "Time to First Token" (TTFT) and prompt response time.
* **Failover Routing (Disaster Recovery):** This can support disaster recovery (DR) by monitoring our primary environment's health checks and automatically redirecting traffic to a secondary region if the primary Haystack/vLLM stack becomes unavailable.

> **Senior Signal:** Because the **vLLM** layer requires expensive GPU instances, running a traditional Active-Passive disaster recovery setup with Failover Routing can be highly inefficient due to idle GPU costs. A strong architectural talking point is advocating for an **Active-Active** setup using Latency-Based Routing across multiple regions. This ensures all provisioned GPUs are actively serving traffic to justify their cost, while inherently providing disaster recovery if one region goes down!
