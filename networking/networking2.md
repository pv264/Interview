## 1. What will happen in the backend when we enter amazon.com?

When I enter `amazon.com` in a browser, the process happens as follows:

1. **Browser & DNS Resolution**
   * First, the browser checks its **local cache** and **DNS cache** for the IP address.
   * If not found, it queries the **DNS resolver**.
   * If there is no cache hit, DNS resolves the domain name to an IP address.

2. **Connection Establishment**
   * Once the IP is obtained, the browser establishes a **TCP connection**.
   * This is followed by a **TLS handshake** because the site uses HTTPS.

3. **CDN (Content Delivery Network)**
   * The request is routed to a CDN like **Amazon CloudFront**.
   * CloudFront checks its **edge cache**:
     * **Cache Hit:** If content (HTML, images, CSS, JS) is valid, it is served directly from the edge (reducing latency).
     * **Cache Miss:** If not cached, the request is forwarded to the origin.

4. **Load Balancing**
   * The request reaches a **Load Balancer**, which distributes traffic to healthy backend application servers.

5. **Application Layer & Caching**
   * The backend first checks **application-level caches** (Redis, Memcached, or in-memory):
     * **Cache Hit:** Data is returned immediately.
     * **Cache Miss:** The application fetches data from the **Database**, processes it, and stores the result back in cache.

6. **Response Path**
   * `Application` → `Load Balancer` → `CDN` (may cache response) → `Browser`.

7. **Rendering**
   * The browser checks its cache again, downloads missing resources, and renders the page using HTML, CSS, and JavaScript.

---

## 2. How do you troubleshoot high latency?

**Strategy:** I use a **"Divide and Conquer"** strategy to isolate where the time is being spent: Client, Network, Server, or Database.

### Step 1: Isolate the Component
I look at the **Load Balancer (ALB) logs**:
* **If `TargetResponseTime` is high:** The slowness is in the application/backend.
* **If `TargetResponseTime` is low (but user sees slowness):** The issue is likely the network or the client's ISP.

### Step 2: Database Layer (The Usual Suspect)
If the backend is slow, I check the **Database (RDS/DynamoDB)**:
* Is CPU high?
* Are there slow queries or missing indexes?
* Is there lock contention?

### Step 3: Application Resources
I check **CloudWatch** for resource spikes on EC2 instances:
* **High CPU/Memory?**
* **Swapping?** If the server is swapping memory to disk, latency spikes significantly.

### Step 4: Dependencies
* Is the app waiting on a **3rd party API** (e.g., a payment gateway) that is timing out?
* **Tools:** Tracing tools like **AWS X-Ray** or **Datadog APM** are vital here to visualize the "waterfall" of the request.

# Proxy Types
## What is forward proxy and reverse proxy?

## 1. Forward Proxy
A **Forward Proxy** sits between the client and the internet, controlling and managing **outbound** requests from clients.

* **Role:** Acts on behalf of the client.
* **Function:** Hides client identity, enforces security policies, or bypasses geo-restrictions.

## 2. Reverse Proxy
A **Reverse Proxy** sits between the client and backend servers, handling **inbound** requests and forwarding them to the appropriate servers.

* **Role:** Acts on behalf of the server.
* **Function:** Load balancing, SSL termination, caching, and hiding server topology.


# 3 How do you ensure IPs don't overlap across subnets?

We prevent IP overlap primarily through **proper CIDR planning and IP address management**. Before creating the network, I define the CIDR range for the VPC or VNet and divide it into smaller, **non-overlapping CIDR blocks** for different subnets.

For example, if I have a VPC with **`10.0.0.0/16`**, I might allocate:

* Public Subnet 1 → **`10.0.1.0/24`**
* Public Subnet 2 → **`10.0.2.0/24`**
* Private Subnet 1 → **`10.0.10.0/24`**
* Private Subnet 2 → **`10.0.11.0/24`**

Since these CIDR ranges are distinct, the IP addresses cannot overlap.

I also consider the CIDR ranges of networks that need to communicate with my VPC, such as:

* On-premises networks
* VPN-connected networks
* Other VPCs
* VPC peering or Transit Gateway networks

These networks must also have **non-overlapping CIDRs**; otherwise, routing can become ambiguous and communication can fail.

From an automation perspective, I prefer managing the CIDR allocation through **Terraform** and using functions such as **`cidrsubnet()`** to derive subnet ranges systematically instead of manually assigning them.

We can also add validation or use an IPAM solution such as **AWS VPC IPAM** for centralized IP address management across multiple VPCs and accounts.

## Overall Approach

The overall approach is:

1. **Plan the IP address space**
2. **Allocate unique CIDRs hierarchically**
3. **Validate CIDRs against existing networks**
4. **Manage CIDR allocation through Terraform/IaC**
5. **Use centralized IPAM for larger environments**

This ensures that we don't have **overlapping subnet ranges** as the environment grows.

